
function remove_workspace() {
	local workspace_name="$1"
	
	jq --arg name "$workspace_name" 'del(.workspaces[] | select(.name == $name))' "$env_file" > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	log IGOR "Workspace ${BOLD}$workspace_name${RESET} has been removed"
}