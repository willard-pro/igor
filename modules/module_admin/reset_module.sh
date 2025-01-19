
modules_dir="modules"

function reset_module() {
	local module_name="$1"
	local module_path="$modules_dir/$module_name"
	local module_label=$(jq -r '.module.label' "$module_path/config.json")
	

    local format=$(jq -r --arg name "$module_name" '.modules[] | select(.name == $name) | .configuration.format' "$env_file")
    if [[ "$format" == "single" ]]; then
        jq --arg name "$module_name" '.modules |= map(if .name == $name then .configuration.configured = "false" else . end)' "$env_file" > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"
    elif [[ "$format" == "multi" ]]; then
    	jq --arg name "$module_name" --arg env "$igor_environment" '.modules |= map(if .name == $name then .configuration[$env].configured = "false" else . end)' "$env_file" > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"
    else
      exit 1
    fi

	log IGOR "Module ${BOLD}$module_label${RESET} has been reset"
}