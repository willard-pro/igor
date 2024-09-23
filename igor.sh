#!/bin/bash

admin=0
debug=0
enhancement=0
development=0
igor_environment="unknown"

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
 # Prints the basic usage of igor
#
function usage() {
	echo "Usage: igor [options]"
	echo
	echo "Options:"
	echo "  --admin					  	Enables administrative mode"
	echo "  --command <module:command>	Invokes a command of from a specified module directly"
	echo "  --develop                 	Enables development mode"
	echo "  --decrypt <text>           	Decrypts the specified text"
	echo "  --encrypt <text>           	Encrypts the specified text"
	echo "  --help                    	Show this help message and exit"
	echo "  --update                  	Performs a version check and updates if a later version is available"
	echo "  --verbose                 	Enable verbose mode"
	echo
	echo "Examples:"
	echo "  igor -encrypt MySecr3tPassw0rd"
	echo "  igor --command module_admin:create_module 'my_new_module' 'New Module' ~/workspace/igor-modules/my_new_module"

	exit 0
}

#
 # Creates a basic environment for Igor
#

function create_environment() {
	echo '{}' > "$env_file"

	local hash=$(openssl rand -base64 32)

	jq '. + { "environment": [] }' $env_file > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" $env_file
	jq --arg name "$hash" '. + { "hash":  $name }' $env_file > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" $env_file

	new_module=$(jq -n --arg name "module_admin" --arg configured "false" '{ "name": $name, "configured": $configured }')
	jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"

	cp "$env_file" "$config_dir/env_dev.json"
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
	if [[ -v HOME && $enhancement -eq 0 ]]; then
		if [[ ! -d "$HOME/.igor" ]]; then
			echo -e "Please complete the installation, by running the install script, install.sh"
			echo -e "In case you are making improvements, restart me in enhance mode, igor --develop"
			exit 1
		else
			if [[ "${BASH_SOURCE[0]}" != "/usr/local/bin/igor" ]]; then
				echo -e "My workbench exists, please call me at ${BOLD}/usr/local/bin/igor${RESET}"
				exit 1
			fi
		fi
	fi	
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

	local remote_version=$(curl -v https://github.com/willard-pro/igor/releases/latest 2>&1 | grep 'location:' | awk -F'tag/' '{print $2}')
	local igor_version=$(cat version.txt)

	local version_result=$("$commands_dir/semver.sh" compare "$remote_version" "$igor_version")
	if [ $version_result -eq 1 ]; then
		log IGOR "New version, $remote_version has been detected"
		echo
		page_prompt_user_continue "Would you like to continue and install the new version"

		curl -o $download_dir/igor.latest.zip -LOJ https://github.com/willard-pro/igor/releases/download/$remote_version/igor-$remote_version.zip
		unzip -o $download_dir/igor.latest.zip -d $HOME/.igor
		mv $HOME/.igor/igor-main/* $HOME/.igor/

		rm -rf $HOME/.igor/.github
		rm -rf $HOME/.igor/igor-main
		rm -rf $HOME/.igor/install.sh

		rm $download_dir/igor.latest.zip

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
	box_key_values["OS"]=$(detect_os)

	print_banner "$config_dir/banner/igor.txt" $igor_banner_color

	if [[ "$development" -eq 1 || "$enhancement" -eq 1 ]]; then
		print_banner "$config_dir/banner/linux.txt"
	fi

	print_box box_key_values 
}

#
 # By default Igor expects no arguments, but some are supported
 #
 # The folowing arguments are supported:
 #  --update (allows for update of Igor either remote or local)
 #  --command (name of the command wihtin the module to execute)
#
function process_arguments() {
	while [[ "$#" -gt 0 ]]; do
	    case $1 in
	    	--admin)
				;;
	        --verbose) 
				;;
	        --develop)
				;;
			--enhance)
				;;
			--help)
				;;	    	
			--command)
			    if [[ -n "$2" && ${2:0:1} != "-" ]]; then
			    	command="$2"
			    	shift 2

			    	if [[ "$command" =~ ^[a-zA-Z_]+:[a-zA-Z_]+$ ]]; then
			    		if has_command "$command"; then
					    	run_command_direct "$command" "$@"
					    	exit 0
					    else
					    	log IGOR "I have no knowledge of such a command"
					    	exit 1
					    fi
				    else 
				   		log ERROR "Command to execute should adhere to the pattern module:command, see usage for more details..."
				   		exit 1
				    fi
	            else
	                log ERROR "Missing command name after --command option"
	                exit 1
	            fi		    	
			    ;;
			--decrypt)
				if [[ -n "$2" && ${2:0:1} != "-" ]]; then
					decrypt "$2"
					exit 1
	            else
	                log ERROR "Missing text after --decrypt option"
	                exit 1
	            fi		    	
				;;
			--encrypt)
				if [[ -n "$2" && ${2:0:1} != "-" ]]; then
					encrypt "$2"
					exit 1
	            else
	                log ERROR "Missing text after --encrypt option"
	                exit 1
	            fi		    	
				;;
	        --update) 
				update_igor
				;;
	    esac
	    shift
	done
}

#
 # By default Igor expects no flags, but some are supported
 #
 # The folowing flags are supported
 #  --debug (enabe debug logging)
 #  --develop (enable development mode)
#
function pre_process_arguments() {
	while [[ "$#" -gt 0 ]]; do
	    case $1 in
	    	--admin)
				admin=1
				;;
	    	--command)
			    return
				;;
	        --develop)
				development=1
				env_file="$config_dir/env_dev.json"
				;;
			--decrypt)
			    if [[ -n "$2" && ${2:0:1} != "-" ]]; then
			    	shift 2
	            fi		    	
				;;
			--encrypt)
			    if [[ -n "$2" && ${2:0:1} != "-" ]]; then
			    	shift 2
	            fi		    	
				;;
			--enhance)
				enhancement=1
				;;
			--help)
				usage
				;;
			--update)
				;;
	        --verbose) 
				debug=1
				;;
			*)
				usage
				;;
	    esac
	    shift
	done
}

#
 # Load all available modules from the environment file
#
function display_modules() {
	local options=()
	declare -A modules

	local module_names=$(jq -r '.modules[].name' $env_file)

	# Iterate over the names
	for module_name in $module_names; do
		log DEBUG "Scanning $module_name"

		local skip=0
		if [[ $admin -eq 0 && "$module_name" == "module_admin" ]] || [[ $admin -ne 0 && "$module_name" != "module_admin" ]]; then
		    skip=1
		fi

	    if [[ skip -eq 0 ]]; then
    		if [[ -L $modules_dir/$module_name  ]]; then
    			rm $modules_dir/$module_name
    		fi

		    local module_version=$(jq -r --arg name "$module_name" '.modules[] | select(.name == $name) | .version' $env_file)
	    	local has_workspace=$(jq --arg name "$module_name" '.modules[] | select(.name == $name) | has("workspace")' $env_file)

	    	if [ "$has_workspace" = "true" ]; then
	    		local module_workspace=$(jq -r --arg name "$module_name" '.modules[] | select(.name == $name) | .workspace' $env_file)

	    		log INFO "Validating developmental module ${BOLD}$module_name${RESET}"
	    		run_command "module_admin" "is_valid_module" "$module_workspace/$module_name" 
	    		if [ $? -eq 0 ]; then
	    			log INFO "Linking developmental module ${BOLD}$module_name${RESET} from ${BOLD}$module_workspace/$module_name${RESET}"
	    			ln -s $module_workspace/$module_name $modules_dir/$module_name
	    		else
	    			log ERROR "Module $module_name failed basic validation, please have a look at the errors"
	    		fi
	    	elif [[ "$module_name" != "module_admin" ]]; then
	    		log INFO "Linking module ${BOLD}$module_name${RESET}"
		    	ln -s $module_name@$module_version $modules_dir/$module_name
	    	fi

    		if jq empty "$modules_dir/$module_name/config.json" > /dev/null 2>&1; then
				local module_label=$(jq -r '.module.label' "$modules_dir/$module_name/config.json")


				if [[ "$debug" -eq 1 ]]; then
					module_label="$module_label ($module_version)"
				fi

		        # Store module directory and module name in the associative array
		        modules["$module_label"]="$module_name"
		        options+=("$module_label")
		    else 
		    	log ERROR "Invalid configuration file for module named ${BOLD}$module_name${RESET}, skipping..."
		    fi
	   	fi
	done

	module_count=${#options[@]}

	if [ $module_count -eq 0 ]; then
		log IGOR "No modules have been installed"
		log IGOR "Invoke administrative mode to install modules, by running ${BOLD}${YELLOW}igor --admin${RESET}"
		exit 1
	else 
#
 # Sort options provided and display the modules sorted on label
#
		local sorted_options=$(sort_array "${options[@]}")
		while IFS= read -r line; do options_array+=("$line"); done <<< "$sorted_options"

		PS3="Select the desired module's functions to access: "

		select option in "${options_array[@]}"; do
		    if [[ "$REPLY" == "#" ]]; then
		    	log_phrase
		        exit 0
			elif [[ " ${options[@]} " =~ " $option " ]]; then

				selected_module_source=${modules["$option"]}
				load_module $selected_module_source

				log_phrase
				exit 0
		    else
		        log ERROR "Invalid choice!"
		    fi
		done
	fi
}

#
 #
 #
#
function set_environment() {
	# Check the number of elements in the environment array
	env_length=$(jq '.environment | length' "$env_file")

	if [ "$env_length" -eq 0 ]; then
		log ERROR "This environment is unfamiliar to me, please ${BOLD}configure${RESET}"

		if [ $admin -eq 0 ]; then
			log IGOR "Invoke administrative mode to configure the environment, by running ${BOLD}${YELLOW}igor --admin${RESET}"
			exit 1
		fi 
	elif [ "$env_length" -eq 1 ]; then
		igor_environment=$(jq -r '.environment[0]' "$env_file")
	elif [ $admin -eq 0 ]; then
# 
 # Environments is not applicable to administrative mode
#		
		display_environments
	fi	
}

#
 # Informs the user that Igor has been configured for multiple environments
 # and the environment to operate within needs to be selected
#
function display_environments() {
	print_banner "$config_dir/banner/env.txt"	
	log IGOR "You have configured multiple environments"

	local igor_environment_options=()

	local igor_environments=($(jq -r '.environment[]' "$env_file"))
	for igor_env in "${igor_environments[@]}"; do
		local igor_environment_label=$(jq -r --arg name "$igor_env" '.environment[] | select(.name == $name) | .label' "$config_dir/default.json")
		igor_environment_options+=("$igor_environment_label")
	done


	local igor_environment_options_sorted=$(sort_array "${igor_environment_options[@]}")
	while IFS= read -r line; do igor_environment_options_array+=("$line"); done <<< "$igor_environment_options_sorted"

	PS3="Please select an environment: "

	select option in "${igor_environment_options_array[@]}"; do
		if [[ " ${igor_environment_options[@]} " =~ " $option " ]]; then
			igor_environment=$(jq -r --arg name "$option" '.environment[] | select(.label == $name) | .name' "$config_dir/default.json")

			local igor_environment_color=$(jq -r --arg name "$igor_environment" '.environment[] | select(.name == $name) | .banner_color' "$config_dir/default.json")
			local igor_environment_color=$(to_color "$igor_environment_color")

			log IGOR "You have selected the $igor_environment_color${BOLD}$option${RESET} environment!"
			break	
	    else
	        log ERROR "Invalid choice!"
	    fi
	done
}

###############################################################################
 # Main                                                                      #
###############################################################################

pre_process_arguments "$@"

validate_igor_home

if [[ "$enhancement" -eq 0 ]]; then
	cd "$HOME/.igor" || exit
fi

#
 # Loads each bash script found in ./lib
 # These are bash scripts which wil be available by default for commands
#
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

create_workspace

#
 # Loads each bash script found in ./core
 # These bash scripts form the core of Igor, pages, prompts and commands
#
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

check_igor_commands

if [[ "$development" -eq 1 || "$enhancement" -eq 1 ]]; then
	log IGOR "Process ID $$"
	log IGOR "Script values captured during execution are available at ${BOLD}$file_store${RESET}"
	log IGOR "Commands executed can be found in ${BOLD}$command_dir${RESET}"
	echo
fi

set_environment
logo_and_banner

if [[ "$igor_environment" != "unknown" ]]; then
	process_arguments "$@"
fi

display_modules
log_phrase