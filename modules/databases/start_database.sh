
database_name=""

function start_database() {
	database_name="$1"

	local config_file=$(get_configuration_property "databases" "config_file")

	local database_label=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .label' $config_file)

	local has_docker=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | has("docker")' $config_file)

	log INFO "Starting database ${BOLD}$$database_label${RESET}"
	if [[ $has_docker == "true" ]]; then
		start_docker_database 
	else
		start_local_database
	fi
	log IGOR "Started database ${BOLD}$database_label${RESET}"
}

function start_local_database() {
	log ERROR "Not yet supported"
	exit 1
}

function start_docker_database() {
	local docker_path=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .docker.path' $config_file)

	pushd "$docker_path"
  	docker_start_output=$(docker-compose start 2>&1)

	if [[ $docker_start_output =~ "failed" ]]; then
		docker-compose up -d
	fi
	popd
}
