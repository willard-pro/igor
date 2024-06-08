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

if [ ! -d "$tmp_dir" ]; then
	mkdir -p $tmp_dir
fi

if [ ! -d "$command_dir" ]; then
	mkdir -p $command_dir
fi

if [ ! -f "$file_store" ]; then
	touch $file_store
fi

if [ ! -d "$lib_dir" ]; then
    echo "Error: Directory $lib_dir does not exist."
    exit 1
fi

if [ ! -d "$core_dir" ]; then
    echo "Error: Directory $core_dir does not exist."
    exit 1
fi

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

for core_file in "$core_dir"/*.sh; do
    if [ -r "$core_file" ]; then
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


if [ ! -f $env_file ]; then
	is_env_configred="false"
	echo '{}' > "$env_file"

	jq --arg name "unknown" '. + { "environment": $name }' $env_file > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" $env_file

	new_module=$(jq -n --arg name "module_admin" --arg configured "false" '{ "name": $name, "configured": $configured }')
	jq --argjson new_module "$new_module" '.modules += [$new_module]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"
else
	if jq -e '.environment == "unknown"' "$env_file" > /dev/null; then
		is_env_configred="false"
	else
		is_env_configred="true"
	fi
fi

if [[ $is_env_configred == "false" ]]; then
	log IGOR "This environment is unknown, complete the ${BOLD}Module Administration Confguration${RESET}"
fi

# Extract the names using jq
module_names=$(jq -r '.modules[].name' $env_file)

# Iterate over the names
for module_name in $module_names; do
	log DEBUG "Scanning $module_name"

    if [[ $is_env_configred == "true" ]]; then
    	if [[ ! -d "$modules_dir/$module_name" ]]; then
    		mkdir $modules_dir/$module_name
    	fi

    	has_workspace=$(jq --arg name "$module_name" '.modules[] | select(.name == $name) | has("workspace")' $env_file)
    	if [ "$has_workspace" = "true" ]; then
    		module_workspace=$(jq -r --arg name "$module_name" '.modules[] | select(.name == $name) | .workspace' $env_file)

    		log DEBUG "Copy experimental module from $module_workspace/$module_name"

    		cp $module_workspace/$module_name/* $modules_dir/$module_name

			module_label=$(jq -r '.module.label' "$modules_dir/$module_name/config.json")
    		module_label="$module_label (Experimental)"
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


if [[ $development -eq 1 ]]; then
	log IGOR "Script values captured during execution are available at ${BOLD}$file_store${RESET}"
	log IGOR "Commands executed can be found in ${BOLD}$command_dir${RESET}"
fi

igor_environment="unknown"
if [ -f "$config_dir/env.json" ]; then
	igor_environment=$(jq -r '.environment' "$config_dir/env.json")
fi

igor_banner_color=$(jq -r --arg name "$igor_environment" '.environment[] | select(.name == $name) | .banner_color' "$config_dir/default.json")
igor_banner_color=$(to_color "$igor_banner_color")

declare -A box_key_values
box_key_values["Environment"]=$(jq -r --arg name "$igor_environment" '.environment[] | select(.name == $name) | .label' "$config_dir/default.json")
box_key_values["Version"]=$(cat version.txt)

print_banner "$config_dir/banner.txt" $igor_banner_color
print_box box_key_values 

PS3="Select the desired module's functions to access: "

select option in "${options[@]}"; do

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

log_phrase