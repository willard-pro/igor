load_module() {
	local module_name=$1
	local module_config="$modules_dir/$module_name/config.json"
	
	log INFO "Loading module ${BOLD}$module_name...${RESET}"

	check_prerequisists $module_name $module_config
	menu $module_name main
}