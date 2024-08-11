
prompt_result=""

function page_prompt_user_options() {
    local prompt_label=$(echo $prompt | jq -r '.label')
    local prompt_format=$(echo $prompt | jq -r '.format')
    local page_prompt_options=()

    prompt_label=$(replace_values "$prompt_label")

    local sort_options="asc"
    local has_sort=$(echo "$prompt" | jq --arg name "$prompt_option" 'has("sort")')
    if [[ $has_sort == "true" ]]; then
        sort_options=$(echo "$prompt" | jq -r --arg name "$prompt_option" '.sort')
    fi

    local is_array=$(echo "$prompt" | jq '.options | type == "array"')
    if [ "$is_array" == "true" ]; then
        local prompt_options_all=$(echo "$prompt" | jq -r '.options[] | .name')
    else
        local prompt_options_all=$(echo "$prompt" | jq -r '.options')

        if [[ $prompt_options_all =~ \$\{command:([^}]*)\} ]]; then
            local command="${BASH_REMATCH[1]}"
            local prompt_command_arguments="${prompt_options_all#*\$\{command:${command}\}}"

            local command_arguments=$(get_arguments "$command$prompt_command_arguments")
            local command_only="${command%% *}"

            run_command "$module_name" "$command_only" ${command_arguments[@]}

            local generated_options=$(echo "$command_result" | jq '.options')
            prompt=$(echo "$prompt" | jq --argjson generated_options "$generated_options" '.options = $generated_options')
            prompt_options_all=$(echo "$prompt" | jq -r '.options[] | .name')
        fi        
    fi    

    local prompt_options
    while IFS= read -r line; do prompt_options+=("$line"); done <<< "$prompt_options_all"

    for prompt_option in "${prompt_options[@]}"; do
        local has_condition=$(echo "$prompt" | jq --arg name "$prompt_option" '.options[] | select(.name == $name) | has("condition")')

        if [[ $has_condition == "true" ]]; then
            local prompt_condition=$(echo "$prompt" | jq -r --arg name "$prompt_option" '.options[] | select(.name == $name) | .condition')

            condition_page_prompt "$prompt_condition"
            if [[ $? -eq 0 ]]; then
                page_prompt_options+=("$prompt_option")
            fi    
        else
            page_prompt_options+=("$prompt_option")
        fi
    done

    local prompt_options_array=()

    if [[ "$sort_options" == "asc" ]]; then
        sorted_prompt_options=$(sort_array "${page_prompt_options[@]}")
        while IFS= read -r line; do prompt_options_array+=("$line"); done <<< "$sorted_prompt_options"
    elif [[ "$sort_options" == "none" ]]; then
        prompt_options_array=("${page_prompt_options[@]}")
    else 
        log ERROR "Unknown sort option ${BOLD}$sort_options${RESET}"
        exit 1
    fi

    prompt_options_length=${#page_prompt_options[@]}
    if [ $prompt_options_length -eq 0 ]; then
        log ERROR "No options available for prompt ${BOLD}$prompt_label${RESET}"
        exit 1
    elif [ $prompt_options_length -eq 1 ]; then
        local prompt_option=${page_prompt_options[0]}
        local selected_prompt_option=$(echo $prompt | jq -r --arg selected "$prompt_option" '.options[] | select (.name == $selected) | .value')
        prompt_result="$selected_prompt_option"

        log IGOR "For ${BOLD}$prompt_label${RESET}, the only option available is ${BOLD}${prompt_option}${RESET}, ${YELLOW}selected by default${RESET}"
    else
        PS3="$prompt_label: "
        select prompt_option in "${prompt_options_array[@]}"; do
            if [[ "$REPLY" == "$back_prompt_result" ]]; then
                prompt_result="\${page:back}"
                break
            elif [[ "$REPLY" == "exit_prompt_result"  ]]; then
                log_phrase
                exit 1
            elif [[ "$prompt_format" == "multi" && "$REPLY" =~ ^([0-9]+,)*[0-9]+$ ]]; then
                local prompt_selections
                local prompt_options_selected=()
                IFS=',' read -ra prompt_selections <<< "$REPLY"

                local valid=true
                for prompt_selection in "${prompt_selections[@]}"; do
                    if (( prompt_selection <= 0 || prompt_selection > ${#prompt_options_array[@]} )); then
                        valid=false
                    else
                        local selected_prompt_option=$(echo $prompt | jq -r --arg selected "${prompt_options_array[$prompt_selection-1]}" '.options[] | select (.name == $selected) | .value')
                        prompt_options_selected+=("$selected_prompt_option")    
                    fi
                done

                if $valid; then
                    prompt_result=$(array_to_string "${prompt_options_selected[@]}")
                    break
                else
                    log ERROR "Invalid option within the multi selected choice!"
                fi
            elif [[ " ${prompt_options_array[@]} " =~ " $prompt_option " ]]; then
                local selected_prompt_option=$(echo $prompt | jq -r --arg selected "$prompt_option" '.options[] | select (.name == $selected) | .value')
                prompt_result="$selected_prompt_option"
                break
            else
                log ERROR "Invalid choice!"
            fi
        done
    fi
}

function page_prompt_user_question() {
    local prompt_label=$(echo $prompt | jq -r '.label')
    local prompt_format=$(echo $prompt | jq -r '.format')

    local has_condition=$(echo "$prompt" | jq --arg name "$prompt_option" 'has("condition")')

    if [[ $has_condition == "true" ]]; then
        local prompt_condition=$(echo "$prompt" | jq -r '.condition')

        condition_page_prompt "$prompt_condition"
        if [[ $? -ne 0 ]]; then
            return 1
        fi    
    fi

    prompt_label=$(replace_values "$prompt_label")

    case $prompt_format in
        "number")
            page_prompt_user_number "$prompt_label"
            ;;
        "yN")
            page_prompt_user_yN "$prompt_label"
            ;;
        "Yn")
            page_prompt_user_Yn "$prompt_label"
            ;;
        "continue")
            page_prompt_user_continue "$prompt_label"
            ;;
        "exit")
            page_prompt_user_exit "$prompt_label"
            ;;            
        "string")
            page_prompt_user_text "$prompt_label"
            ;;
        "dir")
            page_prompt_user_directory "$prompt_label"
            ;;
        "file")
            page_prompt_user_file "$prompt_label"
            ;;
        "url")
            page_prompt_user_url "$prompt_label"
            ;;
        "yyyy-mm-dd")
            page_prompt_user_date "$prompt_label" "$prompt_format"
            ;;            
        *)
            log ERROR "Unsupported prompt format ${BOLD}$prompt_format${RESET}"
            exit 1 
            ;;
    esac
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function page_prompt_user_yN() {
    local prompt_label=$1

    prompt_label="${prompt_label} [y/N]"

    while true; do
        read -r -p "$prompt_label: " response

        if is_prompt_back_or_exit "$response"; then
            break
        else 
            if [ -z "$response" ]; then
                response="n"
            fi

            if is_yn "$response"; then
                prompt_result="${response,,}"
                break
            else
                log ERROR "Invalid input. Please enter either y for yes or n for no."
            fi
        fi
    done
}

