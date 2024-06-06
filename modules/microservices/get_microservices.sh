

get_microservices_result=""

function get_microservices() {
	declare -A microservice_options=()

	local config_file=$(get_configuration_property "microservices" "config_file")
	local microservice_names=$(jq -r '.microservices[] | .name' "$config_file")

	for microservice_name in $microservice_names; do
        local microservice_label=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .label' "$config_file")

		microservice_options["$microservice_label"]="$microservice_name"
    done

    local microservice_count=${#microservice_options[@]}

	get_microservices_result=$(build_options microservice_options)	
}