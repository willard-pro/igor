
modules_dir="modules"

get_installed_modules_result=""

function get_installed_modules() {
	for module_dir in $modules_dir/*/; do
	    # Check if config.json file exists in the current directory
	    if [ -f "${module_dir}config.json" ]; then
	        # Extract module name using jq
	        module_name=$(jq -r '.module.name' "${module_dir}config.json")
	        module_only_dir="${module_dir#*modules/}"
	        module_only_dir="${module_only_dir::-1}"

	        if [ ! "$module_only_dir" = "module_admin" ]; then
		        get_installed_modules_result="$get_installed_modules_result,\"$module_name\": \"$module_only_dir\""
		    fi
	    fi
	done

	get_installed_modules_result="${get_installed_modules_result:1}"
	get_installed_modules_result="{$get_installed_modules_result}"
}
