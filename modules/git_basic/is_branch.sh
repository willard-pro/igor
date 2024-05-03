
function is_branch() {
    local branch_types=("$@")  # Accept an array of branch types as arguments

    local current_branch=$(git rev-parse --abbrev-ref HEAD)

    for branch_type in "${branch_types[@]}"; do
        if [[ "$current_branch" == "$branch_type"* ]]; then
            return 0
        fi
    done
    
    return 1
}
