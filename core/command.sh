
command_result=""
declare -A session_commands=()

declare -A command_results

function run_command() {
	local module_name=$1
	local command=$2
	shift 2 # Shift the first two arguments (module_name and command) out of the way
    local command_arguments=("$@") # Store the remaining arguments as an array

    local arguments
	# Loop through each element in the array
	for command_argument in "${command_arguments[@]}"; do
	    # Wrap the element in quotes and append to the result string
	    arguments+="\"$command_argument\" "
	done

	# Trim the trailing space
	arguments="${arguments% }"

    if [ ! -d "$command_dir/$module_name"  ]; then
        mkdir -p "$command_dir/$module_name" 
    fi

    log DEBUG "Building tempory command for module ${BOLD}$module_name${RESET} command ${BOLD}$command${RESET}"

    local command_tmp="${session_commands[${module_name}_${command}]}"
    if [ ! -n "$command_tmp" ]; then
        command_tmp=$(mktemp -p "$command_dir/$module_name" "${command}_XXXX")
        session_commands["${module_name}_${command}"]="$command_tmp"

        log DEBUG "Created tempory command script ${BOLD}$command_tmp${RESET} for command ${BOLD}$command${RESET} in module ${BOLD}$module_name${RESET}"
    fi

    log DEBUG "Running command ${BOLD}./modules/$module_name/$command.sh $arguments${RESET} wraped in ${BOLD}$command_tmp${RESET}"

    cp "$config_dir/command_template.sh" "$command_tmp"

    sed -i "s/\$debug/$debug/g" $command_tmp
    sed -i "s|\$tmp_dir|$tmp_dir|g" $command_tmp
    sed -i "s|\$env_file|$env_file|g" $command_tmp
    sed -i "s|\$timestamp|$timestamp|g" $command_tmp
    sed -i "s|\$file_store|$file_store|g" $command_tmp
    sed -i "s/\$development/$development/g" $command_tmp
    sed -i "s|\$commands_dir|$commands_dir|g" $command_tmp
    sed -i "s/\$igor_environment/$igor_environment/g" $command_tmp
    
	sed -i "s/\$command/$command/g" $command_tmp
	sed -i "s/\$module/$module_name/g" $command_tmp
	sed -i "s|\$arguments|$arguments|g" $command_tmp
	
	env -i /bin/bash -c "/bin/bash $command_tmp $arguments"
	local command_exit_value=$?

	command_result=$(store_peek)
    command_results["${module_name}.${command}"]="$command_result"

	log DEBUG "Exit code ${BOLD}$command_exit_value${RESET} and value ${BOLD}$command_result${RESET} returned for running command ./modules/$module_name/$command.sh $arguments"

	return $command_exit_value
}

#
 #
#
function run_command_direct() {
    local module_command="$1"
    shift

    local module_name="${module_command%%:*}"
    local command_name="${module_command##*:}"

    run_command "$module_name" "$command_name" "$@"
}

 # Function to check command existence and display error message if not found
function run_command_exists() {
    local command_name=$1
    local error_message=$2
    
    if command -v "$command_name" &> /dev/null; then
        log INFO "${GREEN}OK: ${BOLD}$command_name${RESET}"
        return 1
    else
        log ERROR "${YELLOW}$error_message${RESET}."
        return 0
    fi
}

function run_command_check() {
    local command_name=$1
    local ok_message=$2
    local nok_message=$3
    
    run_command $module_name $command_name

    if [ $? -eq 0 ]; then
        log INFO "${GREEN}OK: ${BOLD}$command_name${RESET}"
        return 0
    else
        log ERROR "${YELLOW}$nok_message${RESET}."
        return 1
    fi
}

function run_command_condition() {
    local command_name=$1
    shift 1 # Shift the first arguments (command_name and command) out of the way
    local command_arguments=("$@") # Store the remaining arguments as an array

    local command_not=1;

    if [[ $command_name == !* ]]; then
        # Remove "!" from the beginning of the string
        command_name="${command_name:1}"
        command_not=0
    fi

    run_command $module_name $command_name "${command_arguments[@]}"

    if [ $? -eq 0 ]; then
        return $((1 ^ $command_not))
    else
        return $((0 ^ $command_not))
    fi
}

#
 # Returns 0 if the module has the command available
#
function has_command() {
    local module_command="$1"

    local module_name="${module_command%%:*}"
    local command_name="${module_command##*:}"

    if [ -d "$modules_dir/$module_name" ]; then
        if [ -f "$modules_dir/$module_name/$command_name.sh" ]; then
            return 0
        else 
            log ERROR "Module $module_name has no such command $command_name"
        fi
    else
        log ERROR "No such module $module_name"
    fi

    return 1
}

