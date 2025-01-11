
get_workspaces_result=""

function get_workspaces() {
	local workspace_field="$1"

	if [ -z "$workspace_field" ]; then
		workspace_field="source"
	fi

	declare -A workspace_options=()
	local workspaces=$(jq -r '.preferences[].workspaces[].name' $env_file)

	for workspace_name in $workspaces; do
		local workspace_field_value=$(jq -r --arg name "$workspace_name" --arg field "$workspace_field" '.preferences[].workspaces[] | select(.name == $name) | .[$field]' $env_file)

		workspace_options["$workspace_name"]="$workspace_field_value"
	done

	get_workspaces_result=$(build_options workspace_options)
}
