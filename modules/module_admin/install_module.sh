
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

	if [ -f "$modules_path/config.json" ]; then
		install_module_from_dir "$modules_path"
	else
		for module_path in "$modules_path"/*; do
		    if [ -d "$module_path" ]; then
		    	install_module_from_dir "$module_path"
		    fi
		done  
	fi
}

function install_module_from_dir() {
 	local module_path="$1"

	if valid_module "$module_path"; then
		local module_name=$(jq -r '.module.name' "$module_path/config.json")
		local module_label=$(jq -r '.module.name' "$module_path/config.json")

		log INFO "Installing module ${BOLD}$module_label${RESET} from ${BOLD}$module_path${RESET}"

		if [ -d "$modules_dir/$module_name" ]; then
			version_new_module=$(cat "$module_path/version.txt")
			version_exising_moule=$(cat "$modules_dir/$module_name/version.txt")

			local version_result=$("$commands_dir/semver.sh" compare "$version_new_module" "$version_exising_moule")
			if [ $version_result -eq 0 ]; then
				log IGOR "Version ${BOLD}$version_exising_moule${RESET} of module ${BOLD}$module_label${RESET} already installed, ${YELLOW}skipped...${RESET}"
				return 
			else
				if [ $version_result -eq -1 ]; then
					log INFO "${YELLOW}Downgrading ${BOLD}$version_exising_moule${RESET}${YELLOW} to ${BOLD}$version_new_module${RESET} of module ${BOLD}$module_label${RESET}"	
				fi

				log INFO "Backing up version of ${BOLD}$version_exising_moule${RESET} of ${BOLD}$module_label${RESET} found to ${BOLD}$modules_dir/${module_name}_$version_exising_moule${RESET}"

				mv "$modules_dir/$module_name" "$modules_dir/${module_name}_${version_exising_moule}"
			fi
		fi

		mkdir "$modules_dir/$module_name"
		cp -R "$module_path"/* "$modules_dir/$module_name"

		local is_components_configured=$(echo "$json_input" | jq -r '.modules[] | select(.name == "components") | .configured')
		if [ "$is_components_configured" == "false" ]; then
			local is_configurable=$(jq -r '.module.configurable' "$module_path/config.json")
			if [ "$is_configurable" = "true" ]; then
			    is_configurable="false"
			elif [ "$is_configurable" = "false" ]; then
			    is_configurable="true"
			fi

			local new_module=$(jq -n --arg name "$module_name" --arg configured "$is_configurable" '{ "name": $name, "configured": $configured }')
			jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"
		fi

		log IGOR "Version ${BOLD}$version_new_module${RESET} of module ${BOLD}$module_label${RESET} installed"
	fi	
}


function install_module_from_zip() {
 	local zip="$1"

	local unzip_dir=$(mktemp -d "$tmp_dir/zip.XXXXXX")
	unzip "$zip" -d "$unzip_dir" > /dev/null

	if [ -f "$unzip_dir/config.json" ]; then
		install_module_from_dir "$unzip_dir"
	else
		install_modules_from_dir "$unzip_dir"
	fi

	rm -rf "$unzip_dir"
}

function valid_module() {
  local module_path="$1"

  local config_file="$module_path/config.json"

  log INFO "Validating configuration $config_file"

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
			if ! jq -e '.pages[] | select(.name == "main")' $config_file >/dev/null; then
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
