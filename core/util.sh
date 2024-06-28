
function replace_values() {
    local input_string="$1"

    local output_string="$input_string"
    local pattern='\$\{value:([^}]+)\}'

    # Use a while loop to find anarrayd replace all occurrences of the pattern
    while [[ $output_string =~ $pattern ]]; do
        # Extract the key
        local key="${BASH_REMATCH[1]}"
        if [[ ! $key == page.* ]]; then
            key="page.${page_name}.${key}"
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
                key="page.${page_name}.${key}"
            fi

            result_array+=("${page_prompt_results[$key]}")
        else
            result_array+=("$argument")
        fi
    done    
    result_array=("${result_array[@]:1}")

    echo "${result_array[@]}"
}


function is_module_configured() {
    local module_name="$1"
    has_configuration_property $module_name "configured"
}

function has_configuration_property() {
    local module_name="$1"
    local property_name="$2"

    local result=$(jq -r --arg name "$module_name" --arg key "$property_name" '.modules[] | select(.name == $name) | .configured' "$env_file")
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

is_version_greater() {
    local version1=(${1//./ })
    local version2=(${2//./ })

    local len=${#version1[@]}
    for ((i=0; i<$len; i++)); do
        if ((10#${version2[i]} > 10#${version1[i]})); then
            return 0
        elif ((10#${version2[i]} < 10#${version1[i]})); then
            return 1
        fi
    done
    
    return 1
}