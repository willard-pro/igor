#!/bin/bash

function is_git_dir() {
    # Run git status and capture the output
    git status &> /dev/null
	
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Call the function and return its result
is_git_dir
