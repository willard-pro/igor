
function banner() {
    local filename=$1

    # Check if the file exists
    if [ ! -f "$filename" ]; then
        log ERROR "Banner not found, ${BOLD}$filename${RESET}"
        exit 1
    fi

    echo
    # Read the file line by line and echo each line with -e option
    while IFS= read -r line; do
        echo -e "$line"
    done < "$filename"
    echo
}

function menu() {
    local module_name=$1
    local menu_name=$2

    local module_config="$modules_dir/$module_name/config.json"

    local menu_label=$(jq -r --arg menu_name "$menu_name" '.menus[] | select(.menu == $menu_name) | .label' < $module_config)
    if [[ -v menu_label ]]; then
        if [[ $menu_label =~ \$\{command:([^}]*)\} ]]; then
            local command="${BASH_REMATCH[1]}"

            run_command "$module_name" "$command" "${argument_result_array[@]}"
            menu_label="${menu_label/\$\{command:$command\}/$command_result}"
        fi
    else
        menu_label="Menu ${BOLD}$menu_name${RESET}"
    fi

    echo -e "$menu_label"

    local menu_options=$(jq -r --arg menu_name "$menu_name" '.menus[] | select(.menu == $menu_name) | .options[].name' < $module_config)
    readarray -t options_all <<< "$menu_options"

    # Remove elements from the array if the condition is met
    options=()
    for option in "${options_all[@]}"; do
        local menu_condition=$(jq -r --arg menu_name "$menu_name" --arg option "$option" '.menus[] | select(.menu == $menu_name) | .options[] | select(.name == $option) | .condition' < $module_config)

        if [[ -v menu_condition ]]; then
            local command="${menu_condition%% *}"
            local arguments="${menu_condition#* }"
            # Converting the rest into an array
            arguments_array=($arguments)

            run_command_condition $command "${arguments_array[@]}"

            if [ $? -eq 0 ]; then
                options+=("$option")
            else
                log DEBUG "Skipping option ${BOLD}$option${RESET}, condition ${BOLD}$menu_condition${RESET} failed"
            fi
        else
            options+=("$option")
        fi
    done
    options+=("Exit")

    PS3="Select action to take: "
    select option in "${options[@]}"; do
        if [[ " ${options[@]} " =~ " $option " ]]; then

            if [[ $option == "Exit" ]]; then
                log_phrase
                exit 0
            fi

            local selected_command=$(jq -r --arg selected "$option" --arg menu_name "$menu_name"  '.menus[] | select (.menu == $menu_name) | .options[] | select (.name == $selected).command' < $module_config)

            if [[ $selected_command == menu:* ]]; then
                local sub_menu_name="${selected_command#menu:}"
                prompt $module_name $sub_menu_name
            fi
            break
        else
            log ERROR "Invalid choice!"
        fi
    done
}