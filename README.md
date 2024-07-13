# Igor

## Goal

Easy to use CLI tool, which presents functionality to the user in the form of a menu and prompts, which requests input from the user for a script to execute, using only bash, mostly.

## About

The origin of __Igor__ came from repeating the same generic bash functions on different projects.  Each of these scrpts, included a list of prompts in order to build up the input parameters required for the function to execute.  The creating of the prompts and validating the input took more time build than creatin the core functionality, especially when the script is shared among fellow developers.  

Hence the birth of __Igor__.  A means to provide a bash prompt based framework which uses a JSON file to construct the prompts and allow you to only focus on the underlying function.

Why the name Igor, well Igor was the loyal assistent of Dr. Frankenstein and the view is that Igor will assist you too.

# Get Started

Download and execute the installation script as shown in [Install](#Install) and start Igor.

```
Usage: igor
```

# Usage

```
Usage: igor [options]

Options:
  --admin                          Enables administrative mode
  --command <module:command>    Invokes a command of from a specified module directly
  --decrypt <text>               Decrypts the specified text
  --develop                     Enables development mode
  --encrypt <text>               Encrypts the specified text
  --help                        Show this help message and exit
  --update                      Performs a version check and updates if a later version is available
  --verbose                     Enable verbose mode

Examples:
  igor -encrypt MySecr3tPassw0rd
  igor --command module_admin:create_module 'my_new_module' 'New Module' ~/workspace/igor-modules/my_new_module
```

## Install

Download the script [install.sh](https://raw.githubusercontent.com/willard-pro/igor/main/install.sh) and execute.

```
curl -o install-igor.sh https://raw.githubusercontent.com/willard-pro/igor/main/install.sh && chmod +x install-igor.sh && ./install-igor.sh
```

### Individual Configuration

Use this approach when you are installing Igor as for private use such as on your own personal laptop and/or standalone server.

### Team Configuration

Coming soon...

## Administrative Mode

```
Usage: igor --admin
```

In administrative mode, the user is presented with a menu which allows the user to:

- add

- create 

- remove

a module to/from Igor workbench.

## Command Execution

```
Usage: igor --command module_admin:create_module 'my_new_module' 'New Module' ~/workspace/igor-modules/my_new_module
```

The following usage informs Igor to execute the command create_module found within module_admin inclusive of the arguments required.

This usage pattern is only applied when executed from a non-interactive shell, such as crontab.  Lastly it can also be seen as a shortcut, should the user be repeating the same selection over and over, this can save some time.

## Development Mode

```
Usage: igor --develop
```

If development mode is enabled, Igor executes from within the calling directory and not the installed directory *~/.igor*. This enables the developer to execute Igor from within the git source directory.

## Update Igor

```
Usage: igor --update
```

Connects to GitHub to see if a later version is available, should that be the case, then Igor will request permission to download and install latest and continue upon permission granted.

## Verbose Logging

```
Usage: igor --verbose
```

When enables prints additional log statements (DEBUG and/or INFO) to the console, which can be used to troubleshoot modules.

# Configuration

## Environment

Before you can make use of Igor, it's environment has to be configured.  Supported environments are:

- Local (used by most users)

- UAT

- Demo

- Production

A module can be configured to behave differently based on the environment it is operating within, or even change the visibility of available functionality.

# Modules

## Create Module

To add custom module, run Igor in administrative mode and navigate to *Create Module* and follow the prompts.  Have the following information ready:

- A descriptive name of module the to display to the user

- Unique name to identify the module from the list of modules.  It will be used as the name of the directory which will contain the module content.

- The absolute path of the working directory which will be used to develop the new module, usually a git workspace.

Igor will create a file named *config.json* in the provided workspace and register the module within Igor's environment as experimental.  Each time Igor is invoked, it will detect the module is experimental and will sync with the provide workspace.

For more detail on the structure and syntax used within *config.json*, see chapter ???

## Install Module

To add an available module, run Igor in administrative mode and navigate to *Install Module* and follow the prompts.  Have the following information ready:

- Absolute path to one of the following
  
  - directory contaning the module contents
  
  - directory housng one or more modules
  
  - zip file containting one ore more modules

Igor will validate the module and if valid, register the module within Igor's environment.

## Remove Module

Removal of a module is achieved, by running Igor in administrative mode and navigate to *Remove Module* and follow the prompts.

# Advanced

## Igor Domain Language

 Below is an example of the syntax and keywords used to construct a module with it's available functionalty.

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

### Module

From the **user** perspective a module is a set of related functions, for example functions related to a developer managing a database,  restoring of the local database with data from either mock source or a backup...

From a **developer** perspective a module is a contained unit of scripts which is provides a user one or more pages, each with one or more prompts, leading to different outcomes.

A module may require additional configuration per environment, such as the name of a docker container in order to mange it. These kind of configurations could be stored in a configuration file on another location within the environment.

If the module requires upront configuration, please provide a page named *configure*, which will be displayed to the user to complete.

```json
{
  "module": {
    "name": "module_admin",
    "label": "Dr. Frankenstein",
    "type": "bash",
    "configurable": "fasle"
  }
}
```

| Name         | Description                                                                                                                         | Required |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------- |:--------:|
| name         | Unique name to identify module within the module registry                                                                           | x        |
| label        | Display name of module to user                                                                                                      | x        |
| type         | For now only bash scripts are supported                                                                                             | x        |
| configurable | If true, Igor will confirm if the user has completed the module configuration, otherwise Igor will request the user to complete it. | x        |

### Required Commands

Igor needs to know of all the commands, inclusive of binaries and scripts, which will be executed by the module, in order to check that the required commands is available on the CLI path.  This is to ensure that the module has access to all it's underlying exectable resources.

```json
{
  "required": {
    "commands": [
      "docker",
      "sed",
      "grep"
    ]
  }
}
```

| Name     | Description                                                                                                                   | Required |
| -------- | ----------------------------------------------------------------------------------------------------------------------------- |:--------:|
| commands | List of executables that should be available on the command line for Igor to invoke the functionality provided by the module. |          |

### Page

From the **user** perspective a page is a set of prompts, when answered, wil execute a specific function with the  arguments derived from the answers provided.  For example the user will be prompted to select which version of the database to restore, where the user can select between latest or some older versions.  Once the user selects, the restore of the local database is performed

From **developer** perspective a page is a list of prompts which can lead to other pages or the execution of an action, such as the restore of a local database.

```json
{  
  "pages": [
    {
      "name": "first",
      "label": "Workbench",
      "command": "workbench_action",
      "prompts": []
    }
  ]
}
```

| Name    | Description                                                                                                          | Required |
| ------- | -------------------------------------------------------------------------------------------------------------------- |:--------:|
| name    | Unique name to identify a page from all the pages found within the module                                            | x        |
| label   | Display name of the page which will be presented to the user                                                         | x        |
| command | Command to execute after all prompts have been responsded too, too be discussed in more detal in the Command chapter |          |
| prompts | To be discussed in more detal in the Prompt chapter                                                                  | x        |

### Prompt

From the **user** perspective a prompt is asking the user to provide some input, for example which backup version of the database to restore.

From **developer** perspective a prompt is either, single or multi select or text based CLI prompt to the user which response is used as input parameters to a script to execute.

```json
{
  "prompts": [
    {
      "label": "Enter your married name",
      "name": "married_name",
      "command": "save_user ${value:prompt.married_name}",
      "format": "text",
      "condition": "${value:page.main.prompt.married} == 'y'",
      "validate": {
        "command": "validate_married ${value:prompt.married_name}",
        "message": "You are not married, your surname do not exist in our database"
      },
      "options": []
    }
  ] 
}
```

| Name      | Description                                                                                                                                                     | Required |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |:--------:|
| name      | Unique name which identifies the prompt from all the prompts within the page                                                                                    | x        |
| label     | Text to display to user                                                                                                                                         | x        |
| command   | The commad to execute after the user has responded to the prompt.  If page has defined a command, it will not be executed, as the prompt command takes priority |          |
| condition | A statement that needs to be true in order for the prompt to be presented to the user                                                                           |          |
| validate  | Custom validation to perform on the input provided, with descriptive message, should the input be invalid                                                       |          |
| format    | What type of prompt, numeric, date, etc.., more details in the Format Chapter                                                                                   | x        |
| options   | List of all the selectable options, to be discussed in more detal in the Format chapter                                                                         |          |

#### Prompt Response

The response of the user to a prompt is stored within a map and is identified by the key *${value:page.unique_page_name.prompt.unique_prompt_name}*, and can be:

- referenced as arguments for a command

- used as decisions to display a prompt to a user or not

- added to labels and/or prompts to display a more descriptive label and/or question

```json
{
  "label": "You selected to ${value:page.main.prompt.action} to do are you sure",
  "condition": "${value:page.main.prompt.action} == 'shutdown'",
  "command": "backup_database ${value:page.database.prompt.database_name}"
}
```

Depending on the scope, a shorthand key may be used. Within a page you may skip the page identification part and it will assume the prompt value you are seaching for is within te same page, for example *${value:prompt.unique_prompt_name}*.

#### Condition

Allows prompts to be visible to the user based on a condition, for example should Igor be executing within a local environment the the backing up of databases is disabled.

Making use of **eval** simple if statements are supported with combition of prompt responses and/or commands. 

**NOTE:**   **Commands** need to return 0 for success and 1 for failure.

```json
    "condition": "${command:is_valid_git_dir}"
    "condition": "${value:page.main.prompt.action} == 'install'"
    "condition": "${value:page.main.prompt.size} > 100"
```

#### Validate

Enables custom validation to be executed on the input provided by a user to a specified prompt.

```json
          "validate": {
              "command": "backup_exists ${value:page.main.prompt.database_selected} 'latest'",
              "message": "Unable to reach backup source and/or there is no backup marked latest"
            }          
```

#### Format

##### Dropdown

Selection based prompt provides the user with a list of options to choose from.  The result could either be single selection or a comma seperated list of multiple selections.

##### Text

Most basic of prompts,  a simple string input expected from the user.

##### Number

Second most prompt, validates that the user enters a numerc value.

##### File

Text based prompt, whichSyntax
      "prompts": [
        {
          "label": "Select action to take",
          "name": "user_action",
          "command": "execute_action ${value:prompt.user_action}"
          "options": []
        }
      ]  validates that the file path provided does exist, on failure it will ask the user to enter the path to a valid file.

##### Directory

Text based prompt, which validates that the directoy path provided does exist, on failure it will ask the user to enter the path to a valid directory.

##### Yes No

A prompt, which asks the user to respond with either yes or no, allowing for defaulting to either yes or no, if the user selects *Enter*.

##### Continue

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

# Core

Consits of code which drives the Igor engine, in summary the bash scripts responsible for generating the prompts and execute the scripts fo different modules.

# Reserved