function page_prompt_user_Yn() {
    local prompt_label=$1

    prompt_label="${prompt_label} [Y/n]"

    while true; do
        read -r -p "$prompt_label: " response

        if is_prompt_back_or_exit "$response"; then
            break
        else 
            if [ -z "$response" ]; then
                response="y"
            fi

            if is_yn "$response"; then
                prompt_result="${response,,}"
                break
            else
                log ERROR "Invalid input. Please enter either y for yes or n for no."
            fi                
        fi
    done
}


# ####
# Function will place selected response in variable prompt_result  
# ####
function page_prompt_user_continue() {
    local prompt_label=$1
    
    page_prompt_user_yN "$prompt_label"

    if [[ "$prompt_result" =~ ^[nN]$ ]]; then
        log_phrase
        exit 0
    fi    
}

function page_prompt_user_exit() {
    local prompt_label=$1
    
    echo "$prompt_label"
    read -n 1 -s
    log_phrase

    exit 0
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function page_prompt_user_text() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response

        if is_prompt_back_or_exit "$response"; then
            break
        elif valid_page_prompt "$response"; then        
            prompt_result=$response
            break
        fi
    done
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function page_prompt_user_number() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response

        if is_prompt_back_or_exit "$response"; then
            break
        elif is_number "$response"; then
            if valid_page_prompt "$response"; then
                prompt_result=$response
                break
            fi
        else
            log ERROR "Invalid input. Please enter a number."
        fi                
    done
}


function page_prompt_user_directory() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response

        if is_prompt_back_or_exit "$response"; then
            break
        elif is_dir "$response"; then
            if valid_page_prompt "$response"; then
                prompt_result=$response
                break
            fi
        else
            log ERROR "Invalid input. Please enter a valid directory."
        fi                
    done
}


function page_prompt_user_file() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response

        if is_prompt_back_or_exit "$response"; then
            break
        elif is_file "$response"; then            
            if valid_page_prompt "$response"; then
                prompt_result=$response
                break
            fi
        else
            log ERROR "Invalid input. Please enter a valid file path."
        fi                
    done
}

function page_prompt_user_url() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response

        if is_prompt_back_or_exit "$response"; then
            break
        elif is_url "$response"; then            
            if valid_page_prompt "$response"; then
                prompt_result=$response
                break
            fi
        else
            log ERROR "Invalid input. Please enter a valid URL."
        fi                
    done
}

