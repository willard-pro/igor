#!/bin/bash

source core/colors.sh
source core/log.sh
source core/prompt.sh

branch_name=""

function generate_branch_name() {
    # Convert the input string to lowercase using 'tr' command
    local ticket_name_lowercase=$(echo "$ticket_name" | tr '[:upper:]' '[:lower:]')

    # Replace spaces with dashes using 'sed' command
    local ticket_name_formatted=$(echo "$ticket_name_lowercase" | sed 's/ /-/g')
    
    branch_name="$branch_type/$ticket_number-$ticket_name_formatted"

    log DEBUG "Generated branch name: ${YELLOW}$branch_type/${GREEN}$ticket_number-$ticket_name_formatted${RESET}"
}

function create_branch() {
    local branch_type=$1
    local ticket_number=$2
    local ticket_name=$3

    generate_branch_name

    log INFO "Checking if workspace is up to date..."
    git pull > /dev/null
    if [ $? -ne 0 ]; then
        log ERROR "Workspace failed to update to latest, please cleanup and retry again..."
        exit 1
    else
        log INFO "Workspace is up to date."
    fi

    echo
    prompt_user_yn "Do you wish to continue and create branch $branch_name"

    if [[ $prompt_response == "y" ]]; then 
        # git branch $new_branch_name
        # git checkout $new_branch_name

        # git push --set-upstream origin $new_branch_name
        log INFO "Sucessfully created branch ${BOLD}$branch_name${RESET}"
    fi
}


########
# MAIN ########################################################################
########

# Check if all three arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <branch_type> <ticket_number> <ticket_name>"
    exit 1
fi

create_branch $1 $2 $3

        # {
        #   "prompt": "Do you wish to continue and create branch ${command:generate_branch_name}",
        #   "format": "yn"
        # }
