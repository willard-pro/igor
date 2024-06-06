
function package_microservice() {
  	local microservice_name="$1"

	local config_file=$(get_configuration_property "microservices" "config_file")
  	local microservice_label=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .label' $config_file)
  	local microservice_workspace=$(jq -r --arg name "$microservice_name" '.microservices[] | select(.name == $name) | .workspace' $config_file)

  	log DEBUG "Packging microservice $microservice_name found at $microservice_workspace" 
  	
  	pushd "$microservice_workspace"

  	./mvnw -Pprod -DskipTests clean package verify jib:dockerBuild --offline
  	
  	if [[ $? -eq  0 ]]; then
  		docker push "creditnetworkbiz/$microservice_name:latest"
  		log IGOR "Packaged microservice $microservice_name and pushed image to Docker under the tag ${BOLD}latest${RESET}"
  	else
  		log ERROR "Something went wrong during the local build and package"
  	fi

  	popd
}
