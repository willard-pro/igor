
user_name=""
user_password=""
database_name=""
container_name=""
mysql_command="local"

source ./modules/databases/execute_mysql_command.sh

function update_database() {
  database_name="$1"
  local dryRun="$2"
  local sql_directory="$3"

  local config_file=$(get_configuration_property "databases" "config_file")

  # Extract specific values using jq
  user_name=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .username')
  user_password=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .password')
 
  local has_container=$(jq -r --arg name "$database_name" '.databases[] | select(.label == "BOM") | .docker | has("container")')
  if [[$has_container == "true "]]
  	local container_pattern=$(jq -r --arg name "$database_name" '.databases[] | select(.name == $name) | .docker.container')
  	container_name=$(docker ps | grep -o "$container_pattern")
  	mysql_command="docker"
  fi

  log DEBUG "Starting transaction for database ${BOLD}$database${RESET} to execute files in ${BOLD}$sql_directory${RESET}"
  # Start the transaction
  execute_mysql_command "start" 

  local rollback=$dryRun
  for file in "$sql_directory"/*.sql; do
    if [[ -f "$file" ]]; then
      # Extract the filename without the extension
      local filename=$(basename "$file")

      log DEBUG "Executing SQL from file ${BOLD}$filename...${RESET}"
      # Execute the SQL file using the MySQL CLI
      execute_mysql_command "file" "$file"
      local exit_code=$?

      if [[ $exit_code -eq 0 ]]; then
        # If successful, commit the transaction
        log INFO "Executed SQL succesfully from file ${BOLD}$filename${RESET}"
      else
        log ERROR "Error occurred while executing ${BOLD}$filename${RESET}. Stopping execution..."
        rollback=1
		break
      fi
    fi
  done
	

	if [[ $rollback -eq 0 ]]; then
		log DEBUG "Committing transaction for database ${BOLD}$database${RESET} to execute files in ${BOLD}$sql_directory${RESET}"
		# Commit the transaction
		execute_mysql_command "commit" 

		for file in "$sql_directory"/*.sql; do
			if [[ -f "$file" ]]; then
				if [[ ! -d "$sql_directory/executed/$timestamp" ]]; then
					mkdir -p "$sql_directory/executed/$timestamp"
				fi

				log INFO "Moving SQL file ${BOLD}$filename${RESET} to the already executed directory"
				mv "$sql_directory/$filename" "$sql_directory/executed/$timestamp/$filename"
			fi
		done
	else
		if [[ $dryRun -eq 1 ]]; then
			log INFO "All transactions for database ${BOLD}$database${RESET} using sql files in ${BOLD}$sql_directory${RESET}executed succesfully, rolling back transactions..."
		fi

		execute_mysql_command "rollback" 
	fi
}

