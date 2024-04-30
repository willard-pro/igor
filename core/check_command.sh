# Function to check command existence and display error message if not found
check_command() {
    local command_name=$1
    local error_message=$2
    
    if command -v "$command_name" &> /dev/null
    then
        log INFO "OK: ${BOLD}$command_name${RESET}"
        return 1
    else
        log ERROR "${YELLOW}$error_message${RESET}."
        return 0
    fi
}