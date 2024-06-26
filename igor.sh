#!/bin/bash

debug=0
development=0

lib_dir="lib"
core_dir="core"
config_dir="config"
modules_dir="modules"
commands_dir="commands"

tmp_dir="tmp"
timestamp=$(date +"%Y%m%d%H%M%S")

env_file="$config_dir/env.json"
file_store="$tmp_dir/$timestamp/store.txt"
command_dir="$tmp_dir/$timestamp/commands"

#
 # Creates a basic environment for Igor
#

function create_environment() {
	echo '{}' > "$env_file"

	jq --arg name "unknown" '. + { "environment": $name }' $env_file > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" $env_file

	new_module=$(jq -n --arg name "module_admin" --arg configured "false" '{ "name": $name, "configured": $configured }')
	jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"	
}

#
 # Creates the temporary space and files which will contain the commands executed and their results
#
function create_workspace() {
	if [ ! -d "$tmp_dir" ]; then
		mkdir -p $tmp_dir
	fi

	if [ ! -d "$command_dir" ]; then
		mkdir -p $command_dir
	fi

	if [ ! -f "$file_store" ]; then
		touch $file_store
	fi

	if [ ! -f $env_file ]; then
		create_environment
	fi
}

#
 # Loads each bash script found in ./lib
 # These are bash scripts which wil be available by default for commands
