
command_result=""

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

    # local command_tmp=$(mktemp)
    local command_tmp="command.tmp"
    local command_bash="./modules/$module_name/$command.sh"

    cp "$config_dir/command_template.sh" "$command_tmp"
    

	sed -i "s/\$command/$command/g" $command_tmp
	sed -i "s/\$module/$module_name/g" $command_tmp
	sed -i "s/\$arguments/$arguments/g" $command_tmp
	
	env -i /bin/bash -c "export debug=$debug && export file_store=$file_store && /bin/bash $command_tmp $arguments"

	store_peek

	command_result="$store_value"
}