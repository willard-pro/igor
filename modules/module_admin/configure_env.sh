
tmp_dir="tmp"

function configure_env() {
	local env_name=$1
	jq --arg name "$env_name" '. + { "environment": $name }' $env_file > "$tmp_dir/env.tmp" && mv "$tmp_dir/env.tmp" $env_file
}