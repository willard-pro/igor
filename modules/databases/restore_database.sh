
user_name=""
user_password=""
database_name=""
container_name=""

source ./modules/databases/execute_mysql_command.sh

function restore_database() {
	database_name="$1"
	local backup_source="$2"
	local use_latest_backup="$3"
	local backup_date="$4"

	local config_file=$(get_configuration_property "databases" "config_file")

	# Extract specific values using jq
	# access_token=$(echo "$meta_data" | jq -r '.dropbox."access-token"')

	# Extract specific values using jq
	local database_label=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .label')
	user_name=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .username')
	user_password=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .password')

	local has_container=$(jq -r --arg name "$database_name" '.databases[] | select(.label == "BOM") | .docker | has("container")')
	if [[$has_container == "true "]]
		local container_pattern=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .docker.container')
		container_name=$(docker ps | grep -o "$container_pattern")
		mysql_command="docker"
	fi

	local backup_postfix='latest'
	if [[ $"use_latest_backup" == "n" ]]; then
		backup_postfix="$backup_date"
	fi

	local backup_file_latest="$backup_dir/$database_name-$backup_postfix.sql"
	local backup_tar_path_latest="/database/backup/prod/$database_name-$backup_postfix.tgz"
	local backup_tar_file="$backup_dir/$database_name-$backup_postfix.tar.gz"

	if [[ "$backup_source" == "local" ]]; then
		local backup_dir=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .dir')
	elif [[ "$backup_source" == "dropbox" ]]; then

	fi


	restore_from_source 

	container_name=$(docker ps | grep -o "$docker_name")

	execute_mysql_command "custom:drop database $database_name"
	execute_mysql_command "custom:create database $database_name"

	execute_mysql_command "file" $backup_file_latest
}


	# if [[ "$microservice" == "gateway" ]]; then
	# 	echo "Resetting all users passwords to 'admin'"

	# 	password_hash='$2a$10$gSAhZrxMllrbgj/kkK9UceBPpChGWJA7SYIb1Mqo.n5aNLq1/oRrC'
	# 	echo "update jhi_user set password_hash = \"$password_hash\";" | docker exec -i "$container_name" /usr/bin/mysql -u "$user_name" --password="$user_password" "$database_name"
	# fi	


	# download_file="true"
	# if [ -e "$backup_tar_file" ]; then
	# 	current_time=$(date +%s)

	# 	file_modification_time=$(stat -c "%Y" "$backup_tar_file")
	# 	time_diff=$((current_time - file_modification_time))
	# 	threshold=$((12 * 3600))

	# 	if [ "$threshold" -ge "$time_diff" ]; then
	# 	  log INFO "Already have a fresh copy of $backup_tar_file, skipping download..."
	# 	  download_file="false"
	# 	fi
	# fi
	# # Older than 12 hours


function restore_from_source() {

}

function download_from_dropbox() {
	log INFO "Downloading backup ${BOLD}$backup_postfix${RESET} for database ${BOLD}$database_name${RESET} from DropBox"

	# Make the API request to check if the file exists
	get_metadata_response=$(curl -s -X POST https://api.dropboxapi.com/2/files/get_metadata \
	  --header "Authorization: Bearer $access_token" \
	  --header "Content-Type: application/json" \
	  --data '{"path": "'$backup_tar_path_latest'","include_media_info": false}')

	if [[ $get_metadata_response == *"path/not_found/"* ]]; then
		log ERROR "Unable to find backup ${BOLD}$backup_postfix${RESET} for database ${BOLD}$database_name${RESET} from DropBox"
		exit 1
	else
	  # Send the API request to download the file
	  curl -X POST https://content.dropboxapi.com/2/files/download \
	      --header "Authorization: Bearer $access_token" \
	      --header "Dropbox-API-Arg: {\"path\": \"$backup_tar_path_latest\"}" \
	      --output "$backup_tar_file"

	  tar -xzf $backup_tar_file -C ../../backup/
	fi
}