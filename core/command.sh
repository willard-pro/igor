
command_result=""

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

    log DEBUG "Running command ${BOLD}./modules/$module_name/$command.sh $arguments${RESET}"

    if [ ! -d "$command_dir/$module_name"  ]; then
        mkdir -p "$command_dir/$module_name" 
    fi

    local command_tmp=$(mktemp -p "$command_dir/$module_name" "${command_name}_XXXX")
    local command_bash="./modules/$module_name/$command.sh"

    cp "$config_dir/command_template.sh" "$command_tmp"
    

	sed -i "s/\$command/$command/g" $command_tmp
	sed -i "s/\$module/$module_name/g" $command_tmp
	sed -i "s/\$arguments/$arguments/g" $command_tmp
	
	env -i /bin/bash -c "export debug=$debug && export file_store=$file_store && /bin/bash $command_tmp $arguments"
	local command_exit_value=$?

	store_peek

	command_result="$store_value"
    command_results["$module_name.$command"]="$command_result"

	log DEBUG "Exit code ${BOLD}$command_exit_value${RESET} and value ${BOLD}$store_value${RESET} returned for running command ./modules/$module_name/$command.sh $arguments"

	return $command_exit_value
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