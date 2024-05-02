#!/bin/bash

debug=0

core_dir="core"
config_dir="config"
modules_dir="modules"

# file_store=$(mktemp)
file_store="store.txt"

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

modules=$(jq -r '.modules[].name' < "$config_dir/user.json")

log DEBUG "Core loaded..."
banner "$config_dir/banner.txt"

PS3="Select the desired module's functions to access: "
options=("${modules[@]}")  # Using modules as options

select type in "${options[@]}"; do
	if [[ " ${options[@]} " =~ " $type " ]]; then
		selected_module_source=$(jq -r --arg selected "$type" '.modules[] | select(.name == $selected) | .source' < "$config_dir/user.json")
		load_module $selected_module_source
        break
    else
        log ERROR "Invalid choice!"
    fi
done

