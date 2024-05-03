source ./modules/git_basic/current_branch.sh

function create_pr() {
    local remote_url=$(git config --get remote.origin.url)
    local repo_owner=$(echo "$remote_url" | sed -n 's/.*github.*.com[:/]\(.*\)\/.*/\1/p')
    local repo_name=$(echo "$remote_url" | sed -n 's/.*github.*.com.*\/\(.*\)\.git$/\1/p')

    current_branch

    case "$current_branch_result" in
        feature/*)
            parent_branch="develop"
            ;;
    esac        

    # Remove the word before '/'
    title="${current_branch_result#*/}"
    # Replace '-' with ' '
    title="${title//-/ }"

    gh pr create --base $parent_branch --head $current_branch --repo $repo_owner/$repo_name --title "$title" --body-file .github/pull_request_template.md
    log INFO "Created ${BOLD}PR${RESET}, from local branch ${BOLD}$current_branch${RESET}"
}
