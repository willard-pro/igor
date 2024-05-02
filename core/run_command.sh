
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
    
	env -i /bin/bash -c "export debug=$debug && ./modules/$module_name/$command.sh $arguments"
	# source core/colors.sh && source core/log.sh &&
}