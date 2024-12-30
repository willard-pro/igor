
function has_workspace() {
	local workspace_search="$1"
	local value="$2"

	local is_workspace_present="false"
	if [[ "$workspace_search" == "name" ]]; then
		is_workspace_present=$(jq --arg name "$value" '[.workspaces[] | select(.name == $name)] | length > 0' $env_file)
	elif [[ "$workspace_search" == "label" ]]; then
		is_workspace_present=$(jq --arg name "$value" '[.workspaces[] | select(.label == $name)] | length > 0' $env_file)
	fi

	if [[ "$is_workspace_present" == "true" ]]; then
		return 0
	else
		return 1
	fi	
}