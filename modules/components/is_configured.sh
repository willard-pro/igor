

function is_configured() {	
	local result=$(is_module_configured "Components")

	if [[ $result == "true" ]]; then
		return 0
	else
		return 1
	fi
}
