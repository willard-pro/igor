
microservice_name=""

function start_microservice() {
	microservice_name="$1"

	local config_file=$(get_configuration_property "microservices" "config_file")

	local microservice_label=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .label' $config_file)
	local docker_path=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .path' $config_file)

	log INFO "Starting microservice ${BOLD}$$microservice_label${RESET}"
	pushd "$docker_path"
  	docker_start_output=$(docker-compose start 2>&1)

	if [[ $docker_start_output =~ "failed" ]]; then
		docker-compose up -d
	fi
	popd	
	log IGOR "Started microservice ${BOLD}$microservice_label${RESET}"
}


