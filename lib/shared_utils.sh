
function environment_get() {
    local result=$(jq -r '.environment' "$env_file")
    echo "$result"
}

function environment_match() {
	local environment_name="$1"
    local result=$(jq -r '.environment' "$env_file")

    if [[ "$environment_name" == "$result" ]]; then
    	return 0;
    else
    	return 1;
    fi
}



function is_array() {
    local var="$1"
    declare -p "$var" 2>/dev/null | grep -q 'declare \-a'
}

function is_assoc_array() {
    local var="$1"
    declare -p "$var" 2>/dev/null | grep -q 'declare \-A'
}

function array_to_string() {
    local array=("$@")
    local str=""

    for item in "${array[@]}"; do
        str+="\"$item\","
    done

    str="${str%,}"
    echo "$str"
}



function print_banner() {
    local filename=$1
    local font_color=$2

    # Check if the file exists
    if [ ! -f "$filename" ]; then
        log ERROR "Banner not found, ${BOLD}$filename${RESET}"
        exit 1
    fi

    if [ ! -v font_color ]; then
        font_color=${WHITE}
    fi

    echo
    # Read the file line by line and echo each line with -e option
    while IFS= read -r line; do
        echo -e "$font_color$line${RESET}"
    done < "$filename"
    echo
}

function print_array() {
    local values=("$@")

    if [ ${#values[@]} -eq 0 ]; then
        log INFO "Array is empty"
    else
        for (( i=${#values[@]}-1; i>=0; i-- )); do
            log INFO "${values[i]}"
        done
    fi
}

function print_box() {
    local -n key_value_pairs=$1

    local box_width=29
    local key_value_width=$((box_width - 4))

    printf "╔"
    printf "═%.0s" $(seq 1 $((box_width - 2)))
    printf "╗\n"

  # Iterate over the keys and values of the associative array
    for key in "${!key_value_pairs[@]}"; do
        local value="${key_value_pairs[$key]}"
        printf "║ %-${key_value_width}s ║\n" "$key: $value"
    done

    printf "╚"
    printf "═%.0s" $(seq 1 $((box_width - 2)))
    printf "╝\n"

}
