
function is_development_mode() {
	if [[ "$development" -eq 1 ]]; then
		return 0
	else
		return 1
	fi
}