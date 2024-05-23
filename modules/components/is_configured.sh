

function is_configured() {
	if [[ -f "$HOME/.igor/modules/components/env.json" ]]; then
    	return 0
	else
    	return 1
	fi
}