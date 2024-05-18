load_module() {
	local module_name=$1
	local module_config="$modules_dir/$module_name/config.json"
	
	log INFO "Loading module ${BOLD}$module_name...${RESET}"
	check_prerequisists
	log DEBUG "Loaded module ${BOLD}$module_name${RESET}"

	page $module_name main
}