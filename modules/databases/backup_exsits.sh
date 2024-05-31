
config_file=""
database_name=""
backup_archive=""

function backup_exists() {
	database_name="$1"
	backup_archive="$2"
	local backup_source="$3"

	config_file=$(get_configuration_property "databases" "config_file")

    case "$backup_source" in
        "local")
			backup_exists_local
			;;
        "dropbox")
			backup_exists_dropbox
			;;
    esac
}

function backup_exists_local() {
	local backup_dir=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .dir' $config_file)	
	local backup_file="$backup_dir/$database_name-$backup_archive.tgz"

	if [ -f "$backup_file" ]; then
		log DEBUG "Unable to find backup ${BOLD}$backup_file${RESET} for database ${BOLD}$database_name${RESET} from local"
		return 0;
	else
		return 1;
	fi
}

function backup_exists_dropbox() {
	local access_token=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .databases[] | select(.source == "dropbox") | .access-token' $config_file)
	local dropbox_dir=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .databases[] | select(.source == "dropbox") | .dir' $config_file)
	local backup_file="$dropbox_dir/$database_name-$backup_archive.tgz"

	# Make the API request to check if the file exists
	get_metadata_response=$(curl -s -X POST https://api.dropboxapi.com/2/files/get_metadata \
	  --header "Authorization: Bearer $access_token" \
	  --header "Content-Type: application/json" \
	  --data '{"path": "'$backup_file'","include_media_info": false}')	

	if [[ $get_metadata_response == *"path/not_found/"* ]]; then
		log DEBUG "Unable to find backup ${BOLD}$backup_file${RESET} for database ${BOLD}$database_name${RESET} from Dropbox"
		return 1
	else
		return 0
	fi
}
