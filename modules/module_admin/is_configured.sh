

function is_configured() {
	local result=$(is_module_configured "Modules")

	if [[ $result == "true" ]]; then
		return 0
	else
		return 1
	fi
}
