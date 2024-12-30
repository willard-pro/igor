

function add_workspace() {	
	local workspace_name="$1"
	local workspace_source="$2"

	local new_workspace=$(jq -n --arg name "$workspace_name" --arg source "$workspace_source" '{ "name": $name, "source": $source }')
	jq --argjson new_workspace "$new_workspace" '.workspaces += [$new_workspace]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	log IGOR "Workspace ${BOLD}$workspace_source${RESET} associated with ${BOLD}$workspace_name${RESET} added."
}