

get_databases_result=""

function get_databases() {
	declare -A database_options=()

	local config_file=$(get_configuration_property "databases" "config_file")
	local database_names=$(jq -r '.databases[] | .name' "$config_file")

	for database_name in $database_names; do
        local database_label=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .label' "$config_file")

		database_options["$database_label"]="$database_name"
    done

    local database_count=${#database_options[@]}

	get_databases_result=$(build_options database_options)	
}