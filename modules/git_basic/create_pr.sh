# #############################################################################
# Creates a pull request using GitHub CLI.  If the branch to PR is a release
# or hotfix branch then it creates a copy of that branch and prefixes it with
# auto and creates a PR to develop from the auto branch.
# #############################################################################

function create_pr() {
    # Remove the word before '/'
    title="${current_branch#*/}"
    # Replace '-' with ' '
    title="${title//-/ }"

    gh pr create --base $parent_branch --head $current_branch --repo $repo_owner/$repo_name --title "$title" --body-file .github/pull_request_template.md
    
    while true; do
        read -p "Do you wish to delete $current_branch? [y/N]" response
        case $response in
            [yY])
                git checkout develop
                git branch -d $current_branch 
                log INFO "Created PR, switched back to develop branch and deleted local branch ${BOLD}$current_branch${RESET}"
                break
                ;;
            [nN]|"")
                log INFO "Created PR, from local branch ${BOLD}$current_branch${RESET}"
                exit 1
                ;;
            *)
                log ERROR "Invalid input!"
                ;;
        esac
    done

    echo -e "${YELLOW}PR has been created please update details${RESET}!"
}
