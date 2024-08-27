
modules_dir="modules"

get_installed_modules_result=""

function get_installed_modules() {
	declare -A module_options=()
	local modules=$(jq -r '.modules[].name' $env_file)

	for module_name in $modules; do
	    if [ -f "$modules_dir/$module_name/config.json" ]; then
	        local module_label=$(jq -r '.module.label' "$modules_dir/$module_name/config.json")

	        if [ ! "$module_name" = "module_admin" ]; then
        		module_options["$module_label"]="$module_name"
		    fi
	    fi
	done

	get_installed_modules_result=$(build_options module_options)
}
