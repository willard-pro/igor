
function replace_values() {
    local input_string="$1"

    local output_string="$input_string"
    local pattern='\$\{value:([^}]+)\}'

    # Use a while loop to find and replace all occurrences of the pattern
    while [[ $output_string =~ $pattern ]]; do
        # Extract the key
        key="${BASH_REMATCH[1]}"
        if [[ ! $key == page.* ]]; then
            key="page.$page_name.$key"
        fi
        
        # Get the value from the associative array, if it exists
        replacement="${page_prompt_results[$key]}"
        # Replace the pattern with the value in the string
        output_string="${output_string//${BASH_REMATCH[0]}/$replacement}"
    done

    echo "$output_string"
}

function get_arguments() {
    local argument_string="$1"

    local argument
    local -a result_array=()

    local arguments=($argument_string)
    for argument in "${arguments[@]}"
    do
        if [[ $argument =~ \$\{value:([^}]+)\} ]]; then
            local key="${BASH_REMATCH[1]}"
        
            if [[ ! $key == page.* ]]; then
                key="page.$page_name.$key"
            fi
        
            result_array+=("${page_prompt_results[$key]}")
        else
            result_array+=("$argument")
        fi
    done    
    result_array=("${result_array[@]:1}")

    echo "${result_array[@]}"
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

function build_options() {
     local -n options=$1

    # Start the JSON object
    json_string=$(jq -n '{ "options": [] }')

    for key in "${!options[@]}"; do
        value=${options[$key]}
 
        option_json=$(build_option "$key" "$value")
        json_string=$(echo "$json_string" | jq -c --argjson option "$option_json" '.options += [$option]')
    done

    echo "$json_string" 
}

function build_option() {
    local name=$1
    local value=$2

    local json_string=$(jq -c -n --arg name "$name" --arg value "$value" '{name: $name, value: $value}')
    echo "$json_string"
}

function banner() {
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

function is_module_configured() {
    local module_name="$1"
    has_configuration_property $module_name "configured"
}

function has_configuration_property() {
    local module_name="$1"
    local property_name="$2"

    local result=$(jq --arg name "$module_name" --arg key "$property_name" '.modules[] | select(.name == $name) | has("configured")' "$env_file")
    echo "$result"
}


function configure_module() {
    local command_name=$1
    local module_name="$2"
    local property_name="$3"
    local property_value="$4"

    case "$command_name" in
        "done")
            set_configurtion_property "$module_name" "configured" "true"
            ;;
        "set")
            set_configurtion_property "$module_name" "$property_name" "$property_value"
            ;;
    esac
}

function set_configurtion_property() {
    local module_name="$1"
    local property_name="$2"
    local property_value="$3"

    jq --arg name "$module_name" --arg key "$property_name" --arg value "$property_value" '.modules |= map(if .name == $name then . + {($key): $value} else . end)' $env_file > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" $env_file

    log DEBUG "Updated environment configuration for module ${BOLD}$module_name${RESET} setting property ${BOLD}$property_name${RESET}=${BOLD}$property_value${RESET}"
}
