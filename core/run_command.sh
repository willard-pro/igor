
function run_command() {
	local module_name=$1
	local command=$2
	shift 2 # Shift the first two arguments (module_name and command) out of the way
    local arguments=("$@") # Store the remaining arguments as an array

	# Use printf to properly escape the arguments for use in the command string
    local escaped_arguments
    printf -v escaped_arguments "%q " "${arguments[@]}"

	echo env -i /bin/bash -c "source core/colors.sh && source core/log.sh && /bin/bash ./modules/$module_name/$command.sh $escaped_arguments"
}