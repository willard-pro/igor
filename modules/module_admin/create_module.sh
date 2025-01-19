
config_dir="config"

function create_module() {
	local module_name=$1
	local module_label=$2
	local module_workspace=$3

	local version_new_module="1.0.0-SNAPSHOT"
	local config_file="$module_workspace/$module_name/config.json"

	log INFO "Creating directory ${BOLD}$module_name${RESET} within ${BOLD}$module_workspace${RESET}"
	mkdir "$module_workspace/$module_name"

	log INFO "Setting version to ${BOLD}${version_new_module}${RESET}"
	echo "$version_new_module" > "$module_workspace/$module_name/version.txt"
	
	log INFO "Constructing basic Igor configuration file ${BOLD}config.json${RESET}"
	cp "$config_dir/module_config_template.json" "$config_file"

    sed -i "s/\$name/$module_name/g" $config_file
    sed -i "s|\$label|$module_label|g" $config_file

	local new_module=$(jq -n --arg name "$module_name" --arg workspace "$module_workspace" --arg version "$version_new_module" --arg configured "true" '{ "name": $name, "workspace": $workspace, "version": $version, "configuration": {  "format": "none", "configured": $configured } }')
	jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	log IGOR "Module ${BOLD}$module_label${RESET} has been created and is ready for development.  Remember to start Igor in ${BOLD}development${RESET} mode. ${YELLOW}igor --develop${RESET}"
}