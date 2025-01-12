
modules_dir="modules"

function reset_module() {
	local module_name="$1"
	local module_path="$modules_dir/$module_name"
	local module_label=$(jq -r '.module.label' "$module_path/config.json")
	
	jq --arg name "$module_name" '.modules |= map(if .name == $name then .configured = "false" else . end)' "$env_file" > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	log IGOR "Module ${BOLD}$module_label${RESET} has been reset"
}