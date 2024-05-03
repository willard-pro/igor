#!/bin/bash

debug=0

core_dir="core"
config_dir="config"
modules_dir="modules"

# file_store=$(mktemp)
tmp_dir="tmp"
file_store=$(mktemp -p "$tmp_dir" "store_XXXX")
command_dir="$tmp_dir/commands"

if [ ! -d "$tmp_dir" ]; then
	mkdir -p $tmp_dir
fi

if [ ! -d "$command_dir" ]; then
	mkdir -p $command_dir
fi

if [ ! -f "$file_store" ]; then
	touch $file_store
fi


# Check if the directory exists
if [ ! -d "$core_dir" ]; then
    echo "Error: Directory $core_dir does not exist."
    exit 1
fi

# Import all scripts from the directory
for core_file in "$core_dir"/*.sh; do
    # Check if the file is readable and executable
    # && [ -x "$core_file" ]
    if [ -r "$core_file" ]; then
       	# echo "Importing script: $core_file"
        source "$core_file"
    else
        echo "Warning: Skipping non-readable or non-executable file: $core_file"
    fi
done


# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --debug) debug=1
			;;
        # --load-module)
        #     if [[ -n "$2" && ${2:0:1} != "-" ]]; then
        #         module="$2"
        #         shift
        #     else
        #         log ERROR "Missing module name after --load-module option"
        #         usage
        #     fi
        #     ;;
    esac
    shift
done


log DEBUG "Check if all required commands are available..."
run_command_exists "jq" "${YELLOW} ${BOLD}jq${RESET} command not found. Please install jq and try again${RESET}."
if [ $? -eq 0 ]; then
	exit 1
fi
# add shuf as required command

modules=$(jq -r '.modules[].name' < "$config_dir/user.json")

log DEBUG "Core loaded..."


log INFO "Script values are stored during execution is available at ${BOLD}$file_store${RESET}"
log INFO "Comands executed can be found in ${BOLD}$command_dir${RESET}"

banner "$config_dir/banner.txt"

PS3="Select the desired module's functions to access: "
options=("${modules[@]}")  # Using modules as options
options+=("Exit")

select option in "${options[@]}"; do
	if [[ " ${options[@]} " =~ " $option " ]]; then
		if [[ $option == "Exit" ]]; then
			log_phrase
			exit 0
		fi

		selected_module_source=$(jq -r --arg selected "$option" '.modules[] | select(.name == $selected) | .source' < "$config_dir/user.json")
		load_module $selected_module_source
        break
    else
        log ERROR "Invalid choice!"
    fi
done

