
function check_prerequisists() {
    local default_json="$config_dir/default.json"

    check_commands
    check_checks
}

function check_commands() {
    log DEBUG "Check if all required commands are available..."

    # local optional=0
    # local optional_failed=0
    
    local mandatory=0
    local mandatory_failed=0


    local commands=$(jq -r '.required.commands | @sh' < $module_config | tr -d "'")

    # Loop over the extracted commands
    for command in $commands; do
        ((mandatory++))

        # Extract the message for the specified command
        local message=$(jq -r --arg command "$command" '.required.commands[] | select(.command == $command) | .message' < $default_json)


        # Call the function
        check_command $command "$message"

        # Check the exit status of the function
        if [ $? -eq 0 ]; then
            ((mandatory_failed++))
        fi
    done

    if [ "$mandatory_failed" -gt 0 ]; then
        log ERROR "Failed ${BOLD}$mandatory_failed${RESET} of the required ${BOLD}$mandatory${RESET} commands, please address them and retry!"
        exit 1
    fi
    # if [ "$optional_failed" -gt 0 ]; then
    #     echo
    #     echo -e "${YELLOW}Failed ${RESET}$optional_failed${YELLOW} of the optional ${RESET}$optional${YELLOW} command, please keep in mind some functionality will not be supported${RESET}."
    #     echo
    # fi
}

function check_checks() {
    log DEBUG "Check if all required checks pass..."

    # local optional=0
    # local optional_failed=0
    
    local mandatory=0
    local mandatory_failed=0


    local checks=$(jq -r '.required.checks[] | .command' < $module_config | tr -d "'")

    # Loop over the extracted checks
    for check in $checks; do
        ((mandatory++))

        # Extract the message for the specified check
        local message=$(jq -r --arg check "$check" '.required.checks[] | select(.command == $check) | .message' < $module_config)

        # Call the function
        check_check $check "$message"

        # Check the exit status of the function
        if [ $? -eq 1 ]; then
            ((mandatory_failed++))
        fi
    done  

    if [ "$mandatory_failed" -gt 0 ]; then
        log ERROR "Failed ${BOLD}$mandatory_failed${RESET} of the required ${BOLD}$mandatory${RESET} checks, please address them and retry!"
        exit 1
    fi
    # if [ "$optional_failed" -gt 0 ]; then
    #     echo
    #     echo -e "${YELLOW}Failed ${RESET}$optional_failed${YELLOW} of the optional ${RESET}$optional${YELLOW} checks, please keep in mind some functionality will not be supported${RESET}."
    #     echo
    # fi      
}

 # Function to check command existence and display error message if not found
function check_command() {
    local command_name=$1
    local error_message=$2
    
    if command -v "$command_name" &> /dev/null
    then
        log INFO "${GREEN}OK: ${BOLD}$command_name${RESET}"
        return 1
    else
        log ERROR "${YELLOW}$error_message${RESET}."
        return 0
    fi
}

function check_check() {
    local command_name=$1
    local ok_message=$2
    local nok_message=$3
    
    run_command $module_name $command_name

    if [ $? -eq 0 ]; then
        log INFO "${GREEN}OK: ${BOLD}$command_name${RESET}"
        return 0
    else
        log ERROR "${YELLOW}$nok_message${RESET}."
        return 1
    fi
}