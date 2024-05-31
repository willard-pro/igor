
database_name=""

function stop_database() {
	database_name="$1"

	local config_file=$(get_configuration_property "databases" "config_file")

	local database_label=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .label' $config_file)

	local has_docker=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | has("docker")' $config_file)

	log INFO "Stoping database ${BOLD}$$database_label${RESET}"
	if [[ $has_docker == "true" ]]; then
		stop_docker_database 
	else
		stop_local_database
	fi
	log IGOR "Stoped database ${BOLD}$database_label${RESET}"
}

function stop_local_database() {
	log ERROR "Not yet supported"
	exit 1
}

function stop_docker_database() {
	local docker_path=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .docker.path' $config_file)

	pushd "$docker_path"
	docker-compose stop
	popd
}