
prompt_result=""

function page_prompt_user_options() {
    local prompt_label=$(echo $prompt | jq -r '.label')
    local prompt_options_array=()

    prompt_label=$(replace_values "$prompt_label")

    local is_array=$(echo "$prompt" | jq '.options | type == "array"')
    if [ "$is_array" == "true" ]; then
        local prompt_options_all=$(echo "$prompt" | jq -r '.options[] | .name')
    else
        local prompt_options_all=$(echo "$prompt" | jq '.options')

        if [[ $prompt_options_all =~ \$\{command:([^}]*)\} ]]; then
            local command="${BASH_REMATCH[1]}"
            
            local command_arguments=$(get_arguments "$command")
            local command_only="${command%% *}"

            run_command "$module_name" "$command_only" ${command_arguments[@]}

            local generated_options=$(echo "$command_result" | jq '.options')
            prompt=$(echo "$prompt" | jq --argjson generated_options "$generated_options" '.options = $generated_options')
            prompt_options_all=$(echo "$prompt" | jq -r '.options[] | .name')
        fi        
    fi    

    readarray -t prompt_options <<< "$prompt_options_all"
    for prompt_option in "${prompt_options[@]}"; do
        local has_condition=$(echo "$prompt" | jq --arg name "$prompt_option" '.options[] | select(.name == $name) | has("condition")')

        if [[ $has_condition == "true" ]]; then
            local prompt_option_condition=$(echo "$prompt" | jq -r --arg name "$prompt_option" '.options[] | select(.name == $name) | .condition')

            log DEBUG "Evaluating condition $prompt_option_condition on prompt $prompt_option"

            if [[ $prompt_option_condition =~ \$\{command:([^}]*)\} ]]; then
                local command="${BASH_REMATCH[1]}"
                
                local command_arguments=$(get_arguments "$command")
                local command_only="${command%% *}"

                run_command "$module_name" "$command_only" ${command_arguments[@]}
                local command_condition_exit_value=$?

                local not_command=0
                if [[ $prompt_option_condition == \!* ]]; then
                    not_command=1
                fi

                local command_condition_result=$(( not_command ^ command_condition_exit_value))

                if [  $command_condition_result -eq 0 ]; then
                    prompt_options_array+=("$prompt_option")
                else
                    log DEBUG "Skipping option ${BOLD}$option${RESET}, condition ${BOLD}$prompt_option_condition${RESET} not met"
                fi

            fi        
        else
            prompt_options_array+=("$prompt_option")
        fi
    done
    # prompt_options_array+=("Exit")


    PS3="$prompt_label: "
    select prompt_option in "${prompt_options_array[@]}"; do
        if [[ " ${prompt_options_array[@]} " =~ " $prompt_option " ]]; then

            local selected_prompt_option=$(echo $prompt | jq -r --arg selected "$prompt_option" '.options[] | select (.name == $selected) | .value')
            prompt_result=$selected_prompt_option
            break
        else
            log ERROR "Invalid choice!"
        fi
    done
}

function page_prompt_user_question() {
    local prompt_label=$(echo $prompt | jq -r '.label')
    local prompt_format=$(echo $prompt | jq -r '.format')

    prompt_label=$(replace_values "$prompt_label")

    case $prompt_format in
        "number")
            page_prompt_user_number "$prompt_label"
            ;;
        "yn")
            page_prompt_user_yn "$prompt_label"
            ;;
        "continue")
            page_prompt_user_continue "$prompt_label"
            ;;
        "string")
            page_prompt_user_text "$prompt_label"
            ;;
        "dir")
            page_prompt_user_directory "$prompt_label"
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
function page_prompt_user_yn() {
    local prompt_label=$1

    prompt_label="${prompt_label} [y/N]"

    while true; do
        read -r -p "$prompt_label: " response

        if is_yn "$response"; then
            prompt_result=$response
            break
        else
            log ERROR "Invalid input. Please enter either y for yes or n for no."
        fi                
    done
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function page_prompt_user_continue() {
    local prompt_label=$1
    
    page_prompt_user_yn "$prompt_label"

    if [[ "$prompt_result" =~ ^[nN]$ ]]; then
        log_phrase
        exit 0
    fi    
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function page_prompt_user_text() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response
        prompt_result=$response
        break
    done
}

# ####
# Function will place selected response in variable prompt_result  
# ####
function page_prompt_user_number() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response

        if is_number "$response"; then
            prompt_result=$response
            break
        else
            log ERROR "Invalid input. Please enter a number."
        fi                
    done
}


function page_prompt_user_directory() {
    local prompt_label=$1

    while true; do
        read -r -p "$prompt_label: " response

        if is_dir "$response"; then
            prompt_result=$response
            break
        else
            log ERROR "Invalid input. Please enter a valid directory."
        fi                
    done
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
