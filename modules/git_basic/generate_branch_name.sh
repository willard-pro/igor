
function generate_branch_name() {
	local branch_type = $1
	local ticket_number=$2
	local ticket_name=$3

	# Convert the input string to lowercase using 'tr' command
    local ticket_name_lowercase=$(echo "$ticket_name" | tr '[:upper:]' '[:lower:]')

    # Replace spaces with dashes using 'sed' command
    local ticket_name_formatted=$(echo "$ticket_name_lowercase" | sed 's/ /-/g')
    
    local branch_name="$branch_type/$type-$ticket_number-$ticket_name_formatted"

    log INFO "Generated branch name: ${YELLOW}$branch_name/${GREEN}$type-$number-$formatted_string${RESET}"
}