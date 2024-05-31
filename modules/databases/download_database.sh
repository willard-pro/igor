
user_name=""
user_password=""
database_name=""
container_name=""
config_file=""

function download_database() {
	database_name="$1"	
	download_option="$2"

	config_file=$(get_configuration_property "databases" "config_file")


    case "$download_option" in
        "docker")
			download_database_from_dropbox
			;;
    esac


	log ERROR "Unable to find backup ${BOLD}$backup_postfix${RESET} for database ${BOLD}$database_name${RESET} from DropBox"
}

function download_database_from_dropbox() {
	local source="$1"

	local backup_dir=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .dir')	
	local access_token=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .databases[] | select(.source == "dropbox") | .access-token')
	local dropbox_dir=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .databases[] | select(.source == "dropbox") | .dir')

	local backup_source="$dropbox_dir/$source"

	log INFO "Downloading backup ${BOLD}$dropbox_path${RESET} for database ${BOLD}$database_name${RESET} from DropBox"


	if [[ $get_metadata_response == *"path/not_found/"* ]]; then
		log ERROR "Unable to find backup ${BOLD}$backup_postfix${RESET} for database ${BOLD}$database_name${RESET} from DropBox"
		exit 1
	else
	  # Send the API request to download the file
	  curl -X POST https://content.dropboxapi.com/2/files/download \
	      --header "Authorization: Bearer $access_token" \
	      --header "Dropbox-API-Arg: {\"path\": \"$backup_source\"}" \
	      --output "$destination"

	  tar -xzf $backup_source -C $backup_dir
	fi
}