function page_prompt_user_date() {
    local prompt_label="$1"
    local prompt_format="$2"

    while true; do
        read -r -p "$prompt_label ($prompt_format):" response

        if is_prompt_back_or_exit "$response"; then
            break
        elif is_date "$response"; then
            if valid_page_prompt "$response"; then
                prompt_result=$response
                break
            fi
        else
            log ERROR "Invalid input. Please enter a date in the format ${BOLD}$prompt_format${RESET}."
        fi                
    done
}


function valid_page_prompt() {
    local prompt_response="$1"
    local has_validation=$(echo "$prompt" | jq 'has("validate")')   

    if [[ $has_validation == "true" ]]; then
        local validate_command=$(echo "$prompt" | jq -r '.validate.command')
        local validate_message=$(echo "$prompt" | jq -r '.validate.message')

        # log DEBUG "Validate $prompt_validate on prompt $prompt_option"

        local not_command=0
        if [[ $validate_command == \!* ]]; then
            not_command=1
            validate_command="${validate_command:1}"
        fi

        local command_arguments=$(get_arguments "${validate_command/\$\{value:prompt.this\}/$prompt_response}")
        local command_only="${validate_command%% *}"

        run_command "$module_name" "$command_only" ${command_arguments[@]}
        local command_validate_exit_value=$?

        local command_validate_result=$(( not_command ^ command_validate_exit_value))

        if [  $command_validate_result -ne 0 ]; then
            log ERROR "$validate_message"
            return 1
        fi
    fi

    return 0
}

function condition_page_prompt() {
    local condition="$1"

    if [[ $condition =~ \$\{command:([^}]*)\} ]]; then
        local command="${BASH_REMATCH[1]}"
        
        local command_arguments=$(get_arguments "$command")
        local command_only="${command%% *}"

        run_command "$module_name" "$command_only" ${command_arguments[@]}
        local command_condition_exit_value=$?

        local not_command=0
        if [[ $condition == \!* ]]; then
            not_command=1
        fi

        local command_condition_result=$(( not_command ^ command_condition_exit_value))

        if [  $command_condition_result -ne 0 ]; then
            return 1
        fi
    elif [[ $condition =~ \$\{environment:([^}]*)\} ]]; then
        local environment="${BASH_REMATCH[1]}"

        local not_environment=0
        if [[ $condition == \!* ]]; then
            not_environment=1
        fi

        local environment_condition_exit_value=1
        local current_environment=$(environment_get)


        if [[ "$environment" == "$current_environment" ]]; then
            environment_condition_exit_value=0
        fi

        local environment_condition_result=$(( not_environment ^ environment_condition_exit_value))

        if [  $environment_condition_result -ne 0 ]; then
            return 1
        fi
    else
        local expr=$(replace_values "$condition")
        local regex='^(.+?)\s*(==|!=|<=|>=|<|>)\s*(.+)$'
          
        if [[ $expr =~ $regex ]]; then
            local left_operand="${BASH_REMATCH[1]}"
            local operator="${BASH_REMATCH[2]}"
            local right_operand="${BASH_REMATCH[3]}"
        else
            log ERROR "Condition $condition does not adhere to conditional syntax"
            exit 1
        fi

        # Check operand types
        if [[ $left_operand =~ ^[0-9]+$ && ! $right_operand =~ ^[0-9]+$ ]]; then
          log ERROR "$left_operand is a number but $right_operand is not."
          exit 1
        elif [[ ! $left_operand =~ ^[0-9]+$ && $right_operand =~ ^[0-9]+$ ]]; then
          echo "Error: $right_operand is a number but $left_operand is not."
          exit 1
        fi

        local eval_result=$(eval "if [[ $expr ]]; then echo 0; else echo 1; fi")
        return $eval_result
    fi

    return 0
}

#
 # Function to check if the user has entered either back or exit
# 
function is_prompt_back_or_exit() {
    local prompt_response="$1"

    if [[ "$prompt_response" == "$back_prompt_result" ]]; then
        prompt_result="\${page:back}"
        return 0
    elif [[ "$prompt_response" == "exit_prompt_result"  ]]; then
        log_phrase
        exit 0
    fi

    return 1
}

# Function to check if input is an integer
is_number() {
    local value=$1

    local regex='^[0-9]+$'
    if [[ $value =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if input is either yes or no
is_yn() {
    local value=$1

    local regex='^[yYnN]$'
    if [[ $value =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}


# Function to check if input is valid directory
is_dir() {
    local value=$1

    if [ -d "$value"  ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if input is valid file
is_file() {
    local value=$1

    if [ -f "$value"  ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if input is valid url
is_url() {
    local value=$1

    if curl -o /dev/null -s -w "%{http_code}" "$value" | grep -q "^[23]"; then
        return 0
    else 
        return 1
    fi
}

is_date() {
    local value="$1"
    local date_format="$2"

    case $date_format in
        "yyyy-mm-dd")
            is_date_yyyy_mm_dd "$value"
            ;;
    esac
}

is_date_yyyy_mm_dd() {
    local value="$1"

    if date -d "$user_date" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi    
}