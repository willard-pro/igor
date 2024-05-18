
function replace_values() {
    local input_string="$1"

    local output_string="$input_string"
    local pattern='\$\{value:([^}]+)\}'

    # Use a while loop to find and replace all occurrences of the pattern
    while [[ $output_string =~ $pattern ]]; do
        # Extract the key
        key="${BASH_REMATCH[1]}"
        # Get the value from the associative array, if it exists
        replacement="${page_prompt_results[$key]}"
        # Replace the pattern with the value in the string
        output_string="${output_string//${BASH_REMATCH[0]}/$replacement}"
    done

    echo "$output_string"
}

function get_values() {
    local input_string="$1"

    local -a result_array=()
    local pattern='\$\{value:([^}]+)\}'

    while [[ $input_string =~ $pattern ]]; do
        local match="${BASH_REMATCH[0]}"
        local key="${BASH_REMATCH[1]}"
        local replacement="${page_prompt_results[$key]}"
        input_string="${input_string//$match/$replacement}"
        result_array+=("$replacement")
    done

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