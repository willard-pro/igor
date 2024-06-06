
microservice_name=""

function stop_microservice() {
	microservice_name="$1"

	local config_file=$(get_configuration_property "microservices" "config_file")

	local microservice_label=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .label' $config_file)
	local docker_path=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .path' $config_file)

	log DEBUG "Stoping microservice ${BOLD}$$microservice_label${RESET} found at $docker_path"

	pushd "$docker_path"

	docker-compose stop

	popd	
	
	log IGOR "Stoped microservice ${BOLD}$microservice_label${RESET}"
}
