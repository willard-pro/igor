
modules_dir="modules"
config_dir="config"

env_file="$config_dir/env.json"

get_installed_modules_result=""

function get_installed_modules() {
	declare -A module_options=()

	for module_dir in $modules_dir/*/; do
	    # Check if config.json file exists in the current directory
	    if [ -f "${module_dir}config.json" ]; then
	        # Extract module name using jq

	        local module_label=$(jq -r '.module.label' "${module_dir}config.json")
	        local module_name=$(jq -r '.module.name' "${module_dir}config.json")

	        if [ ! "$module_name" = "module_admin" ]; then
	        	local is_module_present=$(jq --arg name "$module_name" '[.modules[] | select(.name == $name)] | length > 0' $env_file)
	        	if [ "$is_module_present" = "true" ]; then
	        		module_options["$module_label"]="$module_name"
	        	fi
		    fi
	    fi
	done

	get_installed_modules_result=$(build_options module_options)	
}
