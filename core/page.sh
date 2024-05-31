
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

            unset page_command
            unset prompt_command

            local prompt_name=$(echo "$prompt" | jq -r '.name')

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

                local has_command=$(echo "$prompt" | jq --arg value "$prompt_result" '.options[] | select(.value == $value) | has("command")')
                if [[ $has_command == "true" ]]; then
                    local prompt_command=$(echo "$prompt" | jq -r --arg name "$prompt_option" '.options[] | select(.name == $name) | .command')
                fi
            fi 


            local has_format=$(echo "$prompt" | jq 'has("format")')
            if [[ $has_format == "true" ]]; then
                page_prompt_user_question

                local has_command=$(echo "$prompt" | jq 'has("command")')
                if [[ $has_command == "true" ]]; then
                    local prompt_command=$(echo "$prompt" | jq '.command')
                fi
            fi

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

            log DEBUG "Saving prompt result ${BOLD}$prompt_result${RESET} to ${BOLD}page.$page_name.prompt.$prompt_name${RESET}"
            page_prompt_results["page.$page_name.prompt.$prompt_name"]="$prompt_result"
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
