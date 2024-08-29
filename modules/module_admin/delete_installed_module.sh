
modules_dir="modules"

function delete_installed_module() {
	local module_name="$1"
	local module_path="$modules_dir/$module_name"
	local module_version=$(cat "$module_path/version.txt")
	local module_label=$(jq -r '.module.label' "$module_path/config.json")
	

	rm "$module_path"
	rm -rf $module_path@${module_version}

	jq --arg name "$module_name" 'del(.modules[] | select(.name == $name))' "$env_file" > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	log IGOR "Module ${BOLD}$module_label${RESET} has been removed"
}