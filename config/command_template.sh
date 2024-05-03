#!/bin/bash

source core/log.sh
source core/store.sh
source core/colors.sh

source modules/$module/$command.sh

$command $arguments
exit_code=$?

if [[ ! -v $command_result ]]; then
	$command_result=$exit_code
fi

store_push "$command=$$command_result"

exit $exit_code