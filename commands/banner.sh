
function banner() {
    local filename=$1
    local font_color=$2

    # Check if the file exists
    if [ ! -f "$filename" ]; then
        log ERROR "Banner not found, ${BOLD}$filename${RESET}"
        exit 1
    fi

    if [ -v font_color ]; then
    	font_color=${WHITE}
    fi

    echo
    # Read the file line by line and echo each line with -e option
    while IFS= read -r line; do
        echo -e "$font_color$line${RESET}"
    done < "$filename"
    echo
}
