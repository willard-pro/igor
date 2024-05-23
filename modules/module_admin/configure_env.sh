
tmp_dir="tmp"
config_dir="config"

function configure_env() {
	local env_name=$1

	local env_file="$config_dir/env.json"

	touch $env_file
	jq --arg name "$env_name" '. + { "environment": $name }' $env_file > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" $env_file
}