
user_name=""
user_password=""
database_name=""
container_name=""
mysql_command="local"

source ./modules/databases/execute_mysql_command.sh

function backup_database() {
	database_name="$1"

	local config_file=$(get_configuration_property "databases" "config_file")

	# Extract specific values using jq
	# access_token=$(echo "$meta_data" | jq -r '.dropbox."access-token"')

	# Extract specific values using jq
	local database_label=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .label' "$config_file")
	user_name=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .username' "$config_file")
	user_password=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .password' "$config_file")

	local has_docker=$(jq -r --arg name "$database_name" '.databases[] | select(.label == $name) | has("docker")')
	if [[$has_docker == "true "]]
		local docker_container_name=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .docker.container')
		# container_name=$(docker ps | grep -o "$container_pattern")
		mysql_command="docker"
	fi

	local has_backup=$(jq -r --arg name "$database_name" '.databases[] | select(.label == $name) | has("backup")')
	if [[$has_ == "true "]]
		# local has_backip_dropbox=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .backup | (')
		# container_name=$(docker ps | grep -o "$container_pattern")
		backup_destination="dropbox"
	fi

	local backup_dir=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .dir' "$config_file")

    local file_name="$database_name-$timestamp.sql"
    local file_name_latest="$database_name-latest.sql"

    local tar_name="$database_name-$timestamp.tgz"
    local tar_name_latest="$database_name-latest.tgz"
    local tar_path="/database/backup/prod/$tar_name"


    backup_database_local

	if [[ "$backup_destination" == "dropbox" ]]; then
		backup_database_dropbox
	fi
}

function backup_database_local() {
	execute_mysql_command "backup" "$backup_dir/$file_name"

    tar -czvf "$backup_dir/$tar_name" -C "$backup_dir" $file_name
    cp $backup_dir/$file_name $backup_dir//$file_name_latest
    tar -czvf "$backup_dir/$tar_name_latest"  -C "$backup_dir" $file_name_latest
}

function backup_database_dropbox() {
tar_path_latest="/database/backup/prod/$database_name-latest.tgz"

    # Upload the file to Dropbox date specific tarball
    upload_response=$(curl -X POST https://content.dropboxapi.com/2/files/upload \
      --header "Authorization: Bearer $access_token" \
      --header "Dropbox-API-Arg: {\"path\":\"$tar_path\",\"mode\":\"add\",\"autorename\":true,\"mute\":false}" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @"../../backup/$tar_name")

    # Upload the file to Dropbox latest tarball
    upload_response=$(curl -X POST https://content.dropboxapi.com/2/files/upload \
      --header "Authorization: Bearer $access_token" \
      --header "Dropbox-API-Arg: {\"path\":\"$tar_path_latest\",\"mode\":\"overwrite\",\"autorename\":false,\"mute\":false}" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @"../../backup/$tar_name_latest")

}