
current_branch_result=""

function current_branch() {
	current_branch_result=$(git rev-parse --abbrev-ref HEAD)
}