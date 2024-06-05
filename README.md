# Igor

## Smartass 
Bash project which provides common functionality used by developers, testers and other keyboard warriors.

## About
The origin of __Igor__ came from repeating the same generic bash functions on different projects.  Too list a few:
- Restore local databases wih remote backups
- Generating PR from the CLI
- Triggering AWS tasks

Each of these scrpts, included a list of prompts in order to build up the input parameters required for the function to execute.  The creating of the prompts and validating the input took more time build than creatin the core functionality, especially when the script is shared among fellow developers.  

Hence the birth of __Igor__.  A means to provide a bash prompt based framework which uses a JSON file to construct the prompts and allow you to only focus on the underlying function.

Why the name __Igor__, I'm old school and Dr. Frankenstein was one of the classics and his servant __Igor__ was always their to assist him.

# Usage

```
Usage: igor

Options:
  --debug                    enables debug logging
  --develop                  enables development mode
```

# Core

Consits of code which drives the Igor

# Utils

# Environment


# Syntax

    {
      "module": {
        "name": "",
        "label": "",
        "type": "bash",
        "configurable": "true"
      },
      "required": {
        "commands": [
          "mysql",
          "grep",
          "docker"
        ]
      },  
      "pages": [
        {
          "name": "main",
          "label": "Database Administration",
          "command": "${page:database_action}",
          "prompts": [
            {
              "label": "Select database",
              "name": "database_selected",
              "options": "${command:get_databases}"
            },
            {
              "label": "Are you sure you want to select all databases",
              "name": "database_select_all",
              "format": "continue",
              "condition": "${value:prompt.database_selected} == 'all'"
            }
          ]
        }
        ...
      ]
    }

## Module

Module is made up of set of pages and goal is to provide the user with list of operations that can be peformed.  Such as different backup operation.  

## Page

Page consist of a label and list of prompts.

    <page>
    </page>

## Prompt

# Modules

## Module Administration

### Create



### Install
### Remove


# FAQ

1. How do I create a new module?
N


