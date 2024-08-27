
function modify_module() {
	local module_name=$1
	local module_workspace=$2

	local config_file="$module_workspace/$module_name/config.json"

	local new_module=$(jq -n --arg name "$module_name" --arg workspace "$module_workspace" --arg configured "true" '{ "name": $name, "workspace": $workspace, "configured": $configured }')
	jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	log IGOR "Module ${BOLD}$module_label${RESET} has been marked for ${BOLD}improvement${RESET}"
}