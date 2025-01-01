
function check_prerequisists() {
    local default_json="$config_dir/default.json"

    check_commands
    run_checks
}

function check_commands() {
    log DEBUG "Check if module ${BOLD}$module_name${RESET} required commands are available..."

    # local optional=0
    # local optional_failed=0
    
    local mandatory=0
    local mandatory_failed=0

    local hasMandatory=$(echo "$prompt" | jq 'has(".required.commands")')
    if [[ $hasMandatory == "true" ]]; then
        local commands=$(jq -r '.required.commands | @sh' < $module_config | tr -d "'")

        # Loop over the extracted commands
        for command in $commands; do
            ((mandatory++))

            # Extract the message for the specified command
            local message=$(jq -r --arg command "$command" '.required.commands[] | select(.command == $command) | .message' < $default_json)

            # Call the function
            run_command_exists $command "$message"

            # Check the exit status of the function
            if [ $? -eq 0 ]; then
                ((mandatory_failed++))
            fi
        done
    fi

    if [ "$mandatory_failed" -gt 0 ]; then
        log ERROR "Failed ${BOLD}$mandatory_failed${RESET} of the required ${BOLD}$mandatory${RESET} commands, please address them and retry!"
        exit 1
    else 
        log DEBUG "Required commands passed on module ${BOLD}$module_name${RESET}"
    fi
    # if [ "$optional_failed" -gt 0 ]; then
    #     echo
    #     echo -e "${YELLOW}Failed ${RESET}$optional_failed${YELLOW} of the optional ${RESET}$optional${YELLOW} command, please keep in mind some functionality will not be supported${RESET}."
    #     echo
    # fi
}

function run_checks() {
    log DEBUG "Check if all required checks pass..."

    # local optional=0
    # local optional_failed=0
    
    local mandatory=0
    local mandatory_failed=0


    local hasMandatory=$(echo "$prompt" | jq 'has(".required.checks")')
    if [[ $hasMandatory == "true" ]]; then
        local checks=$(jq -r '.required.checks[] | .command' < $module_config | tr -d "'")

        # Loop over the extracted checks
        for check in $checks; do
            ((mandatory++))

            # Extract the message for the specified check
            local message=$(jq -r --arg check "$check" '.required.checks[] | select(.command == $check) | .message' < $module_config)

            # Call the function
            run_command_check $check "$message"

            # Check the exit status of the function
            if [ $? -eq 1 ]; then
                ((mandatory_failed++))
            fi
        done  
    fi
    
    if [ "$mandatory_failed" -gt 0 ]; then
        log ERROR "Failed ${BOLD}$mandatory_failed${RESET} of the required ${BOLD}$mandatory${RESET} checks, please address them and retry!"
        exit 1
    else 
        log DEBUG "Required checks passed on module ${BOLD}$module_name${RESET}"
    fi
    
    # if [ "$optional_failed" -gt 0 ]; then
    #     echo
    #     echo -e "${YELLOW}Failed ${RESET}$optional_failed${YELLOW} of the optional ${RESET}$optional${YELLOW} checks, please keep in mind some functionality will not be supported${RESET}."
    #     echo
    # fi      
}


function check_preferences() {
    local module_name="$1"
    local page_name
    local module_path="$modules_dir/$module_name"

    log DEBUG "Check if all required preferences pass..."
    
    local mandatory=0
    local mandatory_failed=0


    local hasMandatory=$(echo "$prompt" | jq 'has(".required.preferences")')
    if [[ $hasMandatory == "true" ]]; then
        local preferences=$(jq -r '.required.preferences[] | .command' < $module_config | tr -d "'")

        # Loop over the extracted preferences
        for preference in $preferences; do
            ((mandatory++))

            # Call the function
            jq --arg preference "$preferences" '.preferences | has($preference)'

            # Check the exit status of the function
            if [ $? -eq 1 ]; then
                ((mandatory_failed++))
            fi
        done  
    fi
    
    if [ "$mandatory_failed" -gt 0 ]; then
        log ERROR "Of the required ${BOLD}$mandatory${RESET} preferences, ${BOLD}$mandatory_failed${RESET} failed, please address them and retry!"
        exit 1
    else 
        log DEBUG "Required preferences passed on module ${BOLD}$module_name${RESET}"
    fi    
}
