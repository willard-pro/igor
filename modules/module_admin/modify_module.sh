
function modify_module() {
	local module_name=$1
	local module_workspace=$2

	local module_path="$module_workspace/$module_name"
	local config_file="$module_path/config.json"

	if [[ ! -f "$config_file" ]]; then
		log ERROR "Configuration ${BOLD}config.json${RESET} missing from ${BOLD}$module_path${RESET}"
	else 
		local module_label=$(jq -r '.module.label' $config_file)
		local module_version=$(cat "$module_path/version.txt")

		local is_configurable=$(jq -r '.module.configurable' "$module_path/config.json")

		if [ "$is_configurable" = "multi" ]; then
			local new_module=$(jq -n --arg name "$module_name" --arg workspace "$module_workspace" --arg version "$module_version" --arg env "$igor_environment" --arg format "$is_configurable" --arg configured "false" '{ "name": $name, "workspace": $workspace, "version": $version, "configuration": {  "format": $format, ($env): { "configured": "false" } } }')
		else
			local module_configured="true"

			if [ "$is_configurable" = "single" ]; then
			    module_configured="false"
			elif [ "$is_configurable" != "none" ]; then
				log ERROR "Configurable mode ${BOLD}$is_configurable${RESET} is not supported, valid options are [none, single, multi]"
				exit 1
			fi

			local new_module=$(jq -n --arg name "$module_name" --arg workspace "$module_workspace" --arg version "$module_version" --arg format "$is_configurable" --arg configured "$module_configured" '{ "name": $name, "workspace": $workspace, "version": $version, "configuration": {  "format": $format, "configured": $configured } }')
		fi

		jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"



		log IGOR "Module ${BOLD}$module_label${RESET} has been marked for ${BOLD}improvement${RESET}"
	fi
}
