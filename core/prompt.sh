
function prompt() {
    local module_name=$1
    local menu_name=$2

    local -a argument_result_array

    local module_config="$modules_dir/$module_name/config.json"

    local arguments=$(jq -r --arg menu_name "$menu_name" '.menus[] | select(.menu == $menu_name) | .arguments' < $module_config)
    readarray -t options <<< "$menu_options"

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
                echo "dropdown"
            fi

            local hasPrompt=$(echo "$argument" | jq 'has("prompt")')
            if [[ $hasPrompt == "true" ]]; then
                local prompt_label=$(echo $argument | jq -r '.prompt')
                local prompt_format=$(echo $argument | jq -r '.format')

                prompt_user "$module_name" "$prompt_label" "$prompt_format" "${argument_result_array[@]}"
            fi            
        done
    fi    
}

function prompt_user() {
    local module_name=$1
    local prompt="$2"
    local prompt_format="$3"
    shift 3 # Shift the first three arguments (module_name and prompt and prompt format) out of the way
    local command_arguments=("$@") # Store the remaining arguments as an array
    
    if [[ $prompt_format == "yn" ]]; then
        prompt="${prompt} [y/N]"
    fi
    
    if [[ $prompt =~ \$\{command:([^}]*)\} ]]; then
        local command="${BASH_REMATCH[1]}"

        run_command "$module_name" "$command" "${command_arguments[@]}"
    fi

    # Prompt user for input until an integer is provided
    while true; do
        read -r -p "$prompt: " response

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
                    log ERROR "Invalid input. Please enter either y for yes or n for No."
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
