#!/bin/bash

debug=0
development=0

core_dir="core"
config_dir="config"
modules_dir="modules"

tmp_dir="tmp"
timestamp=$(date +"%Y%m%d%H%M%S")

file_store="$tmp_dir/$timestamp/store.txt"
command_dir="$tmp_dir/$timestamp/commands"

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
       	if ! bash -n "$core_file"; then
    		echo "Syntax errors found in $core_file."
    		exit 1
  		fi
  		
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
        --develop) development=1
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

log DEBUG "Core loaded..."
	
log DEBUG "Check if all required commands are available..."
run_command_exists "jq" "${YELLOW} ${BOLD}jq${RESET} command not found. Please install jq and try again${RESET}."
if [ $? -eq 0 ]; then
	exit 1
fi
# add shuf as required command

if [ -v HOME ]; then
	if [[ ! -d "$HOME/.igor" && $development -eq 0 ]]; then
		log IGOR "I sense that this is the first time you are making use of my services"
		log IGOR "If you wish to test or improve my services invoke me with ${BOLD}--develop${RESET}"
		prompt_user_continue "May I continue and install my workbench"
		
		log IGOR "Creating ${BOLD}~/.igor${RESET} directory which will contain configuration and Igor's projects"
		mkdir -p "$HOME/.igor"
		mkdir -p "$HOME/.igor/core"
		mkdir -p "$HOME/.igor/config"
		mkdir -p "$HOME/.igor/modules"

		log IGOR "Copying configuration for my workbench"
		cp -R "./$config_dir" "$HOME/.igor"
		log IGOR "Copying core tools for my workbench"
		cp -R "./$core_dir" "$HOME/.igor"
		log IGOR "Copy over module(s) ${BOLD}module_admin${RESET} to my workbench"
		cp -R "./$module_dir/modules/module_admin" "$HOME/.igor/modules"

		echo ln -s "$HOME/.igor/igor" /usr/local/bin/igor.sh

		log IGOR "I have completed installing and configuring my workbench"
		log IGOR "Please delete this directory as it is no longer required"
		log IGOR "Shoud you need me again, just call on my name ${BOLD}/usr/local/bin/igor${RESET}"

		log_phrase
		exit 0
	else
		if [[ "${BASH_SOURCE[0]}" != "usr/local/bin/igor" && development -eq 0 ]]; then
			log IGOR "My workbench exists, please call me at ${BOLD}/usr/local/bin/igor${RESET}"
			exit 1
		fi
	fi
fi

options=()
declare -A modules

# Loop over all directories within the "modules" directory
for module_dir in $modules_dir/*/; do
	log DEBUG "Scanning $module_dir"

    # Check if config.json file exists in the current directory
    if [ -f "${module_dir}config.json" ]; then
        # Extract module name using jq
        module_name=$(jq -r '.module.name' "${module_dir}config.json")
        module_only_dir="${module_dir#*modules/}"
        module_only_dir="${module_only_dir::-1}"

        # Store module directory and module name in the associative array
        modules["$module_name"]="$module_only_dir"
        options+=("$module_name")
    fi
done

log IGOR "Script values captured during execution are available at ${BOLD}$file_store${RESET}"
log IGOR "Commands executed can be found in ${BOLD}$command_dir${RESET}"

banner "$config_dir/banner.txt"

PS3="Select the desired module's functions to access: "
options+=("Exit")

select option in "${options[@]}"; do
	if [[ " ${options[@]} " =~ " $option " ]]; then
		if [[ $option == "Exit" ]]; then
			log_phrase
			exit 0
		fi

echo ${modules["$option"]}
		selected_module_source=${modules["$option"]}
		load_module $selected_module_source
        break
    else
        log ERROR "Invalid choice!"
    fi
done

