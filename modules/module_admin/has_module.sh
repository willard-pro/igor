
function has_module() {
	local module_search="$1"
	local value="$1"

	log TRACE "$env_file"

	local is_module_present="false"
	if [[ "$module_search" == "name" ]]; then
		is_module_present=$(jq --arg name "$value" '[.modules[] | select(.name == $name)] | length > 0' $env_file)
	elif [[ "$module_search" == "label" ]]; then
		is_module_present=$(jq --arg name "$value" '[.modules[] | select(.label == $name)] | length > 0' $env_file)
	fi

	if [[ $is_module_present == "true" ]]; then
		return 0
	else
		return 1
	fi	
}