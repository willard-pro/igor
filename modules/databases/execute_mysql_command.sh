
function execute_mysql_command() {
	local mysql_action="$1"
	local sql_file="$2"

	case "$mysql_command" in
	    "local") 
			execute_mysql_local "$mysql_action" "$sql_file"
	        ;;
	    "docker") 
			execute_mysql_docker "$mysql_action" "$sql_file"	        
	        ;;
	esac

	return $?
}

function execute_mysql_docker() {
	local mysql_action="$1"
	local sql_file="$2"
	
	case "$mysql_action" in
		custom:*)
			docker exec -i "$container_name" /usr/bin/mysql -u "$user_name" --password="$user_password" "$database_name" -e "${mysql_action#custom:}"
			;;
		"create")
			docker exec -i "$container_name" /usr/bin/mysql -u "$user_name" --password="$user_password" "$database_name" -e "CREATE DATABASE"
			;;
	    "start") 
			docker exec -i "$container_name" /usr/bin/mysql -u "$user_name" --password="$user_password" "$database_name" -e "START TRANSACTION;"
	        ;;
	    "commit")
			docker exec -i "$container_name" /usr/bin/mysql -u "$user_name" --password="$user_password" "$database_name" -e "COMMIT;"
			;;
	    "rollback")
			docker exec -i "$container_name" /usr/bin/mysql -u "$user_name" --password="$user_password" "$database_name" -e "ROLLBACK;"
			;;
		"file")
			cat $sql_file | docker exec -i "$container_name" /usr/bin/mysql -u "$user_name" --password="$user_password" "$database_name"
			;;
		"backup")
			docker exec -i "$container_name" /usr/bin/mysqldump -u "$user_name" --password="$user_password" "$database_name" > "$sql_file"
			;;
	esac

	return $?
}

function execute_mysql_local() {
	local mysql_action="$1"
	local sql_file="$2"

    if ! command -v "mysql" &> /dev/null; then
        log ERROR "Unable to allocate the command ${BOLD}mysql${RESET} on the command line path"
        exit 1
    fi

	case "$mysql_action" in
		custom:*)
			mysql -u "$user_name" --password="$user_password" "$database_name" -e "${mysql_action#custom:}"
			;;
	    "start") 
			mysql -u "$user_name" --password="$user_password" "$database_name" -e "START TRANSACTION;"					        
	        ;;
	    "commit")
			mysql -u "$user_name" --password="$user_password" "$database_name" -e "COMMIT;"
			;;
	    "rollback")
			mysql -u "$user_name" --password="$user_password" "$database_name" -e "ROLLBACK;"
			;;
		"file")
			cat $sql_file | mysql -u "$user_name" --password="$user_password" "$database_name"
			;;			
		"backup")
			mysqldump -u "$user_name" --password="$user_password" "$database_name" > "$sql_file"
			;;
	esac

	return $?
}