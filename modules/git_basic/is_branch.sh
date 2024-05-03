
function is_branch() {
	local branch_type="$1"

	local current_branch=$(git rev-parse --abbrev-ref HEAD)

	if [[ "$current_branch" == "$branch_type"* ]]; then
        return 0
    else
        return 1
    fi	
}