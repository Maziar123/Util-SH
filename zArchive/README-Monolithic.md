# Util-Sh: Comprehensive Shell Utility Libraries

A collection of powerful bash utility libraries to enhance your shell scripts and make command-line parameter handling simple and robust.

## Table of Contents

- [Overview](#overview)
- [Libraries](#libraries)
  - [sh-globals.sh](#sh-globalssh)
  - [param_handler.sh](#param_handlersh)
- [Installation](#installation)
- [sh-globals.sh Library](#sh-globalssh-library)
  - [Overview](#sh-globals-overview)
  - [Key Features](#sh-globals-key-features)
  - [Installation](#sh-globals-installation)
  - [Initialization](#initialization)
  - [Function Reference](#function-reference)
    - [Color and Formatting](#1-color-and-formatting)
    - [Message Functions](#2-message-functions)
    - [Logging System](#3-robust-logging-system)
    - [String Operations](#4-advanced-string-operations)
    - [Array Functions](#array-functions)
    - [File & Directory Functions](#file--directory-functions)
    - [User Interaction Functions](#user-interaction-functions)
    - [System & Environment Functions](#system--environment-functions)
    - [OS Detection Functions](#os-detection-functions)
    - [Date & Time Functions](#date--time-functions)
    - [Networking Functions](#networking-functions)
    - [Script Lock Functions](#script-lock-functions)
    - [Error Handling Functions](#error-handling-functions)
    - [Dependency Management](#dependency-management)
    - [Number Formatting Functions](#number-formatting-functions)
- [param_handler.sh Library](#param_handlersh-library)
  - [Overview](#paramhandler-overview)
  - [Dependencies](#dependencies)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#paramhandler-installation)
  - [Quick Start](#quick-start)
  - [PARAMS Array Format](#params-array-format)
  - [Usage Examples](#usage-examples)
- [License](#license)

## Overview

Util-Sh provides a collection of comprehensive shell utility libraries designed to simplify bash scripting. The libraries offer consistent error handling, standardized output formatting, and robust parameter handling with minimal code and setup.

## Libraries

### sh-globals.sh

A powerful utility library providing consistent terminal output, error handling, string manipulation, file operations, and many other everyday shell script tasks.

### param_handler.sh

A lightweight, easy-to-use command-line parameter handling library that simplifies argument parsing and validation.

## Installation

Download the libraries to your project directory:

```bash
# Download sh-globals.sh
curl -O https://raw.githubusercontent.com/yourusername/Util-Sh/main/sh-globals.sh
chmod +x sh-globals.sh

# Download param_handler.sh and its dependency
curl -O https://raw.githubusercontent.com/yourusername/Util-Sh/main/param_handler.sh
curl -O https://raw.githubusercontent.com/yourusername/Util-Sh/main/getoptions.sh
chmod +x param_handler.sh
```

## sh-globals.sh Library

<a name="sh-globals-overview"></a>
### Overview

`sh-globals.sh` is a reusable library designed to simplify shell scripting by providing a wide range of carefully crafted functions, consistent error handling, and standardized output formatting. It enhances shell scripts with functionality including:

- **Terminal Output Enhancement**: Rich color and formatting options for better user experience.
- **Robust Logging System**: Multi-level logging with file and console output.
- **Advanced String Operations**: Comprehensive string manipulation functions.
- **File System Tools**: Safe file operations with validation and error handling.
- **Error Management**: Error trapping, cleanup, and stack traces.
- **User Interaction Helpers**: User prompts, confirmations, and secure input.
- **System Information**: OS detection, environment management, and user/host information.
- **Path Manipulation**: Advanced path operations and source file management.
- **Temporary Resource Management**: Auto-cleanup of temporary files and directories.
- **Process Control**: Script locking to prevent concurrent execution.
- **Human-Readable Formatting**: Number and date formatting for better readability.
- **Dependency Management**: Checks for required command-line tools.

<a name="sh-globals-installation"></a>
### Installation

1. Download the `sh-globals.sh` file to your project directory.
2. Make the script executable:
   ```bash
   chmod +x sh-globals.sh
   ```
3. Source it at the beginning of your scripts:
   ```bash
   #!/usr/bin/env bash

   # Source the library
   source "$(dirname "$0")/sh-globals.sh"

   # Initialize with your script's arguments (IMPORTANT)
   sh-globals_init "$@"

   # Now you can use all the library functions
   msg_info "Script initialized."
   ```

### Initialization

| Function                      | Description                   |
| :---------------------------- | :---------------------------- |
| `sh-globals_init [args...]` | Initialize the shell globals. |

It is **crucial** to call `sh-globals_init "$@"` at the beginning of your script after sourcing the library. This function performs several essential setup tasks:

- Sets up trap handlers for errors (`ERR`) and script exit (`EXIT`, `HUP`, `INT`, `QUIT`, `TERM`).
- Enables `pipefail` so that pipelines return a failure status if any command fails.
- Initializes common flag variables like `DEBUG`, `VERBOSE`, `QUIET`, `FORCE`.
- Parses common command-line flags (`--debug`, `--verbose`, `--quiet`, `--force`, `--help`, `--version`) from the script's arguments (`"$@"`).
- Sets up the mechanism for automatic cleanup of temporary files and directories created via `create_temp_file` and `create_temp_dir`.
- Ensures the script lock (if created using `create_lock`) is released on exit.

Example:

```bash
# Source the utilities and initialize
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"

echo "Shell utilities initialized"

# Now other functions can be used
log_info "Script starting"

# Check flags parsed by sh-globals_init
if [[ "$DEBUG" -eq 1 ]]; then
  msg_debug "Debug mode is ON"
fi
if [[ "$VERBOSE" -eq 1 ]]; then
  msg_info "Verbose mode is ON"
fi
```

### Function Reference

#### 1. Color and Formatting

Provides constants for adding colors and formatting to terminal output.

| Variable                                                               | Description         |
| :--------------------------------------------------------------------- | :------------------ |
| `BLACK`, `RED`, `GREEN`, `YELLOW`, `BLUE`, `MAGENTA`, `CYAN`, `WHITE`, `GRAY` | Text colors         |
| `BG_BLACK`, `BG_RED`, `BG_GREEN`, `BG_YELLOW`, `BG_BLUE`, `BG_MAGENTA`, `BG_CYAN`, `BG_WHITE` | Background colors |
| `BOLD`, `DIM`, `UNDERLINE`, `BLINK`, `REVERSE`, `HIDDEN`                   | Text formatting     |
| `NC`                                                                   | Reset color/format |

Example:

```bash
# Example of using colors
echo -e "${RED}Error:${NC} Something went wrong"
echo -e "${GREEN}Success:${NC} Operation completed"
echo -e "${BOLD}${BLUE}Important:${NC} Read this carefully"
echo -e "${YELLOW}Warning:${BOLD} Important note${NC}"
echo -e "${BG_BLUE}${WHITE}Highlighted information${NC}"
```

#### 2. Message Functions

Modern formatted message functions for clear, consistent terminal output.

| Function                                  | Description                                | Parameters                       | Returns |
| :---------------------------------------- | :----------------------------------------- | :------------------------------- | :------ |
| `msg [message...]`                        | Display a plain message                    | `message...`                     | None    |
| `msg_info [message...]`                   | Display an informational message (blue)    | `message...`                     | None    |
| `msg_success [message...]`                | Display a success message (green)          | `message...`                     | None    |
| `msg_warning [message...]`                | Display a warning message (yellow) to stderr | `message...`                     | None    |
| `msg_error [message...]`                  | Display an error message (red) to stderr   | `message...`                     | None    |
| `msg_highlight [message...]`              | Display a highlighted message (cyan)       | `message...`                     | None    |
| `msg_header [message...]`                 | Display a header message (bold, magenta)   | `message...`                     | None    |
| `msg_section [text] [width=80] [char=]` | Display a section divider with text        | `[text]` `[width]` `[char]`      | None    |
| `msg_subtle [message...]`                 | Display a subtle/dim message (gray)        | `message...`                     | None    |
| `msg_color [message] [color]`             | Display a message with custom color        | `message` `color`                | None    |
| `msg_step [step] [total] [description]`   | Display a step or progress message         | `step` `total` `description` | None    |
| `msg_debug [message...]`                  | Display debug message (cyan, if DEBUG=1)   | `message...`                     | None    |

Example:

```bash
# Basic messages
msg "Standard message"
msg_info "Informational message"
msg_success "Success message"
msg_warning "Warning message"
msg_error "Error message"
msg_highlight "Highlighted message"
msg_header "SECTION HEADER"
msg_subtle "This is less important."

# Section dividers
msg_section "Configuration" 60 "-" # Centered text with dashes
msg_section "" 80 "*"          # Just a line of asterisks

# Custom color
msg_color "This is a custom colored message" "$MAGENTA"

# Progress steps
msg_step 1 5 "Downloading resources"
msg_step 2 5 "Extracting files"

# Debug message (displays only when DEBUG=1)
DEBUG=1
msg_debug "Debug information here"
```

#### 3. Robust Logging System

Multi-level logging with optional timestamping and file output.

| Function                                     | Description                                               | Parameters                              | Returns |
| :------------------------------------------- | :-------------------------------------------------------- | :-------------------------------------- | :------ |
| `log_init [log_file] [save_to_file=1]`       | Initialize logging system (optional file path & toggle) | `[file_path]` `[save_to_file=1]`        | None    |
| `log_info [message...]`                      | Log informational message                                 | `message...`                            | None    |
| `log_warn [message...]`                      | Log warning message                                       | `message...`                            | None    |
| `log_error [message...]`                     | Log error message                                         | `message...`                            | None    |
| `log_debug [message...]`                     | Log debug message (only if DEBUG=1)                       | `message...`                            | None    |
| `log_success [message...]`                   | Log success message                                       | `message...`                            | None    |
| `log_with_timestamp [level] [message...]`    | Log with custom level and timestamp                       | `level` `message...`                    | None    |

Example:

```bash
# Initialize logging (optionally to file)
log_init "/var/log/myscript.log"  # Log to specified file and console
# log_init  # Log to ./script_name.log and console
# log_init "" 0 # Log only to console

# Set debug mode (optional)
DEBUG=1

# Log messages at different levels
log_info "Operation started"
log_warn "Resource usage high"
log_error "Failed to connect to server"
log_debug "Variable state: value=example" # Only logged if DEBUG=1
log_success "Backup completed successfully"

# Custom timestamp logging
log_with_timestamp "CUSTOM" "Special event occurred"
```

#### 4. Advanced String Operations

Functions for string manipulation and testing.

| Function                                  | Description                        | Parameters                | Returns             |
| :---------------------------------------- | :--------------------------------- | :------------------------ | :------------------ |
| `str_contains [string] [substring]`       | Check if string contains substring | `string` `substring`      | Boolean (exit code) |
| `str_starts_with [string] [prefix]`       | Check if string starts with prefix | `string` `prefix`         | Boolean (exit code) |
| `str_ends_with [string] [suffix]`         | Check if string ends with suffix   | `string` `suffix`         | Boolean (exit code) |
| `str_trim [string]`                       | Trim whitespace from string ends   | `string`                  | Trimmed string      |
| `str_to_upper [string]`                   | Convert string to uppercase        | `string`                  | Uppercase string    |
| `str_to_lower [string]`                   | Convert string to lowercase        | `string`                  | Lowercase string    |
| `str_length [string]`                     | Get string length                  | `string`                  | Length (integer)    |
| `str_replace [string] [search] [replace]` | Replace substring in string        | `string` `search` `replace` | Modified string     |

Example:

```bash
# String operations
name="  John Doe  "
filename="log-backup-2023.tar.gz.bak"

# String tests (return 0 for true, 1 for false)
if str_contains "$name" "John"; then
  echo "'$name' contains 'John'" # Prints
fi

if str_starts_with "$filename" "log-"; then
  echo "'$filename' starts with 'log-'" # Prints
fi

if str_ends_with "$filename" ".bak"; then
  echo "'$filename' ends with '.bak'" # Prints
fi

# String transformations
clean_name=$(str_trim "$name")
echo "Name: '$clean_name'" # Output: 'John Doe'

upper=$(str_to_upper "$name")
echo "Upper: $upper" # Output: '  JOHN DOE  '

lower=$(str_to_lower "$name")
echo "Lower: $lower" # Output: '  john doe  '

length=$(str_length "$name")
echo "Length: $length" # Output: 11

new_filename=$(str_replace "$filename" ".tar.gz" "")
echo "New filename: $new_filename" # Output: 'log-backup-2023.bak'
```

#### Array Functions

Functions for working with arrays.

| Function                                  | Description                        | Parameters                | Returns             |
| :---------------------------------------- | :--------------------------------- | :------------------------ | :------------------ |
| `array_contains [element] [array...]`       | Check if array contains element | `element` `array...`      | Boolean (exit code) |
| `array_join [delimiter] [array...]`       | Join array elements with delimiter | `delimiter` `array...`        | Joined string       |
| `array_length [array_name]`         | Get array length   | `array_name`         | Length (integer)    |

Example:

```bash
# Define an array
fruits=("apple" "banana" "orange" "grape")

# Check if array contains element
if array_contains "banana" "${fruits[@]}"; then
  echo "Array contains banana"  # This will print
fi

# Join array elements
joined=$(array_join ", " "${fruits[@]}")
echo "Joined: $joined"  # Output: apple, banana, orange, grape

# Get array length
length=$(array_length fruits)
echo "Array length: $length"  # Output: 4
```

#### File & Directory Functions

Functions for file and directory operations.

| Function                                  | Description                        | Parameters                | Returns             |
| :---------------------------------------- | :--------------------------------- | :------------------------ | :------------------ |
| `command_exists [command]`          | Check if a command exists         | `command`         | Boolean (exit code)  |
| `safe_mkdir [directory]`          | Create directory if it doesn't exist | `directory`        | Boolean (exit code)  |
| `file_exists [path]`             | Check if file exists and is readable | `path`           | Boolean (exit code)  |
| `dir_exists [path]`              | Check if directory exists            | `path`           | Boolean (exit code)  |
| `file_size [path]`               | Get file size in bytes               | `path`           | Size in bytes        |
| `safe_copy [src] [dst]`          | Copy file with verification          | `src` `dst`      | Boolean (exit code)  |
| `create_temp_file [template]`    | Create a temp file (auto-cleaned)    | `[template]`     | File path            |
| `create_temp_dir [template]`     | Create a temp directory (auto-cleaned) | `[template]`   | Directory path       |
| `wait_for_file [file] [timeout] [interval]` | Wait for a file to exist  | `file` `[timeout]` `[interval]` | Boolean |
| `get_file_extension [filename]`  | Get file extension                   | `filename`       | Extension            |
| `get_file_basename [filename]`   | Get filename without extension       | `filename`       | Basename             |

## param_handler.sh Library

<a name="paramhandler-overview"></a>
### Overview

ParamHandler is a lightweight Bash library for handling both named and positional command-line parameters in shell scripts. It simplifies argument parsing, parameter validation, and provides an easy-to-use interface for accessing parameter values.

### Dependencies

This library depends on [getoptions](https://github.com/ko1nksm/getoptions), a powerful command-line argument parser for shell scripts.

### Features

- Handle both named (`--option value`) and positional parameters in a single script
- Automatic parameter registration and management
- Built-in help message generation
- Color-coded output for better readability
- Simple API for quick implementation
- Parameter validation
- Multiple display formats
- Environment variable export

### Requirements

- Bash 4.0+ (for associative arrays)
- [getoptions.sh](../Util-Sh/getoptions.sh) (included in this project)

<a name="paramhandler-installation"></a>
### Installation

1. Download the required files:

```bash
# Download the library files
curl -O https://raw.githubusercontent.com/yourusername/param_handler/main/getoptions.sh
curl -O https://raw.githubusercontent.com/yourusername/param_handler/main/param_handler.sh
chmod +x param_handler.sh
```

2. Source the library in your script:

```bash
#!/usr/bin/bash
source path/to/param_handler.sh
```

### Quick Start

For a minimal example:

```bash
#!/usr/bin/bash
source param_handler.sh

# Define parameters in an indexed array
declare -a PARAMS=(
    # Basic format: internal_name:VARIABLE_NAME:Description
    "name:NAME:Person's name"
    "age:AGE:Person's age"
    # Extended format: internal_name:VARIABLE_NAME:option_name:Description
    "location:LOCATION:place:Person's location"
)

# Process all parameters in one step
if ! param_handler::simple_handle PARAMS "$@"; then
    exit 0  # Help was shown, exit successfully
fi

# Use the parameters
echo "Hello, $NAME! You are $AGE years old and from $LOCATION."
```

### PARAMS Array Format

The `PARAMS` array uses a specific format to define parameters:

#### Basic Format

```bash
declare -a PARAMS=(
    "internal_name:VARIABLE_NAME:Description"
)
```

#### Extended Format

```bash
declare -a PARAMS=(
    "internal_name:VARIABLE_NAME:option_name:Description[:REQUIRE][:getter_func]"
)
```

#### Format Components

1. **Core Components** (required):
   - `internal_name`: Used internally by the library (e.g., "user", "server")
   - `VARIABLE_NAME`: The actual variable name in your script (e.g., "USERNAME", "SERVER_ADDRESS")

2. **Optional Components**:
   - `option_name`: Custom name for the command-line option (default: internal_name)
   - `REQUIRE`: Mark the parameter as required
   - `getter_func`: Function name to validate or prompt for the parameter

3. **Description**: Help text displayed in the help message

### Usage Examples

#### Example 1: Basic Parameters

```bash
declare -a PARAMS=(
    "name:NAME:Person's name"
    "age:AGE:Person's age"
)
```

Usage:

```bash
./script.sh --name "John" --age "30"
# or
./script.sh "John" "30"
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 