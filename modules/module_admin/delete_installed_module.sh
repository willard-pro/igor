

config_dir="config"
modules_dir="modules"

env_file="$config_dir/env.json"

function delete_instaled_module() {
	local module_name="$1"
	local module_label=$(jq -r '.module.label' "$modules_dir/$module_name/config.json")

	rm -rf "$modules_dir/$module_name"
	jq --arg name "$module_name" 'del(.modules[] | select(.name == $name))' "$env_file" > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	log IGOR "Module ${BOLD}$module_label${RESET} has been removed"
}