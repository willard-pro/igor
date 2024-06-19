# Igor

## Goal

Bash project which provides a prompt based wrapper to scripts executed by keyboard warriors.  Let Igor take care of interacting with the user on the CLI using bash based prompts.

## About

The origin of __Igor__ came from repeating the same generic bash functions on different projects.  Too list a few:

- Restore local databases wih remote backups
- Generating PR from the CLI
- Triggering AWS tasks

Each of these scrpts, included a list of prompts in order to build up the input parameters required for the function to execute.  The creating of the prompts and validating the input took more time build than creatin the core functionality, especially when the script is shared among fellow developers.  

Hence the birth of __Igor__.  A means to provide a bash prompt based framework which uses a JSON file to construct the prompts and allow you to only focus on the underlying function.

Why the name Igor, I'm old school and Dr. Frankenstein was one of the classics and his servant Igor was always their to assist him.

# Usage

```
Usage: igor

Options:
  --debug                    enables debug logging
  --develop                  enables development mode
```

## Install

When Igor executes for the first time, he will verify the existence of the directory ~/.igor.  Should the directory not exist, he wil ask you if he may continue and install himself.

If you confirm, Igor will ask you to identiy in which environment he wil be assisting.   

## Debug Mode

Debug mode enables debug logging.

## Development Mode

If development mode is enabled, Igor executes from within the calling directory and not the installed directory *~/.igor*.  This enables the developer to execute Igor from within the git source directory.

# Core

Consits of code which drives the Igor engine, in summary the bash scripts responsible for generating the prompts and execute the scripts fo different modules.

# Environment

Supported environments are:

- Local (used by developers and testers)

- UAT (used by QA)

- Demo

- Production  

# Syntax

```json
{
  "module": {
    "name": "database",
    "label": "Database",
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
```

# Module

From the **user** perspective a module is a set of related functions, for example functions related to a developer managing a database,  restoring of the local database with data from either mock source or a backup...

From **developer** perspective a module is a contained unit of scripts which is provides a user one or more pages, with each one or more prompts, leading to different script executions.

## Required Commands

Igor needs to know of all the commands, inclusive of binaries and scripts, which will be executed by the module, in order to check that the required commands is available on the CLI path.  This is to ensure that the module has access to all it's underlying exectable resources.

## Configurable

A module may require additional configuration per environment, such as the name of a docker container in order to mange it.  These kind of configurations could be stored in a configuration file on another location within the environment.

If the module requires upront configuration, please provide a page named *configure*, which will be displayed to the user to complete.

## Syntax

```json
{
  "module": {
    "name": "module_admin",
    "label": "Dr. Frankenstein",
    "type": "bash",
    "configurable": "fasle"
  },
  "required": {
    "commands": [
      "docker"
    ]
  },
  "pages": []
}
```

| Name                | Description                                                                                                                       | Required |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------- |:--------:|
| module.name         | Unique name to identify module within the module registry                                                                         | x        |
| module.label        | Display name of module to user                                                                                                    | x        |
| module.type         | For now only bash scripts are supported                                                                                           | x        |
| module.configurable | If true, Igor will confirm if the user has completed the module configuration, otherwise he will request the user to complete it. | x        |
| required.commands   | List of executables that should be available on the command line for Igor to invoke the functionality provided by the page.       |          |
| pages               | To be discussed in more detal in the Page chapter                                                                                 | x        |

### Import a module

#### From directory

#### From zip file

### Create new module

1. Create a workspace which will contain the modle, usually a directory within a git repository

2. Call Igor and ask to see the *Dr Frankenstein*, from there he will ask you a few questions, when selecting *Create Module*.
   
   1. Unique name to identify the module among the other supported modules
   
   2. Display name which is presented to the user
   
   3. Directory to use for the development of the module, 

3. Igor will update the registry with the where abouts of the new module, allowing you the developer to work within the git repository.

4. Upon each excecution of Igor in development mode, will it copy the contents of the module workspace director into it's modules directory.

### Delete module

Call Igor and ask to see *Dr Frankenstein*, from there he will ask you which module, when selecting *Remove Module*.

### Export module

Call Igor and ask to see *Dr Frankenstein*, from there he will ask you which module, when selecting *Export Module*. The module will be exported a zip file which can be imported by Igor running on another environment.

# Page

From the **user** perspective a page is a set of prompts, when answered, wil execute a specific function with the correct parameters.  For example the user will be prompted to select which version of the database to restore, where the user can select between latest or some older versions.  Once the user selects, the restore of the local database is performed

