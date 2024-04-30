# Function to prompt the user for input
# Usage: prompt_user "Prompt message" "default value if user input is empty"
function prompt_user() {
    local prompt="$1"
    local default_value="${2:-}"

    read -p "$prompt" response

    # If the response is empty, return the default value
    if [ -z "$response" ]; then
        echo "$default_value"
    else
        echo "$response"
    fi
}