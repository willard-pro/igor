
modules_dir="modules"

get_installed_modules_result=""

function get_installed_modules() {
	declare -A module_options=()

	for module_dir in $modules_dir/*/; do
	    # Check if config.json file exists in the current directory
	    if [ -f "${module_dir}config.json" ]; then
	        # Extract module name using jq
	        module_name=$(jq -r '.module.name' "${module_dir}config.json")
	        module_only_dir="${module_dir#*modules/}"
	        module_only_dir="${module_only_dir::-1}"

	        if [ ! "$module_only_dir" = "module_admin" ]; then
	        	component_options["$module_name"]="$module_only_dir"
		    fi
	    fi
	done

	get_components_result=$(build_options module_options)	
}
