
function is_configured() {
	if [[ -f "$HOME/.igor/config/env.json" ]]; then
    	return 0
	else
    	return 1
	fi
}