
function load_module() {
	local module_name=$1
	local module_config="$modules_dir/$module_name/config.json"
	
	log INFO "Loading module ${BOLD}$module_name...${RESET}"
	check_prerequisists
	log DEBUG "Loaded module ${BOLD}$module_name${RESET}"

	local is_configured=$(is_module_configured "$module_name")

	if [[ $is_configured == "true" ]]; then
		page $module_name main
	else
		page $module_name "configure"
	fi
}