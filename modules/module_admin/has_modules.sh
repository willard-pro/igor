
function has_modules() {
	has_modules=$(jq 'has("modules") and (.modules | length > 1)' $env_file)

	if [[ $has_modules == "true" ]]; then
		return 0
	else
		return 1
	fi	
}