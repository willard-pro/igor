
get_workspaces_result=""

function get_workspaces() {
	declare -A workspace_options=()
	local workspaces=$(jq -r '.preferences[].workspaces[].name' $env_file)

	for workspace_name in $workspaces; do
		workspace_options["$workspace_name"]="$workspace_name"
	done

	get_workspaces_result=$(build_options workspace_options)
}
