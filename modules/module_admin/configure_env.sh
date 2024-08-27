
function configure_env() {
	local env_name=$1

    local env_array=()

    if [[ "$env_name" == *","* ]]; then
        IFS=',' read -ra env_array <<< "$env_name"  # Split by comma into array
    else
        env_array=("$env_name")  # Convert single to aray
    fi

    for env_name_item in "${env_array[@]}"; do
		jq --arg name "$env_name_item" '.environment += [$name]' "$env_file" >> "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" "$env_file"
	done
}