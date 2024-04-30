function check_prerequisists() {
    local module_name=$1
    local module_config=$2

    local optional=0
    local optional_failed=0
    
    local mandatory=0
    local mandatory_failed=0


    local commands=$(jq -r '.required.commands | @sh' < $module_config | tr -d "'")

    # Loop over the extracted commands
    for command in $commands; do
        ((mandatory++))

        # Extract the message for the specified command
        local message=$(echo "$json_data" | jq -r --arg command "$command" '.required.commands[] | select(.command == $command) | .message')

        # Call the function
        check_command $command $message

        # Check the exit status of the function
        if [ $? -eq 0 ]; then
            ((mandatory_failed++))
        fi
    done

    if [ "$mandatory_failed" -gt 0 ]; then
        echo
        echo -e "${RED}Failed ${YELLOW}$mandatory_failed${RED} of the mandatory ${YELLOW}$mandatory${RED} prerequisists, please address them and retry${RESET}."
        exit 1
    fi
    if [ "$optional_failed" -gt 0 ]; then
        echo
        echo -e "${YELLOW}Failed ${RESET}$optional_failed${YELLOW} of the optional ${RESET}$optional${YELLOW} prerequisists, please keep in mind some functionality will not be supported${RESET}."
        echo
    fi
}
