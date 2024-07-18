#!/bin/bash

debug=$debug
tmp_dir=$tmp_dir
env_file=$env_file
timestamp=$timestamp
file_store=$file_store
development=$development
commands_dir=$commands_dir
igor_environment=$igor_environment

source lib/log.sh
source lib/colors.sh
source lib/shared_utils.sh

source core/store.sh
source modules/$module/$command.sh

$command $arguments
exit_code=$?

if [[ ! -v $command_result ]]; then
	$command_result=$exit_code
fi

if is_array $command_result; then
	tmp_result=$(array_to_string "${$command_result[@]}")
	store_push "$command=$tmp_result"
else
	store_push "$command=$$command_result"
fi

exit $exit_code