#
function load_libraries() {
	for lib_file in "$lib_dir"/*.sh; do
	    if [ -r "$lib_file" ]; then
	       	if ! bash -n "$lib_file"; then
	    		echo "Syntax errors found in $core_file."
	    		exit 1
	  		fi
	  		
	        source "$lib_file"
	    else
	        echo "Warning: Skipping non-readable or non-executable file: $core_file"
	    fi
	done
}

#
 # Loads each bash script found in ./core
 # These bash scripts form the core of Igor, pages, prompts and commands
#
function load_core() {
	for core_file in "$core_dir"/*.sh; do
	    if [ -r "$core_file" ]; then
	       	if ! bash -n "$core_file"; then
	    		log ERROR "Syntax errors found in $core_file."
	    		exit 1
	  		fi
	  		
	        source "$core_file"
	    else
	        log WARN "Skipping non-readable or non-executable file: $core_file"
	    fi
	done
}

#
 # Check if the required commands are available on the CLI, otherwise Igor cannot function properly
 # - curl
 # - jq
 # - sort
 # - shuf
 # - unzip
#
function check_igor_commands() {
	log DEBUG "Check if all required commands are available..."
	run_command_exists "curl" "${YELLOW} ${BOLD}curl${RESET} command not found. You will not be able to use Igor's update function...${RESET}."
	run_command_exists "jq" "${YELLOW} ${BOLD}jq${RESET} command not found. Without it, Igor will be unable to parse the module configuration. Please install jq and try again${RESET}."
	if [ $? -eq 0 ]; then
		exit 1
	fi
	run_command_exists "sort" "${YELLOW} ${BOLD}sort${RESET} command not found. Please install sort and try again${RESET}."
	if [ $? -eq 0 ]; then
		exit 1
	fi
	run_command_exists "shuf" "${YELLOW} ${BOLD}sort${RESET} command not found. Igor will be unable to say good bye without it${RESET}."
	run_command_exists "unzip" "${YELLOW} ${BOLD}unzip${RESET} command not found. You will not be able to use Igor's update function...${RESET}."
}

#
 # Checks if the environment variable HOME is available and validates that Igor is installed
 # If not installed it will install and/or upgrade Igor into ~/.igor
#
function validate_igor_home() {
	if [[ -v HOME && $development -eq 0 ]]; then
		if [[ ! -d "$HOME/.igor" ]]; then
			install_igor
		else
			if [[ "${BASH_SOURCE[0]}" != "usr/local/bin/igor" ]]; then
				log IGOR "My workbench exists, please call me at ${BOLD}/usr/local/bin/igor${RESET}"
				exit 1
			fi
		fi
	fi	
}

#
 # Create a symbolic link to /usr/local/bin/igor, such that it can be executed from anywhere
#
function install_igor() {
	log IGOR "I sense that this is the first time you are making use of my services"
	log IGOR "If you wish to test or improve my services invoke me with ${BOLD}--develop${RESET}"
	page_prompt_user_continue "May I continue and install my workbench"
	
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

	ln -s "$HOME/.igor/igor.sh" /usr/local/bin/igor

	log IGOR "I have completed installing and configuring my workbench"
	log IGOR "Please delete this directory as it is no longer required"
	log IGOR "Shoud you need me again, just call on my name ${BOLD}/usr/local/bin/igor${RESET}"

	log_phrase
	exit 0
}

#
 # Updates the installed version of Igor
 #
#
function update_igor() {
	echo
	log IGOR "Checking if there is a new version to clone"

	local download_dir="$tmp_dir/download"

	if [ ! -d "$download_dir" ]; then
		mkdir -p "$download_dir"
	fi

	# curl -o "$download_dir/version.txt" -s "https://raw.githubusercontent.com/willard-pro/igor/main/version.txt"
	# local remote_version=$(cat "$download_dir/version.txt")
	local remote_version="1.0.0-SNAPSHOT"
	local igor_version=$(cat version.txt)

	local version_result=$("$commands_dir/semver.sh" compare "$remote_version" "$igor_version")
	if [ $version_result -eq 1 ]; then
		log IGOR "New version, $remote_version has been detected"
		echo
		page_prompt_user_continue "May I continue and install the new version"

		# curl -o "$download_dir/igor-$remote_version.zip" -LOJ https://github.com/exampleuser/willard-pro/igor/archive/refs/heads/main.zip
		# unzip -o "$download_dir/igor-$remote_version.zip" -d "$HOME/.igor"

		log IGOR "Sucessfully updated to version $remote_version"
	else 
		log IGOR "Already on latest version"
	fi

	exit 1
}

#
 # Print the Igor logo and banner 
 #
#
function logo_and_banner() {
	local igor_banner_color=$(jq -r --arg name "$igor_environment" '.environment[] | select(.name == $name) | .banner_color' "$config_dir/default.json")
	local igor_banner_color=$(to_color "$igor_banner_color")

	declare -A box_key_values
	box_key_values["Environment"]=$(jq -r --arg name "$igor_environment" '.environment[] | select(.name == $name) | .label' "$config_dir/default.json")
	box_key_values["Version"]=$(cat version.txt)

	print_banner "$config_dir/banner.txt" $igor_banner_color
	print_box box_key_values 
}

#
 # By default Igor expects no arguments, but some are supported
 # The folowing arguments are supported
 #  --update (allows for update of Igor either remote or local)
 #  --module (name of the module whose command will be executed)
 #  --command (name of the command wihtin the module to execute)
#
function process_arguments() {
	local module=""
	local module_command=""
	local module_arguments=()

	while [[ "$#" -gt 0 ]]; do
	    case $1 in
	        --debug) 
				;;
	        --develop)
				;;	    	
	        --update) 
				update_igor
				;;
			--module)
			    if [[ -n "$2" && ${2:0:1} != "-" ]]; then
			    	module="$2"
			    	shift 2

			    	case $1 in
						--command)
							if [[ -n "$2" && ${2:0:1} != "-" ]]; then
						    	module_command="$2"
						    	shift 2

						    	while [[ "$#" -gt 0 ]]; do
						    		module_arguments+=("$1")
						    		shift
						    	done
				            else
				                log ERROR "Missing command name after --command option"
				                exit 1
				            fi
				            ;;
				        *)
							log ERROR "Missing --command option after --module option"
							exit 1
						    ;;
					esac			    		
	            else
	                log ERROR "Missing module name after --module option"
	                exit 1
	            fi		    	
			    ;;
	    esac
	    shift
	done
}

#
 # By default Igor expects no flags, but some are supported
 # The folowing flags are supported
 #  --debug (enabe debug logging)
 #  --develop (enable development mode)
#
function process_flags() {
	while [[ "$#" -gt 0 ]]; do
	    case $1 in
	        --debug) 
				debug=1
				;;
	        --develop)
				development=1
				;;
	    esac
	    shift
	done
}

#
 # Load all available modules from the environment file
#
function display_modules() {
	options=()
	declare -A modules

	module_names=$(jq -r '.modules[].name' $env_file)

	# Iterate over the names
	for module_name in $module_names; do
		log DEBUG "Scanning $module_name"

	    if [[ $is_env_configured == "true" ]]; then
	    	if [[ ! -d "$modules_dir/$module_name" ]]; then
	    		mkdir $modules_dir/$module_name
	    	fi

	    	has_workspace=$(jq --arg name "$module_name" '.modules[] | select(.name == $name) | has("workspace")' $env_file)
	    	if [ "$has_workspace" = "true" ]; then
	    		module_workspace=$(jq -r --arg name "$module_name" '.modules[] | select(.name == $name) | .workspace' $env_file)

	    		log DEBUG "Copy experimental module from $module_workspace/$module_name"

	    		cp $module_workspace/$module_name/* $modules_dir/$module_name

				module_label=$(jq -r '.module.label' "$modules_dir/$module_name/config.json")
	    		module_label="$module_label"
	    	else
	    		module_label=$(jq -r '.module.label' "$modules_dir/$module_name/config.json")
	    	fi

	        # Store module directory and module name in the associative array
	        modules["$module_label"]="$module_name"
	        options+=("$module_label")
	   	elif [[ "$module_name" == "module_admin" ]]; then
	        modules["$module_label"]="$module_name"
	        options+=("$module_label")
	   	fi
	done

	#
	 # Sort options provided and display the modules sorted on label
	#
	sorted_options=$(sort_array "${options[@]}")
	while IFS= read -r line; do options_array+=("$line"); done <<< "$sorted_options"

	PS3="Select the desired module's functions to access: "

	select option in "${options_array[@]}"; do
	    if [[ "$REPLY" == "#" ]]; then
	    	log_phrase
	        exit 0
		elif [[ " ${options[@]} " =~ " $option " ]]; then

			selected_module_source=${modules["$option"]}
			load_module $selected_module_source
	    else
	        log ERROR "Invalid choice!"
	    fi
	done

}

###############################################################################
 # Main                                                                      #
###############################################################################

process_flags "$@"
load_libraries
validate_igor_home

create_workspace
load_core
check_igor_commands

igor_environment=$(jq -r '.environment' "$env_file")

if [[ development -eq 1 ]]; then
	echo 
	log IGOR "Process ID $$"
	log IGOR "Script values captured during execution are available at ${BOLD}$file_store${RESET}"
	log IGOR "Commands executed can be found in ${BOLD}$command_dir${RESET}"
fi

logo_and_banner

if [[ "$igor_environment" == "unknown" ]]; then
	is_env_configured=false
	log IGOR "This environment is unknown, complete ${BOLD}confguration${RESET}"
else
	is_env_configured=true
	process_arguments "$@"
fi

display_modules
log_phrase