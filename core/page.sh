
prompt_result=""
declare -A page_prompt_results=()

function page() {
    local module_name=$1
    local page_name=$2

    log DEBUG "Building page ${BOLD}$page_name${RESET} found within module ${BOLD}$module_name${RESET}"

    local module_config="$modules_dir/$module_name/config.json"

    local has_page=$(jq -r --arg page_name "$page_name" '.pages | map(.name == $page_name) | any' < $module_config)
    if [[ $has_page == "false" ]]; then
        log ERROR "Page ${BOLD}$page_name${RESET} NOT FOUND within module ${BOLD}$module_name${RESET}"
        exit 1
    fi

    local page_label=$(jq -r --arg page_name "$page_name" '.pages[] | select(.name == $page_name) | .label' < $module_config)
    if [[ $page_label != "null" ]]; then
        if [[ $page_label =~ \$\{command:([^}]*)\} ]]; then
            log DEBUG "Altering label $page_label"
            local command="${BASH_REMATCH[1]}"

            run_command "$module_name" "$command" "${argument_result_array[@]}"
            page_label="${page_label/\$\{command:$command\}/$command_result}"
        fi
        
        echo
        echo -e "${BG_WHITE}${BLACK}${BOLD}$page_label${RESET}"

    else
        log DEBUG "page ${BOLD}$page_name${RESET}"
    fi

    page_prompts $module_name $page_name
}

function page_prompts() {
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
            log DEBUG "Preparing prompt $prompt"

            local prompt_name=$(echo "$prompt" | jq -r '.name')

            local has_options=$(echo "$prompt" | jq 'has("options")')
            if [[ $has_options == "true" ]]; then
                page_prompt_user_options

                local has_command=$(echo "$prompt" | jq --arg value "$prompt_result" '.options[] | select(.value == $value) | has("command")')
                if [[ $has_command == "true" ]]; then
                    log DEBUG "Specific command defined in prompt $prompt_name, overrides the default command"
                    command=$(echo "$prompt" | jq -r --arg name "$prompt_option" '.options[] | select(.name == $name) | .command')
                    break
                fi
            fi 

            local has_format=$(echo "$prompt" | jq 'has("format")')
            if [[ $has_format == "true" ]]; then
                page_prompt_user_question
            fi

            log DEBUG "Saving prompt result ${BOLD}$prompt_result${RESET} to ${BOLD}page.$page_name.prompt.$prompt_name${RESET}"
            page_prompt_results["page.$page_name.prompt.$prompt_name"]="$prompt_result"
        done
        log DEBUG "Preparing to run command $command"


        if [[ $command =~ \$\{page:([^}]*)\} ]]; then
            local command_page_name="${BASH_REMATCH[1]}"
            page $module_name $command_page_name
        else
            local command_arguments=$(get_values "$command")
            local command_only="${command%% *}"
            
            run_command "$module_name" "$command_only" ${command_arguments[@]}
        fi
    fi    
}

function page_prompt_user_options() {
    local prompt_label=$(echo $prompt | jq -r '.label')
    local prompt_options_array=()

    prompt_label=$(replace_values "$prompt_label")

    local is_array=$(echo "$prompt" | jq '.options | type == "array"')
    if [ "$is_array" == "true" ]; then
        local prompt_options_all=$(echo "$prompt" | jq -r '.options[] | .name')
    else
        local prompt_options_all=$(echo "$prompt" | jq '.options')

        if [[ $prompt_options_all =~ \$\{command:([^}]*)\} ]]; then
            local command="${BASH_REMATCH[1]}"
            
            local command_arguments=$(get_values "$command")
            local command_only="${command%% *}"

            run_command "$module_name" "$command_only" ${command_arguments[@]}

            local generated_options=$(echo "$command_result" | jq '.options')
            prompt=$(echo "$prompt" | jq --argjson generated_options "$generated_options" '.options = $generated_options')
            prompt_options_all=$(echo "$prompt" | jq -r '.options[] | .name')
        fi        
    fi    

    readarray -t prompt_options <<< "$prompt_options_all"
    for prompt_option in "${prompt_options[@]}"; do
        local has_condition=$(echo "$prompt" | jq --arg name "$prompt_option" '.options[] | select(.name == $name) | has("condition")')

        if [[ $has_condition == "true" ]]; then
            local prompt_option_condition=$(echo "$prompt" | jq -r --arg name "$prompt_option" '.options[] | select(.name == $name) | .condition')

            log DEBUG "Evaluating condition $prompt_option_condition on prompt $prompt_option"

            if [[ $prompt_option_condition =~ \$\{command:([^}]*)\} ]]; then
                local command="${BASH_REMATCH[1]}"
                
                local command_arguments=$(get_values "$command")
                local command_only="${command%% *}"

                run_command "$module_name" "$command_only" ${command_arguments[@]}
                local command_condition_exit_value=$?

                local not_command=0
                if [[ $prompt_option_condition == \!* ]]; then
                    not_command=1
                fi

                local command_condition_result=$(( not_command ^ command_condition_exit_value))

                if [  $command_condition_result -eq 0 ]; then
                    prompt_options_array+=("$prompt_option")
                else
                    log DEBUG "Skipping option ${BOLD}$option${RESET}, condition ${BOLD}$prompt_option_condition${RESET} not met"
                fi

            fi        
        else
            prompt_options_array+=("$prompt_option")
        fi
    done
    # prompt_options_array+=("Exit")


    PS3="$prompt_label: "
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

function page_prompt_user_question() {
    local prompt_label=$(echo $prompt | jq -r '.label')
    local prompt_format=$(echo $prompt | jq -r '.format')

    prompt_label=$(replace_values "$prompt_label")

    case $prompt_format in
        "number")
            page_prompt_user_number "$prompt_label"
            ;;
        "yn")
            page_prompt_user_yn "$prompt_label"
            ;;
        "continue")
            page_prompt_user_continue "$prompt_label"
            ;;
        "string")
            page_prompt_user_text "$prompt_label"
            ;;
        "dir")
            page_prompt_user_directory "$prompt_label"
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
function page_prompt_user_yn() {
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
function page_prompt_user_continue() {
    local prompt_label=$1
    
    page_prompt_user_yn "$prompt_label"

    if [[ "$prompt_result" =~ ^[nN]$ ]]; then
        log_phrase
        exit 0
    fi    
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function page_prompt_user_text() {
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
function page_prompt_user_number() {
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
