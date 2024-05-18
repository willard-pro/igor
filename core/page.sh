
prompt_result=""
declare -A page_prompt_results=()

function banner() {
    local filename=$1

    # Check if the file exists
    if [ ! -f "$filename" ]; then
        log ERROR "Banner not found, ${BOLD}$filename${RESET}"
        exit 1
    fi

    echo
    # Read the file line by line and echo each line with -e option
    while IFS= read -r line; do
        echo -e "$line"
    done < "$filename"
    echo
}

function page() {
    local module_name=$1
    local page_name=$2

    log DEBUG "Building page $page_name found within module $module_name"

    local module_config="$modules_dir/$module_name/config.json"

    local page_label=$(jq -r --arg page_name "$page_name" '.pages[] | select(.name == $page_name) | .label' < $module_config)
    if [[ $page_label != "null" ]]; then
        if [[ $page_label =~ \$\{command:([^}]*)\} ]]; then
            log DEBUG "Altering label $page_label"
            local command="${BASH_REMATCH[1]}"

            run_command "$module_name" "$command" "${argument_result_array[@]}"
            page_label="${page_label/\$\{command:$command\}/$command_result}"
        fi
        
        echo -e "${BG_WHITE}${BLACK}${BOLD}$page_label${RESET}"
    else
        log DEBUG "page ${BOLD}$page_name${RESET}"
    fi

    prompts $module_name $page_name
}

function prompts() {
    local module_name=$1
    local page_name=$2

    log DEBUG "Building prompts for page $page_name found within module $module_name"

    local module_config="$modules_dir/$module_name/config.json"

    local prompts=$(jq -r --arg page_name "$page_name" '.pages[] | select(.name == $page_name) | .prompts' < $module_config)
    local command=$(jq -r --arg page_name "$page_name" '.pages[] | select(.name == $page_name) | .command' < $module_config)

    # Check if prompts is not empty
    if [ -n "$prompts" ]; then
        # Iterate over each prompt
        local json_result=$(echo "$prompts" | jq -c '.[]')

        # Declare an empty array
        local -a prompt_array

        # Read the JSON result into the Bash array
        readarray -t prompt_array <<< "$json_result"

        # Now you can access individual elements of the Bash array
        for prompt in "${prompt_array[@]}"; do
            local prompt_name=$(echo "$prompt" | jq -r '.name')

            local hasOptions=$(echo "$prompt" | jq 'has("options")')
            if [[ $hasOptions == "true" ]]; then
                prompt_user_options
                page_prompt_results["page.$page_name.prompt.$prompt_name"]="$prompt_result"
            fi

            local hasFormat=$(echo "$format" | jq 'has("format")')
            if [[ $hasFormat == "true" ]]; then
                prompt_user_question
                page_prompt_results["page.$page_name.prompt.$prompt_name"]="$prompt_result"
            fi            
        done
        log DEBUG "Preparing to run command $command"

        if [[ $command =~ \$\{page:([^}]*)\} ]]; then
            local command_page_name="${BASH_REMATCH[1]}"
            page $module_name $command_page_name
        else
            local prompt_result_array=$(get_values $command)
            run_command "$module_name" "$command" "${prompt_result_array[@]}"
        fi
    fi    
}

function prompt_user_options() {
    local prompt_label=$(echo $prompt | jq -r '.label')
    local prompt_options_array=()

    prompt_label=$(replace_values "$prompt_label")

    # Test if "prompts" node is an array or a plain node
    local is_array=$(echo "$prompt" | jq '.options | type == "array"')
    if [ "$is_array" == "true" ]; then
        local prompt_options=$(echo "$prompt" | jq -r '.options[] | .name')
    else
        local prompt_options=$(echo "$prompt" | jq '.options')

        if [[ $prompt_options =~ \$\{command:([^}]*)\} ]]; then
            local command="${BASH_REMATCH[1]}"
            local prompt_result_array=$(get_values $command)
            run_command "$module_name" "$command" "${prompt_result_array[@]}"

            local generated_options=$(echo "$command_result" | jq '.options')
            prompt=$(echo "$prompt" | jq --argjson generated_options "$generated_options" '.options = $generated_options')
            prompt_options=$(echo "$prompt" | jq -r '.options[] | .name')
        fi        
    fi

    PS3="$prompt_label: "
    readarray -t prompt_options_array <<< "$prompt_options"

    select prompt_option in "${prompt_options_array[@]}"; do
        if [[ " ${prompt_options_array[@]} " =~ " $prompt_option " ]]; then

            local selected_prompt_option=$(echo $prompt | jq -r --arg selected "$prompt_option" '.options[] | select (.name == $selected) | .value')
            prompt_result=$selected_prompt_option
            break
        else
            log ERROR "Invalid choice!"
        fi
    done
}

function prompt_user_question() {
    local prompt_label=$(echo $argument | jq -r '.prompt')
    local prompt_format=$(echo $argument | jq -r '.format')
        
    if [[ $prompt_label =~ \$\{command:([^}]*)\} ]]; then
        local command="${BASH_REMATCH[1]}"

        run_command "$module_name" "$command" "${argument_result_array[@]}"
        prompt_label="${prompt_label/\$\{command:$command\}/$command_result}"        
    fi

    echo "${argument_result_array[1]}"

    if [[ $prompt_label =~ \$\{arguments\[([0-9]+)\]\} ]]; then
        local argument="${BASH_REMATCH[1]}"
        prompt_label="${prompt_label//\$\{arguments\[$argument\]\}/$argument_result_array}"
    fi

    case $prompt_format in
        "number")
            prompt_user_number "$prompt_label"
            ;;
        "yn")
            prompt_user_yn "$prompt_label"
            ;;
        "continue")
            prompt_user_continue "$prompt_label"
            ;;
        "string")
            prompt_user_text "$prompt_label"
            ;;
        *)
            log ERROR "Unsupported prompt format ${BOLD}$prompt_format${RESET}"
            exit 1 
            ;;
    esac
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function prompt_user_yn() {
    local prompt_label=$1

    prompt_label="${prompt_label} [y/N]"

    while true; do
        read -r -p "$prompt_label: " response

        if is_yn "$response"; then
            prompt_result=$response
            break
        else
            log ERROR "Invalid input. Please enter either y for yes or n for no."
        fi                
    done
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function prompt_user_continue() {
    local prompt_label=$1
    
    prompt_user_yn "$prompt_label"

    if [[ "$prompt_result" =~ ^[nN]$ ]]; then
        log_phrase
        exit 0
    fi    
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function prompt_user_text() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response
        prompt_result=$response
        break
    done
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function prompt_user_number() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response

        if is_number "$response"; then
            prompt_result=$response
            break
        else
            log ERROR "Invalid input. Please enter a number."
        fi                
    done
}


# Function to check if input is an integer
is_number() {
    local value=$1

    local regex='^[0-9]+$'
    if [[ $value =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if input is either yes or no
is_yn() {
    local value=$1

    local regex='^[yYnN]$'
    if [[ $value =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# function single_select() {

#     PS3="Select action to take: "
#     select option in "${options[@]}"; do
#         if [[ " ${options[@]} " =~ " $option " ]]; then

#             local selected_command=$(jq -r --arg selected "$option" --arg menu_name "$menu_name"  '.menus[] | select (.menu == $menu_name) | .options[] | select (.name == $selected).command' < $module_config)

#             if [[ $string == menu:* ]]; then
#                 local sub_menu_name="${string#menu:}"
#                 menu $module_name $sub_menu_name
#             fi
#             break
#         else
#             log ERROR "Invalid choice!"
#         fi
#     done

# }
