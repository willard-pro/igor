
function has_workspaces() {
	has_workspaces=$(jq 'has("workspaces") and (.workspaces | length > 1)' $env_file)

	if [[ $has_workspaces == "true" ]]; then
		return 0
	else
		return 1
	fi	
}