
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
    local menu_name=$1

    menu_options=$(jq -r '.menus[] | select(.menu == "$menu_name") | .options[].name' menu.json)
    echo "$menu_options"
}