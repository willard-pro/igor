#!/bin/bash

debug=$debug
development=$development

source core/log.sh
source core/store.sh
source core/colors.sh
source core/util.sh

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