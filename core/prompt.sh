
prompt_result=""

function prompt() {
    local module_name=$1
    local menu_name=$2

    local -a argument_result_array

    local module_config="$modules_dir/$module_name/config.json"

    local arguments=$(jq -r --arg menu_name "$menu_name" '.menus[] | select(.menu == $menu_name) | .arguments' < $module_config)
    local command=$(jq -r --arg menu_name "$menu_name" '.menus[] | select(.menu == $menu_name) | .command' < $module_config)

    log DEBUG "Menu ${BOLD}$menu_name${RESET}"

    # Check if arguments is not empty
    if [ -n "$arguments" ]; then
        # Iterate over each argument
        local json_result=$(echo "$arguments" | jq -c '.[]')

        # Declare an empty array
        local -a argument_array

        # Read the JSON result into the Bash array
        readarray -t argument_array <<< "$json_result"

        # Now you can access individual elements of the Bash array
        for argument in "${argument_array[@]}"; do
            local hasOptions=$(echo "$argument" | jq 'has("options")')
            if [[ $hasOptions == "true" ]]; then
                prompt_user_choice
                argument_result_array+=("$prompt_result")
            fi

            local hasPrompt=$(echo "$argument" | jq 'has("prompt")')
            if [[ $hasPrompt == "true" ]]; then
                prompt_user_question
                argument_result_array+=("$prompt_result")
            fi            
        done

        run_command "$module_name" "$command" "${argument_result_array[@]}"
    fi    
}

function prompt_user_choice() {
    local prompt_label=$(echo $argument | jq -r '.options')
    local prompt_options_array=()

    # Test if "arguments" node is an array or a plain node
    local is_array=$(echo "$argument" | jq '.parameters | type == "array"')
    if [ "$is_array" == "true" ]; then
        local prompt_options=$(echo "$argument" | jq -r '.parameters[].options[] | .name')
    else
        local prompt_parameters=$(echo "$argument" | jq '.parameters')

        if [[ $prompt_parameters =~ \$\{command:([^}]*)\} ]]; then
            local command="${BASH_REMATCH[1]}"

            run_command "$module_name" "$command" "${argument_result_array[@]}"

            local prompt_options=$(echo "$command_result" | jq -c 'to_entries | map({name: .key, value: .value}) | [{options: .}]')
            argument=$(echo "$argument" | jq --argjson var "$prompt_options" '.parameters = $var')
            prompt_options=$(echo "$argument" | jq -r '.parameters[].options[] | .name')
        fi        
    fi

    PS3="$prompt_label: "
    readarray -t prompt_options_array <<< "$prompt_options"

    select prompt_option in "${prompt_options_array[@]}"; do
        if [[ " ${prompt_options_array[@]} " =~ " $prompt_option " ]]; then
            local selected_prompt_option=$(echo $argument | jq -r --arg selected "$prompt_option" '.parameters[].options[] | select (.name == $selected) | .value')
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
