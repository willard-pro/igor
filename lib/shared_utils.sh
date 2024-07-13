
#
 # Makes use of the hash found in the environment file and uses 
 # openssl to encrypt the provided text
#
function encrypt() {
    local input_string="$1"

    local hash=$(jq -r '.hash' "$env_file")

    echo "$input_string" | openssl enc -aes-256-cbc -pbkdf2 -a -salt -pass pass:"$hash" | sed ':a;N;$!ba;s/\n/\\n/g'
}

#
 # Makes use of the hash found in the environment file and uses 
 # openssl to decrypt the provided text
#
function decrypt() {
    local input_string="$1"

    local hash=$(jq -r '.hash' "$env_file")

    echo "$input_string" | openssl enc -aes-256-cbc -pbkdf2 -d -a -salt -pass pass:"$hash"
}


function environment_get() {
    echo "$igor_environment"
}

function environment_match() {
	local environment_name="$1"

    if [[ "$environment_name" == "$igor_environment" ]]; then
    	return 0;
    else
    	return 1;
    fi
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


function get_configuration_property() {
    local module_name="$1"
    local property_name="$2"

    local result=$(jq -r --arg name "$module_name" --arg key "$property_name" '.modules[] | select(.name == $name) | .[$key]' "$env_file")
    echo "$result"
}


function is_array() {
    local var="$1"
    declare -p "$var" 2>/dev/null | grep -q 'declare \-a'
}

function is_assoc_array() {
    local var="$1"
    declare -p "$var" 2>/dev/null | grep -q 'declare \-A'
}

#
 # array=( "cat" "apple" "mars" )
 # array_to_string "${array[@]}"
 # 
 # result: "apple,cat,mars"
#
function array_to_string() {
    local array=("$@")
    local str=""

    for item in "${array[@]}"; do
        str+="$item,"
    done

    str="${str%,}"
    echo "$str"
}

#
 # array=( "cat_1" "apple_100" "mars_5" )
 # array_search_and_replace "_" " " "${array[@]}"
 # 
 # result: "cat 1,apple 100,mars 5"
#
function array_search_and_replace() {
    local search="$1"
    local replace="$2"
    shift 2
    local array=("$@")

    for i in "${!array[@]}"; do
      array[i]="${array[i]//$search/$replace}"
    done

    echo "$array"
}

function sort_array() {
	local array=("$@")

	if [[ ${array[0]} =~ ^[0-9]+$ ]]; then
		sort_array_numeric "${array[@]}"
	elif [[ ${array[0]} =~ ^#[0-9]+ ]]; then
        sort_array_numeric_and_remove_index "${array[@]}"
    else
    	sort_array_alpha_numeric "${array[@]}"
	fi
}

#
 # array=( "cat" "apple" "mars" )
 # sort_array_alpha_numeric "${array[@]}"
 # 
 # result: ( "apple" "cat" "mars")
#
function sort_array_alpha_numeric() {
	local array=("$@")

	local sorted_array=$(for i in "${array[@]}"; do echo "$i"; done | sort)

	echo "$sorted_array"
}

#
 # array=( "11" "4" "5" )
 # sort_array_alpha_numeric "${array[@]}"
 # 
 # result: ( "4" "5" "11")
#
function sort_array_numeric() {
	local array=("$@")
	local sorted_array

	IFS=$'\n' sorted_array=($(echo "${array[*]}" | sort -n))
	echo "$sorted_array"
}

#
 # array=( "#2 cat" "#1 apple" "#5 mars" "#3 orange" )
 # sort_array_numeric_and_remove_index "${array[@]}"
 #
 # result: ( "apple" "cat" "orange" "mars")
#
sort_array_numeric_and_remove_index() {
	local array=("$@")
    local sorted_array

    # Sort the array based on the numeric prefix after #
    IFS=$'\n' sorted_array=($(for item in "${array[@]}"; do echo "$item"; done | sort -t'#' -k2n))
    
    # Remove the numeric prefix and #
    for i in "${!sorted_array[@]}"; do
        sorted_array[$i]=$(echo "${sorted_array[$i]}" | sed 's/^#[0-9]* //')
    done
    
    # Print the sorted array
    echo "$sorted_array"
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
        font_color=""
    fi

    echo
    # Read the file line by line and echo each line with -e option
    while IFS= read -r line; do
        echo -e "$font_color$line${RESET}"
    done < "$filename"
    echo
}

#
 # array=()
 # print_array "${array[@]}"
#
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

#
 # text="cat\napple\nmars
 # read_array "$text"
 # 
 # result: ( "cat" "apple" "mars")
#
function read_array() {
    local text="$1"
    local array=()

    while IFS= read -r line; do
        array+=("$line")
    done <<< "$text"    

    echo "${array[@]}"
}