From **developer** perspective a page is a list of prompts which can lead to other pages or the execution of an action, such as the restore of a local database.

## Syntax

```json
  "pages": [
    {
      "name": "main",
      "label": "Workbench",
      "command": "workbench_action"
      "prompts": []
    },
    ...
  ]
```

| Name         | Description                                                                                                          | Required |
| ------------ | -------------------------------------------------------------------------------------------------------------------- |:--------:|
| page.name    | Unique name to identify a page from all the pages found within the module                                            | x        |
| page.label   | Display name of the page which will be presented to the user                                                         | x        |
| page.command | Command to execute after all prompts have been responsded too, too be discussed in more detal in the Command chapter |          |
| page.prompts | To be discussed in more detal in the Prompt chapter                                                                  | x        |

# Prompt

From the **user** perspective a prompt is asking the user to provide some input, for example which backup version of the database to restore.

From **developer** perspective a prompt is either, single or multi select or text based CLI prompt to the user which response is used as input parameters to a script to execute.

## Response

The response of the user to a prompt is stored within a map and is identified by the key *\${value:page.unique_page_name.prompt.unique_prompt_name\}*, and can be:

- referenced as arguments for a command

- used as decisions to display a prompt to a user or not

- added to labels and/or prompts to display a more descriptive label and/or question

```json
    "label": "You selected to ${value:page.main.prompt.action} to do are you sure",
    "condition": "${value:page.main.prompt.action} == 'shutdown'",
    "command": "backup_database ${value:page.database.prompt.database_name}"
```

Depending on the scope, a shorthand key may be used.  Within a page you may skip the page identification part and it will assume the prompt value you are seaching for is within te same page, for example *\${prompt.unique_prompt_name\}*.

## Condition

Allows prompts to be visible to the user based on a condition, for example should Igor be executing within a local environment the the backing up of databases is disabled.

Making use of **eval** simple if statements are supported with combition of prompt responses and/or commands. **Commands** need to return 0 for success and 1 for failure.

```json
    "condition": "${command:is_valid_git_dir}"
    "condition": "${value:page.main.prompt.action} == 'install'"
    "condition": "${value:page.main.prompt.size} > 100"
```

## Validate

Enables custom validation to be executed on the input provided by a user to a specified prompt.

## Format

### Selection

Selection based prompt provides the user with a list of options to choose from.  The result could either be single selection or a comma seperated list of multiple selections.

#### Syntax

```json
      "prompts": [
        {
          "label": "Select action to take",
          "name": "user_action",
          "command": "execute_action ${value:prompt.user_action}"
          "options": []
        }
      ] 
```

| Name           | Description                                                                                                                                                     |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| prompt.name    | Unique name which identifies the prompt from all the prompts within the page                                                                                    |
| prompt.label   | Display name of the prompt which will be presented to the user                                                                                                  |
| prompt.command | The commad to execute after the user has responded to the prompt.  If page has defined a command, it will not be executed, as the prompt command takes priority |
| prompt.options | List of all the selectable options, to be discussed in more detal in the Format chapter                                                                         |

### Text

Most basic of prompts,  a simple string input expected from the user.

### Number

Second most prompt, validates that the user enters a numerc value.

### File

Text based prompt, which validates that the file path provided does exist, on failure it will ask the user to enter the path to a valid file.

### Directory

Text based prompt, which validates that the directoy path provided does exist, on failure it will ask the user to enter the path to a valid directory.

### Yes No

A prompt, which asks the user to respond with either yes or no, allowing for defaulting to either yes or no, if the user selects *Enter*.

### Continue

Similar to the yes no prompt, with the exception that when the user responds with no, Igor cancels the request and returns to th CLI.

# Command

Commands only exists from a **developer** perspective.  Command is a function found within a bash script which can be invoked by Igor to perform an action. For example the command *backup_database*, is defined within a bash script named *backup_database.sh*, which provides the means for backing up a database with some required input parameters.

**backup_database.sh**

```bash
function backup_database() {
    local database_name="$1"
    local backup_filename="$2"


    mysqldump -u root -p password "$database_name" > "$backup_filename"
}
```

In essence for each command made available to Igor function name should match the filename.  

Commands are executed within a brand new bash environment, as shown below.

```bash
env -i /bin/bash -c "/bin/bash ..."
```

# Reserved
