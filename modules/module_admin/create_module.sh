
config_dir="config"
modules_dir="modules"

env_file="$config_dir/env.json"

function create_module() {
	local module_name=$1
	local module_label=$2
	local module_workspace=$3

	local config_file="$module_workspace/$module_name/config.json"

	mkdir "$modules_dir/$module_name"
	mkdir "$module_workspace/$module_name"
	echo "1.0.0-SNAPSHOT" > "$module_workspace/$module_name/version.txt"
	
	cp "$config_dir/module_config_template.json" "$config_file"

    sed -i "s/\$name/$module_name/g" $config_file
    sed -i "s|\$label|$module_label|g" $config_file

	local new_module=$(jq -n --arg name "$module_name" --arg workspace "$module_workspace" --arg configured "true" '{ "name": $name, "workspace": $workspace, "configured": $configured }')
	jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	log IGOR "Module ${BOLD}$module_label${RESET} has been created and is available at ${BOLD}$module_workspace/$module_name${RESET}"
}