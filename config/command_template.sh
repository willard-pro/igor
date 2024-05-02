#!/bin/bash

source core/log.sh
source core/store.sh
source core/colors.sh

source modules/$module/$command.sh

$command $arguments

store_push "$command=$$command_result"