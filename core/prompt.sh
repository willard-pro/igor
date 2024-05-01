
function prompt() {
    local module_name=$1
    local menu_name=$2

    local -a argument_result_array

    local module_config="$modules_dir/$module_name/config.json"

    local arguments=$(jq -r --arg menu_name "$menu_name" '.menus[] | select(.menu == $menu_name) | .arguments' < $module_config)
    # readarray -t options <<< "$menu_options"

    echo
    log INFO "Menu ${BOLD}$menu_name${RESET}"

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
            fi

            local hasPrompt=$(echo "$argument" | jq 'has("prompt")')
            if [[ $hasPrompt == "true" ]]; then
                prompt_user_question
            fi            
        done
    fi    
}

function prompt_user_choice() {
    local prompt_label=$(echo $argument | jq -r '.options')
    local prompt_options=$(echo $argument | jq -r '.parameters[].options[] | .name')
    readarray -t prompt_options_array <<< "$prompt_options"

    PS3="$prompt_label: "
    select prompt_option in "${prompt_options_array[@]}"; do
        if [[ " ${prompt_options_array[@]} " =~ " $prompt_option " ]]; then

            local selected_prompt_option=$(echo $argument | jq -r --arg selected "$prompt_option" '.parameters[].options[] | select (.name == $selected) | .value')
            argument_result_array+=($selected_prompt_option)
            break
        else
            log ERROR "Invalid choice!"
        fi
    done
}

function prompt_user_question() {
    local prompt_label=$(echo $argument | jq -r '.prompt')
    local prompt_format=$(echo $argument | jq -r '.format')
    
    if [[ $prompt_format == "yn" ]]; then
        prompt_label="${prompt_label} [y/N]"
    fi
    
    if [[ $prompt_label =~ \$\{command:([^}]*)\} ]]; then
        local command="${BASH_REMATCH[1]}"

        run_command "$module_name" "$command" "${argument_result_array[@]}"
    fi

    # Prompt user for input until an integer is provided
    while true; do
        read -r -p "$prompt_label: " response

        case $prompt_format in
            "number")
                if is_number "$response"; then
                    argument_result_array+=($response)
                    break
                else
                    log ERROR "Invalid input. Please enter a number."
                fi
                ;;
            "yn")
                if is_yn "$response"; then
                    argument_result_array+=($response)
                    break
                else
                    log ERROR "Invalid input. Please enter either y for yes or n for no."
                fi                
                ;;
            "string")
                argument_result_array+=($response)
                break
                ;;
            *)
                log ERROR "Unsupported prompt format ${BOLD}$prompt_format${RESET}"
                exit 1 
                ;;
        esac
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
