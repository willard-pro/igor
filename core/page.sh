
page_stack=()
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
        local page_label_header=$(printf "%-40s" "$page_label")
        echo -e "${BG_WHITE}${BLACK}${BOLD}$page_label_header${RESET}"

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

    # Check if prompts is not empty
    if [ -n "$prompts" ]; then
        # Iterate over each prompt
        local json_result=$(echo "$prompts" | jq -c '.[]')

        # Declare an empty array
        local -a prompt_array
        while IFS= read -r line; do prompt_array+=("$line"); done <<< "$json_result"

        # Now you can access individual elements of the Bash array
        for prompt in "${prompt_array[@]}"; do
            log DEBUG "Preparing prompt $prompt"

            unset page_command
            unset prompt_command

            local prompt_name=$(echo "$prompt" | jq -r '.name')

            # Check if there is a condition assigned to the prompt, if the condition fails then the prompt is not displayed
            local has_condition=$(echo "$prompt" | jq 'has("condition")')
            if [[ $has_condition == "true" ]]; then
                local prompt_condition=$(echo "$prompt" | jq -r '.condition')
                condition_page_prompt "$prompt_condition"

                if [[ $?  -ne 0 ]]; then
                    continue
                fi
            fi

            local has_options=$(echo "$prompt" | jq 'has("options")')
            if [[ $has_options == "true" ]]; then
                page_prompt_user_options

                if [[ "$prompt_result" == "\${page:back}" ]]; then
                    page_command="$prompt_result"
                    break
                else
                    local has_command=$(echo "$prompt" | jq --arg value "$prompt_result" '.options[] | select(.value == $value) | has("command")')
                    if [[ $has_command == "true" ]]; then
                        local prompt_command=$(echo "$prompt" | jq -r --arg value "$prompt_result" '.options[] | select(.value == $value) | .command')
                    fi

                    local has_required=$(echo "$prompt" | jq --arg value "$prompt_result" '.options[] | select(.value == $value) | has("required")')
                    if [[ $has_required == "true" ]]; then
                        local prompt_required=$(echo "$prompt" | jq -r --arg value "$prompt_result" '.options[] | select(.value == $value) | .required')
                    fi     
                fi
            else 
                local has_format=$(echo "$prompt" | jq 'has("format")')
                if [[ $has_format == "true" ]]; then
                    page_prompt_user_question

                    if [[ "$prompt_result" == "\${page:back}" ]]; then
                        page_command="$prompt_result"
                        break
                    else
                        local has_command=$(echo "$prompt" | jq 'has("command")')
                        if [[ $has_command == "true" ]]; then
                            local prompt_command=$(echo "$prompt" | jq '.command')
                        fi

                        local has_required=$(echo "$prompt" | jq 'has("required")')
                        if [[ $has_required == "true" ]]; then
                            local prompt_required=$(echo "$prompt" | jq -r '.required')
                        fi                        
                    fi
                fi
            fi

            # Check if there is required commands, preferences, etc... assigned to the prompt, if the required checks fail then an error message is displayed
            if [ -v prompt_required ]; then
                check_required "$prompt_required"
            fi

            log DEBUG "Saving prompt result ${BOLD}$prompt_result${RESET} to ${BOLD}page.$page_name.prompt.$prompt_name${RESET}"
            page_prompt_results["page.${page_name}.prompt.${prompt_name}"]="$prompt_result"
            
            if [ -v prompt_command ]; then
                if [[ $prompt_command =~ \$\{page:([^}]*)\} ]]; then
                    local page_command=$prompt_command
                    break
                elif [[ $prompt_command =~ \$\{configure:([^}]*)\} ]]; then
                    local configure_comand="${BASH_REMATCH[1]}"
                    configure_module $configure_comand $module_name $prompt_name "$prompt_result"
                else
                    log DEBUG "Specific command defined in prompt $prompt_name options, overrides the default command"
                    local page_command=$prompt_command
                fi
            fi
        done

        if [ -z "$page_command" ]; then 
            local has_command=$(jq -r --arg page_name "$page_name" '.pages[] | select(.name == $page_name) | has ("command")' < $module_config)

            if [[ $has_command == "true" ]]; then
                local page_command=$(jq -r --arg page_name "$page_name" '.pages[] | select(.name == $page_name) | .command' < $module_config)
            fi
        fi

        log DEBUG "Preparing to run command ${BOLD}$page_command${RESET}"

        if [[ $page_command =~ \$\{page:([^}]*)\} ]]; then
            local command_page_name="${BASH_REMATCH[1]}"

            if [[ "$command_page_name" == "back" ]]; then
                if [ ${#page_stack[@]} -eq 0 ]; then
                    exit 0
                else
                    command_page_name="${page_stack[-1]}"
                    unset page_stack[-1]
                fi
            else 
                page_stack+=("$page_name")
            fi

            page $module_name $command_page_name
        elif [[ $page_command =~ \$\{configure:([^}]*)\} ]]; then
            local configure_comand="${BASH_REMATCH[1]}"
            
            configure_module $configure_comand $module_name $prompt_name
        else
            local command_arguments=$(get_arguments "$page_command")
            local command_only="${page_command%% *}"
            
            run_command "$module_name" "$command_only" ${command_arguments[@]}
        fi
    fi    
}


page_pop() {
    if [ ${#page_stack[@]} -eq 0 ]; then
        return 1
    else
        local popped_page="${page_stack[-1]}"
        unset page_stack[-1]
    fi

    return 0
}
