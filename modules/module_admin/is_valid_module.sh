
function is_valid_module() {
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
