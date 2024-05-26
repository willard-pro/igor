
config_dir="config"
modules_dir="modules"

env_file="$config_dir/env.json"

function install_module() {
	local install_type="$1"
	local module_path="$2"

	case "$install_type" in
	    "dir")
			install_module_from_dir "$module_path"
	        ;;
	    "zip")
			install_module_from_zip "$module_path"
	        ;;
	esac
}

function install_modules_from_dir() {
	local modules_path="$1"


	if [ ! -f "$modules_path/config.json" ]; then
		install_module_from_dir "$modules_path"
	else
		for module_path in "$modules_path"/*/; do
		    if [ -d "$module_path" ]; then
		    	install_module_from_dir "$modules_path"
		    fi
		done  
	fi
}

function install_module_from_dir() {
 	local module_path="$1"

	if validate_module "$module_path"; then
		local module_name=$(jq -r '.module.name' "$module_path/config.json")
		local module_label=$(jq -r '.module.name' "$module_path/config.json")

		log DEBUG "Installing module ${BOLD}$module_label${RESET} from ${BOLD}$module_path${RESET}"

		if [ -d "$modules_dir/$module_name" ]; then
			log DEBUG "Deleting previous version of ${BOLD}$module_label${RESET} found at ${BOLD}$modules_dir/$module_name${RESET}"

			rm -rf "$modules_dir/$module_name"
			jq --arg name "$module_name" 'del(.modules[] | select(.name == $name))' "$env_file" > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"
		fi

		mkdir "$modules_dir/$module_name"
		cp -R "$module_path"/* "$modules_dir/$module_name"

		local is_configurable=$(jq -r '.module.configurable' "$module_path/config.json")
		if [ "$is_configurable" = "true" ]; then
		    is_configurable="false"
		elif [ "$is_configurable" = "false" ]; then
		    is_configurable="true"
		fi

		local new_module=$(jq -n --arg name "$module_name" --arg configured "$is_configurable" '{ "name": $name, "configured": $configured }')
		jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

		log IGOR "New module ${BOLD}$module_label${RESET} available"
	fi	
}


function install_module_from_zip() {
 	local zip="$1"

	local tmp_dir=$(mktemp -d)
	unzip "$zip" -d "$tmp_dir"

	if [ ! -f "$tmp_dir/config.json" ]; then
		install_module_from_dir "$tmp_dir"
	else
		install_modules_from_dir "$tmp_dir"
	fi

	rm -rf "$tmp_dir"
}

function validate_module() {
  local module_path="$1"

  local config_file="$module_path/config.json"

  log DEBUG "Validating configuration $config_file"

  # Check if the config.json file exists
	if [[ ! -f "$config_file" ]]; then
		log ERROR "Configuration ${BOLD}(config.json)${RESET} missing from $module_path"
		return 1
	else
		# Check if the config.json file is valid JSON
		if ! jq empty "$config_file" 2>/dev/null; then
			log ERROR "Configuration ${BOLD}(config.json)${RESET} from $module_path invalid, unable to parse"
			return 1
		else
			if ! jq -e '.pages[] | select(.name == "main")' $config_file; then
				log ERROR "Configuration ${BOLD}(config.json)${RESET} from $module_path invalid, missing 'main' page"
				return 1
			fi

			local is_configurable=$(jq -r '.module.configurable' $config_file)
			if [ "$is_configurable" == "true" ]; then
				if ! jq -e '.pages[] | select(.name == "configure")' $config_file > /dev/null; then
				log ERROR "Configuration ${BOLD}(config.json)${RESET} from $module_name is specified as configurable, missing 'configure' page"
				return 1
				fi
			fi
		fi
	fi

  return 0
}
