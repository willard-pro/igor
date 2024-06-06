
function update_microservice() {
	microservice_name="$1"

	local config_file=$(get_configuration_property "microservices" "config_file")

	local microservice_label=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .label' $config_file)
	local docker_path=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .path' $config_file)

	log DEBUG "Updating microservice ${BOLD}$$microservice_label${RESET} found at $microservice_workspace" 
	
	pushd "$docker_path"

	docker-compose stop
	docker-compose pull
	docker-compose up -d	
	
	popd

	log IGOR "Updated microservice ${BOLD}$microservice_label${RESET}"
}