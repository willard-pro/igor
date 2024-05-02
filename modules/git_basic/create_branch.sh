#!/bin/bash

source ./modules/git_basic/generate_branch_name.sh

function create_branch() {
    local branch_type=$1
    local ticket_number=$2
    local ticket_name=$3

    generate_branch_name $branch_type $ticket_number "$ticket_name"

    log INFO "Checking if workspace is up to date..."
    git pull > /dev/null
    if [ $? -ne 0 ]; then
        log ERROR "Workspace failed to update to latest, please cleanup and retry again..."
        exit 1
    else
        log INFO "Workspace is up to date."
    fi

    # git branch $new_branch_name
    # git checkout $new_branch_name

    # git push --set-upstream origin $new_branch_name
    log INFO "Sucessfully created branch ${BOLD}$generate_branch_name_result${RESET}"
}
