
config_dir="config"

function is_configured() {
	if [[ -f "$config_dir/env.json" ]]; then
    	return 0
	else
    	return 1
	fi
}