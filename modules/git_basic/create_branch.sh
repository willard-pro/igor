function create_branch() {
    log INFO "Creating new branch ${BOLD}$new_branch_name${RESET}"

    git pull
    if [ $? -ne 0 ]; then
        log ERROR "Workspace failed to update to latest, please cleanup and retry again..."
        exit 1
    fi

    git branch $new_branch_name
    git checkout $new_branch_name

    git push --set-upstream origin $new_branch_name
    log INFO "Sucessfully created branch ${BOLD}$new_branch_name${RESET}"
}
