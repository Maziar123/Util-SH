# Bash Utility Libraries

A collection of comprehensive shell utility libraries providing common functions and tools for bash scripts.


## Table of Contents

- [Bash Utility Libraries](#bash-utility-libraries)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Installation](#installation)
  - [Dependencies](#dependencies)
- [Library 1: sh-globals.sh](#library-1-sh-globalssh)
  - [Key Features](#key-features)
  - [Getting Started](#getting-started)
  - [Initialization](#initialization)
  - [Function Reference](#function-reference)
    - [1. Color and Formatting](#1-color-and-formatting)
    - [2. Message Functions](#2-message-functions)
    - [3. Robust Logging System](#3-robust-logging-system)
    - [4. Advanced String Operations](#4-advanced-string-operations)
    - [5. Array Functions](#5-array-functions)
    - [6. File \& Directory Management](#6-file--directory-management)
    - [7. User Interaction Functions](#7-user-interaction-functions)
    - [8. System and Environment Functions](#8-system-and-environment-functions)
    - [9. OS Detection Functions](#9-os-detection-functions)
    - [10. Date \& Time Functions](#10-date--time-functions)
    - [11. Networking Functions](#11-networking-functions)
    - [12. Script Lock Functions](#12-script-lock-functions)
    - [13. Error Handling Functions](#13-error-handling-functions)
    - [14. Dependency Management](#14-dependency-management)
    - [15. Number Formatting Functions](#15-number-formatting-functions)
    - [16. Path Navigation Functions](#16-path-navigation-functions)
  - [Advanced Usage Patterns](#advanced-usage-patterns)
    - [Complete Error Handling Example](#complete-error-handling-example)
    - [Temporary File Management Pattern](#temporary-file-management-pattern)
  - [Tips for Effective Use of sh-globals.sh](#tips-for-effective-use-of-sh-globalssh)
- [Library 2: param\_handler.sh](#library-2-param_handlersh)
  - [Key Features](#key-features-1)
  - [Quick Start](#quick-start)
  - [PARAMS Array Format](#params-array-format)
    - [Basic Format](#basic-format)
    - [Extended Format](#extended-format)
    - [Format Components](#format-components)
    - [Examples](#examples)
      - [1. Basic Example](#1-basic-example)
      - [2. Custom Option Names](#2-custom-option-names)
      - [3. Required Parameters](#3-required-parameters)
    - [Usage Examples](#usage-examples)
      - [Example 1: Basic Parameters](#example-1-basic-parameters)
      - [Example 2: Custom Option Names](#example-2-custom-option-names)
      - [Example 3: Mixed Parameters](#example-3-mixed-parameters)
  - [Parameter Validation](#parameter-validation)
  - [Accessing Parameter Values](#accessing-parameter-values)
    - [1. Direct Variable Access](#1-direct-variable-access)
    - [2. Check How Parameters Were Set](#2-check-how-parameters-were-set)
    - [3. Get Parameter Values Programmatically](#3-get-parameter-values-programmatically)
    - [4. Print All Parameters](#4-print-all-parameters)
  - [Core Functions Reference](#core-functions-reference)
    - [Simple API (Recommended)](#simple-api-recommended)
    - [Display Functions](#display-functions)
    - [Export Functions](#export-functions)
  - [Parameter Type Example](#parameter-type-example)
  - [Complete Example with Required Parameters and Validation](#complete-example-with-required-parameters-and-validation)
  - [Tips for Effective Use of param\_handler.sh](#tips-for-effective-use-of-param_handlersh)
- [Library 3: tmux\_utils1.sh](#library-3-tmux_utils1sh)
  - [Key Features](#key-features-2)
  - [Architecture Overview](#architecture-overview)
  - [TMUX Script Execution Methods](#tmux-script-execution-methods)
    - [1. Embedded Mode](#1-embedded-mode)
    - [2. Script Mode](#2-script-mode)
    - [3. Direct Function Mode (Recommended)](#3-direct-function-mode-recommended)
  - [Variable Sharing Between Scripts](#variable-sharing-between-scripts)
  - [Core Functions](#core-functions)
  - [Sample Files](#sample-files)
    - [TMUX Sample Files (`Samples/tmux-sample/`)](#tmux-sample-files-samplestmux-sample)
    - [Shell Utility Samples (`Samples/sh-sample/`)](#shell-utility-samples-samplessh-sample)
    - [Parameter Handling Samples (`Samples/param-sample/`)](#parameter-handling-samples-samplesparam-sample)
  - [Quick Start](#quick-start-1)
- [Combined Usage Example](#combined-usage-example)
  - [License](#license)

## Overview

This repository contains multiple utility libraries designed to simplify shell scripting:

1. **sh-globals.sh**: A comprehensive shell utility library with color definitions, string operations, file handling, error management, and more.
2. **param_handler.sh**: A lightweight Bash library for handling both named and positional command-line parameters in shell scripts.
3. **tmux_utils1.sh**: A utility library for managing tmux sessions from shell scripts, providing multiple approaches for executing scripts in tmux panes with variable sharing between the host script and tmux sessions.

These libraries aim to make shell scripting more robust, maintainable, and easier to implement.

## Installation

1. Download the required files:

```bash
# Clone the repository
git clone https://github.com/yourusername/Util-Sh.git
cd Util-Sh
```

2. Make the scripts executable:

```bash
chmod +x sh-globals.sh param_handler.sh tmux_utils1.sh
```

3. Source the libraries in your script:

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/sh-globals.sh"
source "$(dirname "$0")/param_handler.sh"
source "$(dirname "$0")/tmux_utils1.sh"

# Initialize libraries
sh-globals_init "$@"
```

## Dependencies

The `param_handler.sh` library depends on [getoptions](https://github.com/ko1nksm/getoptions), a powerful command-line argument parser for shell scripts.

- **Repository**: [ko1nksm/getoptions](https://github.com/ko1nksm/getoptions)
- **License**: [Creative Commons Zero v1.0 Universal](https://github.com/ko1nksm/getoptions/blob/master/LICENSE)
- **Version**: v3.3.2 (included in this project)

---

# Library 1: sh-globals.sh

`sh-globals.sh` is a comprehensive utility library that enhances your shell scripts with a wide range of functionality through carefully crafted functions, consistent error handling, and standardized output formatting.

## Key Features

- **Terminal Output Enhancement**: Rich color and formatting options for better user experience
- **Robust Logging System**: Multi-level logging with file and console output
- **Advanced String Operations**: Comprehensive string manipulation functions
- **File System Tools**: Safe file operations with validation and error handling
- **Error Management**: Error trapping, cleanup, and stack traces
- **User Interaction Helpers**: User prompts, confirmations, and secure input
- **System Information**: OS detection, environment management, and user/host information
- **Path Manipulation**: Advanced path operations and source file management
- **Temporary Resource Management**: Auto-cleanup of temporary files and directories
- **Process Control**: Script locking to prevent concurrent execution
- **Human-Readable Formatting**: Number and date formatting for better readability

## Getting Started

```bash
#!/usr/bin/env bash

# Source the library
source "$(dirname "$0")/sh-globals.sh"

# Initialize with your script's arguments (IMPORTANT)
sh-globals_init "$@"

# Now you can use all the library functions
msg_header "Welcome to My Script"
msg_info "Running as user: $(get_current_user)"
msg_info "Operating system: $(get_os)"

# Check for required dependencies
if ! check_dependencies curl jq; then
  msg_error "Missing required tools"
  exit 1
fi

# Create a lock to prevent multiple instances
if ! create_lock; then
  msg_error "Another instance is already running"
  exit 1
fi

# Script logic follows...
```

## Initialization

| Function                      | Description                   |
| :---------------------------- | :---------------------------- |
| `sh-globals_init [args...]` | Initialize the shell globals. |

It is **crucial** to call `sh-globals_init "$@"` at the beginning of your script after sourcing the library. This function performs several essential setup tasks:

-   Sets up trap handlers for errors (`ERR`) and script exit (`EXIT`, `HUP`, `INT`, `QUIT`, `TERM`).
-   Enables `pipefail` so that pipelines return a failure status if any command fails.
-   Initializes common flag variables like `DEBUG`, `VERBOSE`, `QUIET`, `FORCE`.
-   Parses common command-line flags (`--debug`, `--verbose`, `--quiet`, `--force`, `--help`, `--version`) from the script's arguments (`"$@"`).
-   Sets up the mechanism for automatic cleanup of temporary files and directories created via `create_temp_file` and `create_temp_dir`.
-   Ensures the script lock (if created using `create_lock`) is released on exit.

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

## Function Reference

### 1. Color and Formatting

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

# Output:
# Error: Something went wrong (in red)
# Success: Operation completed (in green)
# Important: Read this carefully (in bold blue)
# Warning: Important note (in yellow, note is bold)
# Highlighted information (white text on blue background)
```

### 2. Message Functions

Modern formatted message functions for clear, consistent terminal output. These functions handle colorization and standard prefixes automatically.

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

### 3. Robust Logging System

Multi-level logging with optional timestamping and file output. Useful for tracking script execution over time.

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

### 4. Advanced String Operations

| Function                                  | Description                        | Parameters                | Returns             |
| :---------------------------------------- | :--------------------------------- | :------------------------ | :------------------ |
| `str_contains [string] [substring]`       | Check if string contains substring | `string` `substring`      | Boolean (exit code) |
| `str_starts_with [string] [prefix]`       | Check if string starts with prefix | `string` `prefix`         | Boolean (exit code) |
| `str_ends_with [string] [suffix]`         | Check if string ends with suffix   | `string` `suffix`         | Boolean (exit code) |
| `str_trim [string]`                       | Trim whitespace from string ends   | `string`                  | Trimmed string      |
| `str_to_upper [string]`                   | Convert string to uppercase        | `string`                  | Uppercase string    |
| `str_to_lower [string]`                   | Convert string to lowercase        | `string`                  | Lowercase string    |
| `str_length [string]`                     | Get string length                  | `string`                  | Length (integer)    |
| `str_replace [string] [search] [replace]` | Replace substring in string      | `string` `search` `replace` | Modified string     |

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
trimmed=$(str_trim "$name")
echo "Trimmed: '$trimmed'" # Output: 'John Doe'

upper=$(str_to_upper "$name")
echo "Uppercase: '$upper'" # Output: '  JOHN DOE  '

lower=$(str_to_lower "$name")
echo "Lowercase: '$lower'" # Output: '  john doe  '

length=$(str_length "$trimmed")
echo "Length of trimmed: $length" # Output: 8

replaced=$(str_replace "$name" "John" "Jane")
echo "Replaced: '$replaced'" # Output: '  Jane Doe  '
```

### 5. Array Functions

| Function                                   | Description                       | Parameters             | Returns             |
| :----------------------------------------- | :-------------------------------- | :--------------------- | :------------------ |
| `array_contains [element] [array...]`      | Check if array contains element   | `element` `array...`   | Boolean (exit code) |
| `array_join [delimiter] [array...]`        | Join array elements with delimiter| `delimiter` `array...` | Joined string       |
| `array_length [array_name]`                | Get array length (pass name only) | `array_name`           | Length (integer)    |

Example:

```bash
# Define an array
fruits=("apple" "banana" "orange" "grape")

# Check if array contains element
if array_contains "banana" "${fruits[@]}"; then
  echo "Array contains banana" # Prints
fi

# Join array elements
joined=$(array_join ", " "${fruits[@]}")
echo "Joined: $joined" # Output: apple, banana, orange, grape

# Get array length (pass the array name as a string)
declare -a colors=("red" "green" "blue")
len=$(array_length colors)
echo "Colors array length: $len" # Output: 3
```

### 6. File & Directory Management

Includes functions for safe file operations, checks, and temporary resource management.

| Function                                         | Description                            | Parameters                      | Returns             |
| :----------------------------------------------- | :------------------------------------- | :------------------------------ | :------------------ |
| `command_exists [command]`                       | Check if command exists in PATH        | `command`                       | Boolean (exit code) |
| `safe_mkdir [directory]`                         | Create directory if it doesn't exist   | `directory`                     | None                |
| `file_exists [path]`                             | Check if file exists and is readable   | `path`                          | Boolean (exit code) |
| `dir_exists [path]`                              | Check if directory exists              | `path`                          | Boolean (exit code) |
| `file_size [path]`                               | Get file size in bytes                 | `path`                          | Size (bytes)        |
| `safe_copy [src] [dst]`                          | Copy file with verification            | `src` `dst`                     | Boolean (exit code) |
| `create_temp_file [template=tmp.XXXXXXXXXX]`     | Create a temp file (auto-cleaned)      | `[template]`                    | Temp file path      |
| `create_temp_dir [template=tmp.XXXXXXXXXX]`      | Create a temp directory (auto-cleaned) | `[template]`                    | Temp dir path       |
| `wait_for_file [file] [timeout=30] [interval=1]` | Wait for a file to exist               | `file` `[timeout]` `[interval]` | Boolean (exit code) |
| `get_file_extension [filename]`                  | Get file extension (without dot)       | `filename`                      | Extension string    |
| `get_file_basename [filename]`                   | Get filename without extension         | `filename`                      | Base filename       |
| `cleanup_temp`                                   | Manually clean up temp files/dirs      | None                            | None                |

Example:

```bash
# Check prerequisites
if ! command_exists "jq"; then
  msg_error "jq command not found. Please install jq."
  exit 1
fi

# Safe directory creation
safe_mkdir "/var/data/app/logs"

# Temporary file handling (auto-cleaned on exit)
temp_data=$(create_temp_file "data_proc_XXXX")
temp_dir=$(create_temp_dir "results_XXXX")
msg_info "Using temp file $temp_data and temp dir $temp_dir"
```

### 7. User Interaction Functions

Functions to prompt the user for input, confirmation, and validated values.

| Function                                                      | Description                              | Parameters                                       | Returns          |
| :------------------------------------------------------------ | :--------------------------------------- | :----------------------------------------------- | :--------------- |
| `confirm [prompt="Are you sure?"] [default=n]`                | Confirm prompt (y/n)                     | `[prompt]` `[default=y\|n]`                    | Boolean (exit code) |
| `confirm_enter_esc [prompt]`                                  | Simple Enter to confirm, Esc to cancel   | `[prompt]`                                     | Boolean (exit code) |
| `prompt_input [prompt] [default]`                             | Prompt for input with optional default   | `prompt` `[default]`                           | User input string |
| `prompt_password [prompt="Password:"]`                        | Prompt for password (hidden input)       | `[prompt]`                                     | Password string  |
| `get_number [prompt] [default] [min] [max]`                   | Get a validated numeric input            | `[prompt]` `[default]` `[min]` `[max]`         | Number           |
| `get_string [prompt] [default] [pattern] [error_msg]`         | Get string with optional regex validation| `[prompt]` `[default]` `[pattern]` `[error_msg]`| String           |
| `get_path [prompt] [default] [type] [must_exist=0]`           | Get file/directory path with validation  | `[prompt]` `[default]` `[type]` `[must_exist]`   | Path string      |
| `get_value [prompt] [default] [validator_func] [error_msg]` | Get value with custom validation function| `[prompt]` `[default]` `[validator]` `[error_msg]`| Validated value |

Example:

```bash
# Simple confirmation (returns 0 for yes, 1 for no)
if confirm "Delete all temporary files?" "n"; then
  msg_info "Deleting files..."
else
  msg_info "Deletion cancelled."
fi

# Simplified Enter/Escape confirmation
if confirm_enter_esc "Press Enter to continue, Esc to cancel:"; then
  msg_success "Continuing with operation..."
else
  msg_warning "Operation cancelled."
fi

# Input with default value
name=$(prompt_input "Enter your name" "guest")
msg_info "Hello, $name!"

# Validated numeric input
port=$(get_number "Enter server port" "8080" "1" "65535")
msg_info "Using port: $port"
```

### 8. System and Environment Functions

| Function                             | Description                          | Parameters   | Returns             |
| :----------------------------------- | :----------------------------------- | :----------- | :------------------ |
| `env_or_default [var_name] [default]`| Get environment variable or default  | `var_name` `[default]` | Value string        |
| `is_root`                            | Check if script is run as root       | None         | Boolean (exit code) |
| `require_root`                       | Exit script if not running as root   | None         | None (or exits)     |
| `parse_flags [args...]`              | Parse common flags (used by init)    | `args...`    | None (sets vars)    |
| `get_current_user`                   | Get current username                 | None         | Username string     |
| `get_hostname`                       | Get system hostname                  | None         | Hostname string     |

Example:

```bash
# Environment variables
api_key=$(env_or_default "API_KEY" "default-key")
log_level=$(env_or_default "LOG_LEVEL" "INFO")

# Privilege checks
if ! is_root; then
  msg_warning "This script ideally runs as root, but proceeding."
fi
```

### 9. OS Detection Functions

| Function           | Description                          | Parameters | Returns                     |
| :----------------- | :----------------------------------- | :--------- | :-------------------------- |
| `get_os`           | Get OS type (linux, mac, windows)    | None       | OS string                   |
| `get_linux_distro` | Get Linux distribution name (if OS=linux) | None       | Distro name string          |
| `get_arch`         | Get processor architecture           | None       | Arch string (amd64, arm64...) |
| `is_in_container`  | Check if running in a container      | None       | Boolean (exit code)         |

Example:

```bash
# Detect OS information
os_type=$(get_os)
arch=$(get_arch)
msg_info "OS Type: $os_type"
msg_info "Architecture: $arch"

if [[ "$os_type" == "linux" ]]; then
  distro=$(get_linux_distro)
  msg_info "Linux Distribution: $distro" # e.g., ubuntu, debian, centos
fi
```

### 10. Date & Time Functions

| Function                                     | Description                             | Parameters                      | Returns               |
| :------------------------------------------- | :-------------------------------------- | :------------------------------ | :-------------------- |
| `get_timestamp`                              | Get current timestamp (Unix epoch seconds)| None                            | Timestamp (integer)   |
| `format_date [format=%Y-%m-%d] [timestamp=now]` | Format date/time using `strftime`       | `[format]` `[timestamp]`        | Formatted date string |
| `time_diff_human [start] [end=now]`          | Human-readable time difference          | `start_ts` `[end_ts]`           | Formatted time string |

Example:

```bash
# Record start time
start_time=$(get_timestamp)
msg_info "Operation started at: $start_time"

# Format dates consistently
today=$(format_date "%Y-%m-%d") # Default format
log_ts=$(format_date "%Y%m%d_%H%M%S")
iso_ts=$(format_date "%Y-%m-%dT%H:%M:%SZ") # ISO 8601 format in UTC

# Do some work...
sleep 3

# Get elapsed time in human-readable format
end_time=$(get_timestamp)
elapsed=$(time_diff_human "$start_time" "$end_time") # e.g., "3s"
msg_info "Operation completed in $elapsed"
```

### 11. Networking Functions

| Function                                     | Description                      | Parameters                    | Returns             |
| :------------------------------------------- | :------------------------------- | :---------------------------- | :------------------ |
| `is_url_reachable [url] [timeout=5]`         | Check if URL is reachable (HEAD/GET) | `url` `[timeout]`             | Boolean (exit code) |
| `get_external_ip`                            | Get external/public IP address   | None                          | IP address string   |
| `is_port_open [host] [port] [timeout=2]`     | Check if TCP port is open on host| `host` `port` `[timeout]`     | Boolean (exit code) |

Example:

```bash
# Check connectivity
if is_url_reachable "https://api.example.com" 3; then
  msg_success "API endpoint is reachable."
else
  msg_error "Cannot reach API endpoint."
fi

# Get public IP
my_ip=$(get_external_ip)
if [[ -n "$my_ip" ]]; then
  msg_info "My external IP address: $my_ip"
fi
```

### 12. Script Lock Functions

Prevents multiple instances of the script from running simultaneously using a lock file.

| Function                     | Description                                         | Parameters    | Returns             |
| :--------------------------- | :-------------------------------------------------- | :------------ | :------------------ |
| `create_lock [lock_file]`    | Create lock file (fails if valid lock exists)       | `[lock_file]` | Boolean (exit code) |
| `release_lock`               | Release the lock file (usually done automatically) | None          | None                |

Example:

```bash
# Attempt to create the lock
if ! create_lock; then
  msg_error "Another instance is already running."
  exit 1
fi

msg_success "Lock acquired. Running exclusively."

# Lock will be released automatically on exit.
```

### 13. Error Handling Functions

| Function                                | Description                                  | Parameters                | Returns |
| :-------------------------------------- | :------------------------------------------- | :------------------------ | :------ |
| `print_stack_trace`                     | Print the current function call stack        | None                      | None    |
| `error_handler [exit_code] [line_number]` | Default ERR trap handler (logs, cleans up) | `exit_code` `line_number` | None    |
| `setup_traps`                           | Setup ERR and EXIT traps (used by init)    | None                      | None    |

### 14. Dependency Management

| Function                      | Description                       | Parameters   | Returns             |
| :---------------------------- | :-------------------------------- | :----------- | :------------------ |
| `check_dependencies [cmd...]` | Check if required commands exist | `commands...`| Boolean (exit code) |

Example:

```bash
# Check for essential tools at the start of the script
if ! check_dependencies git docker kubectl helm; then
  msg_error "Please install the missing tools and try again."
  exit 1
fi
```

### 15. Number Formatting Functions

| Function                                  | Description                                     | Parameters             | Returns          |
| :---------------------------------------- | :---------------------------------------------- | :--------------------- | :--------------- |
| `format_si_number [number] [precision=1]` | Format number with SI prefixes (K, M, G, T, P, m, μ, n) | `number` `[precision]` | Formatted string |
| `format_bytes [bytes] [precision=1]`      | Format bytes to human-readable size (KB, MB, GB, TB) | `bytes` `[precision]`  | Formatted string |

Example:

```bash
# Format numbers with SI prefixes
users=8543210
formatted_users=$(format_si_number "$users")      # "8.5M"

# Format bytes with appropriate units
file_size_bytes=2684354560
formatted_size=$(format_bytes "$file_size_bytes") # "2.5GB"
```

### 16. Path Navigation Functions

| Function                                     | Description                                | Parameters                    | Returns               |
| :------------------------------------------- | :----------------------------------------- | :---------------------------- | :-------------------- |
| `get_script_dir`                             | Get the directory containing the script    | None                          | Script directory path |
| `get_script_name`                            | Get the filename of the script             | None                          | Script filename       |
| `get_script_path`                            | Get the full path to the script            | None                          | Full script path      |
| `get_line_number`                            | Get the current line number in the script  | None                          | Current line number   |
| `get_parent_dir [path=pwd]`                  | Get parent directory of a path             | `[path]`                      | Parent directory path |
| `get_parent_dir_n [path=pwd] [levels=1]`     | Get parent directory N levels up           | `[path]` `[levels]`           | Path N levels up      |
| `path_relative_to_script [relative_path]`    | Make path absolute, relative to script dir | `relative_path`               | Absolute path         |
| `to_absolute_path [path] [base_dir=pwd]`     | Convert relative path to absolute          | `path` `[base_dir]`           | Absolute path         |
| `source_relative [relative_path]`            | Source file relative to calling script     | `relative_path`               | Boolean (exit code)   |
| `source_with_fallbacks [filename] [paths...]`| Source file with fallback locations        | `filename` `[fallback_paths...]` | Boolean (exit code)   |
| `parent_path [levels=1]`                     | Create path string like `../../`         | `[levels]`                    | Path string           |

Example:

```bash
# Get script location information
script_dir=$(get_script_dir)
script_name=$(get_script_name)
script_path=$(get_script_path)
log_info "Running script: $script_name in $script_dir"
```

## Advanced Usage Patterns

### Complete Error Handling Example

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"

# Initialize logging
log_init "/var/log/myapp.log"

# Function that may fail
perform_operation() {
  local path="$1"
  
  if [[ ! -d "$path" ]]; then
    # This will trigger the error handler due to set -e
    return 1
  fi
  
  # Successful operation
  return 0
}

# Main processing logic
main() {
  log_info "Script started"
  
  # Create a lock
  if ! create_lock; then
    log_error "Another instance is already running"
    exit 1
  fi
  
  # Perform operations
  if ! perform_operation "/nonexistent/path"; then
    log_error "Operation failed"
    # No need to exit, cleanup is handled automatically
    return 1
  fi
  
  log_success "Script completed successfully"
}

# Run main function
main
```

### Temporary File Management Pattern

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"

process_data() {
  # Create temporary resources
  local temp_dir=$(create_temp_dir)
  local temp_file1=$(create_temp_file)
  local temp_file2=$(create_temp_file)
  
  # Download data
  wget -q "https://example.com/data.csv" -O "$temp_file1"
  
  # Process data
  sort "$temp_file1" > "$temp_file2"
  cut -d, -f1,2 "$temp_file2" > "$temp_dir/result.csv"
  
  # Files will be automatically cleaned up on script exit
  echo "$temp_dir/result.csv"
}

# Main script
result_file=$(process_data)
msg_success "Data processed and saved to $result_file"
cat "$result_file"
```

## Tips for Effective Use of sh-globals.sh

1.  **Always Initialize**: Call `sh-globals_init "$@"` at the beginning of your script to set up traps and other features.
2.  **Prefer msg_* over echo**: Use `msg_info`, `msg_error`, etc. instead of direct echo commands for consistent, colorized output.
3.  **Use log_* for persistent logs**: When you need to track script execution over time, initialize logging with `log_init` and use the `log_*` functions.
4.  **Let error handling work for you**: The library sets up error trapping automatically. Let errors propagate naturally and rely on the cleanup functions.
5.  **Leverage temporary resource creation**: Use `create_temp_file` and `create_temp_dir` to get auto-cleaned temporary resources.
6.  **Build on validation functions**: Compose complex validation by combining the `get_*` input functions with custom validators.

# Library 2: param_handler.sh

The `param_handler.sh` library simplifies handling both named and positional command-line parameters in shell scripts.

## Key Features

- Handle both named (`--option value`) and positional parameters in a single script
- Automatic parameter registration and management
- Built-in help message generation
- Color-coded output for better readability
- Parameter value retrieval and state checking
- Multiple display formats
- JSON export capability
- Environment variable export with prefix support
- Required parameters with validation
- Parameter validation using custom functions

## Quick Start

```bash
#!/usr/bin/bash
source param_handler.sh

# Define parameters in an indexed array
# Format: "internal_name:VARIABLE_NAME[:option_name]:Description[:REQUIRE][:getter_func]"
declare -a PARAMS=(
    # Basic format: internal_name:VARIABLE_NAME:Description
    "name:NAME:Person's name"  # Creates $NAME and --name option
    
    # Basic format: internal_name:VARIABLE_NAME:Description
    "age:AGE:Person's age"     # Creates $AGE and --age option
    
    # Extended format: internal_name:VARIABLE_NAME:option_name:Description
    "location:LOCATION:place:Person's location"  # Creates $LOCATION and --place option
)

# Process all parameters in one step
if ! param_handler::simple_handle PARAMS "$@"; then
    exit 0  # Help was shown, exit successfully
fi

# Use the parameters
echo "Hello, $NAME! You are $AGE years old and from $LOCATION."
```

## PARAMS Array Format

The `PARAMS` array uses a specific format to define parameters:

### Basic Format

```bash
declare -a PARAMS=(
    "internal_name:VARIABLE_NAME:Description"
)
```

### Extended Format

```bash
declare -a PARAMS=(
    "internal_name:VARIABLE_NAME:option_name:Description[:REQUIRE][:getter_func]"
)
```

### Format Components

1. **Core Components** (required):
   - `internal_name`: Used internally by the library (e.g., "user", "server")
   - `VARIABLE_NAME`: The actual variable name in your script (e.g., "USERNAME", "SERVER_ADDRESS")

2. **Optional Components**:
   - `option_name`: Custom name for the command-line option (default: internal_name)
   - `REQUIRE`: Mark the parameter as required
   - `getter_func`: Function name to validate or prompt for the parameter

3. **Description**: Help text displayed in the help message

### Examples

#### 1. Basic Example

```bash
declare -a PARAMS=(
    "user:USERNAME:Username for login"
    "server:SERVER_ADDRESS:Server address"
)
```

- Creates variables: `$USERNAME`, `$SERVER_ADDRESS`
- Command-line options: `--user`, `--server`

#### 2. Custom Option Names

```bash
declare -a PARAMS=(
    "user:USERNAME:username:Username for login"
    "server:SERVER_ADDRESS:server-address:Server address"
)
```

- Creates variables: `$USERNAME`, `$SERVER_ADDRESS`
- Command-line options: `--username`, `--server-address`

#### 3. Required Parameters

```bash
declare -a PARAMS=(
    "user:USERNAME:username:Username for login:REQUIRE"
    "pass:PASSWORD:password:Password for authentication:REQUIRE"
    "server:SERVER_ADDRESS:server-address:Server address"
)
```

- Creates variables: `$USERNAME`, `$PASSWORD`, `$SERVER_ADDRESS`
- Command-line options: `--username`, `--password`, `--server-address`
- Required parameters: `--username`, `--password`

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

#### Example 2: Custom Option Names

```bash
declare -a PARAMS=(
    "user:USERNAME:username:Login username"
    "pass:PASSWORD:password:Login password"
)
```

Usage:

```bash
./script.sh --username "john" --password "secret"
# or
./script.sh "john" "secret"
```

#### Example 3: Mixed Parameters

```bash
declare -a PARAMS=(
    "db:DB_NAME:database:Database name"
    "host:DB_HOST:Database host"
    "port:DB_PORT:db-port:Database port"
)
```

Usage:

```bash
./script.sh --database "mydb" --host "localhost" --db-port "5432"
# or
./script.sh "mydb" "localhost" "5432"
# or mixed
./script.sh --database "mydb" "localhost" --db-port "5432"
```

## Parameter Validation

To use parameter validation:

1. Define validator functions that return 0 for valid input and non-zero for invalid input
2. Use these functions in the parameter definition
3. When validation fails, the user will be prompted to enter a valid value

Example validator functions:

```bash
# Validate age (must be a number between 1-120)
validate_age() {
    local value="$1"
    
    # Check if it's a number
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "Age must be a number" >&2
        return 1
    fi
    
    # Check range
    if (( value < 1 || value > 120 )); then
        echo "Age must be between 1 and 120" >&2
        return 1
    fi
    
    return 0
}

# Validate email format
validate_email() {
    local value="$1"
    
    # Simple email validation
    if ! [[ "$value" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid email format" >&2
        return 1
    fi
    
    return 0
}
```

Usage with validation:

```bash
declare -a PARAMS=(
    "name:NAME:Person's name"
    "age:AGE:age:Person's age (required, 1-120):REQUIRE:validate_age"
    "email:EMAIL:email-address:Email address (required):REQUIRE:validate_email"
)

if ! param_handler::simple_handle PARAMS "$@"; then
    exit 1  # Help was shown or required parameter validation failed
fi
```

## Accessing Parameter Values

After using `param_handler::simple_handle`, you can access your parameters in several ways:

### 1. Direct Variable Access

```bash
# Access variables directly
if [[ -n "$USERNAME" ]]; then
    echo "Username is set to: $USERNAME"
else
    echo "Username is not set"
fi
```

### 2. Check How Parameters Were Set

```bash
# Check if server was set by name (--server-address)
if param_handler::was_set_by_name "server"; then
    echo "Server was set via --server-address option"
fi

# Check if server was set by position
if param_handler::was_set_by_position "server"; then
    echo "Server was set as a positional parameter"
fi
```

### 3. Get Parameter Values Programmatically

```bash
# Get parameter value
server_address=$(param_handler::get_param "server")
echo "Server address: $server_address"
```

### 4. Print All Parameters

```bash
# Print all parameters with their values and sources
param_handler::print_params_extended
```

## Core Functions Reference

### Simple API (Recommended)

| Function | Description | Sample |
|----------|-------------|--------|
| `param_handler::simple_handle [params_array] [args...]` | Process parameters in one step | `param_handler::simple_handle PARAMS "$@"` |
| `param_handler::get_param [param_name]` | Get parameter value | `value=$(param_handler::get_param "name")` |
| `param_handler::was_set_by_name [param_name]` | Check if set by name | `if param_handler::was_set_by_name "server"; then echo "Set via --server-address option"; fi` |
| `param_handler::was_set_by_position [param_name]` | Check if set by position | `if param_handler::was_set_by_position "user"; then echo "Set positionally"; fi` |
| `param_handler::print_params` | Display parameter values | `param_handler::print_params # Show all param values` |
| `param_handler::print_help` | Display help message | `param_handler::print_help # Show help message` |
| `param_handler::export_params [--format type] [--prefix prefix]` | Export parameters | `param_handler::export_params --format json` |

### Display Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `param_handler::print_params` | Basic parameter values display | `param_handler::print_params` |
| `param_handler::print_params_extended` | Display with source information | `param_handler::print_params_extended` |
| `param_handler::print_summary` | Summary of parameter counts | `param_handler::print_summary` |
| `param_handler::print_help` | Help message | `param_handler::print_help` |

### Export Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `param_handler::export_params --prefix [prefix]` | Export to environment variables | `param_handler::export_params --prefix "APP_"` |
| `param_handler::export_params --format json` | Export as JSON | `param_handler::export_params --format json` |

## Parameter Type Example

The library uses colored output to indicate parameter sources:
- **Green**: Parameters set via named options (--option value)
- **Yellow**: Parameters set via positional arguments
- **Red**: Unset parameters

```bash
# Run with parameters by name
./script.sh --name "John" --age "30"

# Output
NAME: John (named)
AGE: 30 (named)
```

```bash
# Run with positional parameters
./script.sh "John" "30"

# Output
NAME: John (positional)
AGE: 30 (positional)
```

## Complete Example with Required Parameters and Validation

```bash
#!/usr/bin/bash
source "$(dirname "$0")/sh-globals.sh"
source "$(dirname "$0")/param_handler.sh"

# Initialize sh-globals
sh-globals_init "$@"

# Define validator functions
validate_age() {
    local value="$1"
    
    # Check if it's a number
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "Age must be a number" >&2
        return 1
    fi
    
    # Check range
    if (( value < 1 || value > 120 )); then
        echo "Age must be between 1 and 120" >&2
        return 1
    fi
    
    return 0
}

validate_email() {
    local value="$1"
    
    # Simple email validation
    if ! [[ "$value" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid email format" >&2
        return 1
    fi
    
    return 0
}

# Define parameters
declare -a PARAMS=(
    # Optional parameter (standard)
    "name:NAME:Person's name"
    
    # Required parameter with validator
    "age:AGE:age:Person's age (required, 1-120):REQUIRE:validate_age"
    
    # Required parameter with custom option name and validator
    "email:EMAIL:email-address:Email address (required):REQUIRE:validate_email"
    
    # Optional parameter with custom option name
    "location:LOCATION:place:Person's location"
)

# Process all parameters
# If validation fails for required parameters, the user will be prompted
if ! param_handler::simple_handle PARAMS "$@"; then
    exit 1  # Help was shown or required parameter validation failed
fi

# Display information
msg_header "Required Parameters Example"

msg_info "Parameter Values:"
echo "Name: ${NAME:-not set}"
echo "Age: ${AGE} (required)"
echo "Email: ${EMAIL} (required)"
echo "Location: ${LOCATION:-not set}"

msg_info "Parameter Sources:"
if param_handler::was_set_by_name "age"; then
    msg_success "Age was provided via --age option"
elif param_handler::was_set_by_position "age"; then
    msg_highlight "Age was provided as a positional parameter"
else
    msg_warning "Age was provided via prompt (required parameter)"
fi

# Display parameter details
param_handler::print_params_extended
```

## Tips for Effective Use of param_handler.sh

1. **Organized Definitions**: Keep your parameter definitions organized with clear descriptions
2. **Use Validation**: Add validation functions for critical parameters to ensure data integrity
3. **Use Required Flag**: Mark essential parameters as required using the `REQUIRE` keyword
4. **Descriptive Help**: Write clear descriptions that will be shown in the help message
5. **Check Parameter Sources**: Use the source checking functions when the source matters
6. **Export When Needed**: Use export capabilities when passing parameters to other scripts
7. **User-Friendly Names**: Use the custom option name feature to create user-friendly parameter names

---

# Library 3: tmux_utils1.sh

`tmux_utils1.sh` is a utility library for managing tmux sessions from shell scripts, providing multiple approaches for executing scripts in tmux panes with variable sharing between the host script and tmux sessions.

## Key Features

- Create and manage tmux sessions programmatically
- Execute scripts in tmux panes using multiple methods
- Share variables between parent script and tmux sessions
- Auto-cleanup of temporary resources
- Modular architecture with specialized utility files:
  - `tmux_base_utils.sh`: Core low-level tmux functions
  - `tmux_script_generator.sh`: Script generation and boilerplate
  - `tmux_utils1.sh`: Main high-level functionality

## Architecture Overview

The tmux utilities have been reorganized into a modular architecture:

1. **tmux_base_utils.sh**: Contains fundamental tmux helper functions like:
   - Environment variable management (`tmx_var_set`, `tmx_var_get`)
   - Pane ID/index management (`tmx_get_pane_id`, `tmx_kill_pane_by_id`)
   - Self-destruct capabilities for sessions

2. **tmux_script_generator.sh**: Provides script generation functionality:
   - Handles script boilerplate generation
   - Sets up proper environment for pane scripts
   - Ensures proper utility sourcing in generated scripts

3. **tmux_utils1.sh**: Main library that brings it all together:
   - High-level session management
   - Script execution methods
   - Pane creation and control
   - Session monitoring and display

## TMUX Script Execution Methods

There are three main ways to run scripts in tmux panes:

### 1. Embedded Mode

Inline scripts with heredoc syntax - simple and direct.

```bash
# Using heredoc for inline scripts
tmx_execute_script "${SESSION_NAME}" 0 "VARS_TO_EXPORT" <<'EOF'
msg_bg_blue "This is an inline script"
echo "Current directory: $(pwd)"
# Access shared variables
echo "Variable from parent: ${SHARED_VAR}"
EOF
```

**Benefits:**
- Simple for quick one-off scripts
- No need to define separate functions
- Great for short, self-contained tasks

### 2. Script Mode

Loading scripts from files or functions that generate script content.

```bash
# Function that generates script content
welcome_script() {
    cat <<EOF
msg_header "Welcome to \${SESSION_NAME}!"
echo "This script was generated by a function"
# Access shared variables
echo "Data file: \${DATA_FILE}"
EOF
}

# Execute the generated script
tmx_execute_function "${SESSION_NAME}" 0 welcome_script "SESSION_NAME DATA_FILE"

# Or from a file
tmx_execute_file "${SESSION_NAME}" 0 "/path/to/script.sh" "VARS_TO_EXPORT"
```

**Benefits:**
- Good for reusable script templates
- Can organize scripts in separate files

### 3. Direct Function Mode (Recommended)

For complex cases, execute real shell functions directly:

```bash
# Define a normal shell function
monitor_files() {
    local watch_dir="${WATCH_DIR:-$(pwd)}"
    msg_bg_cyan "Monitoring files in: $watch_dir"
    while true; do
        find "$watch_dir" -type f -mtime -1 | sort
        sleep 5
    done
}

# Execute it in a tmux pane
tmx_execute_shell_function "${SESSION_NAME}" 0 monitor_files "WATCH_DIR"
```

**Benefits:**
- Full IDE/syntax support for function development
- Easier debugging outside of tmux
- Better integration with modern development workflows

## Variable Sharing Between Scripts

A key feature is sharing variables between the host script and tmux sessions. The simplest approach uses files as demonstrated in the `tmux_micro_counter.sh` template:

```bash
# Create files to hold shared values
COUNT_FILE="/tmp/counter_$$.txt"
echo "0" > "${COUNT_FILE}"  # Initialize

# Monitor function in one pane
monitor() {
    while true; do
        echo "Current count: $(cat ${COUNT_FILE})"
        sleep 1
    done
}

# Counter function in another pane
counter() {
    while true; do
        v=$(($(cat ${COUNT_FILE}) + 1))
        echo ${v} > ${COUNT_FILE}  # Write for other panes to see
        sleep 2
    done
}

# Execute in different panes
tmx_execute_shell_function "${SESSION_NAME}" 0 monitor "COUNT_FILE"
tmx_execute_shell_function "${SESSION_NAME}" 1 counter "COUNT_FILE"
```

## Core Functions

| Function | Description |
|----------|-------------|
| `tmx_create_session [session_name]` | Create a new tmux session |
| `tmx_execute_script [session] [pane] [vars] <<EOF ...` | Execute script using heredoc |
| `tmx_execute_function [session] [pane] [func_name] [vars]` | Execute script from generator function |
| `tmx_execute_file [session] [pane] [file_path] [vars]` | Execute script from file |
| `tmx_execute_shell_function [session] [pane] [func_name] [vars]` | Execute shell function directly |
| `tmx_create_pane [session] [split_type="h"]` | Create a new pane (h=horizontal, v=vertical) |
| `tmx_kill_session [session]` | Kill a tmux session |
| `tmx_display_info [session]` | Display comprehensive session information |
| `tmx_create_pane_func [func_name] [session] [label]` | Create pane with smart layout and execute function |
| `tmx_var_set [var_name] [value] [session]` | Set a tmux environment variable |
| `tmx_var_get [var_name] [session]` | Get a tmux environment variable |

## Sample Files

The Util-Sh repository contains examples demonstrating the usage of various utilities:

### TMUX Sample Files (`Samples/tmux-sample/`)

These examples demonstrate different aspects of tmux session and pane management:

1. **`tmux_micro_counter.sh`**: Minimal example showing variable sharing between panes
   - Creates a session with three panes (monitor, green and blue counters)
   - Demonstrates simple inter-pane communication using tmux environment variables
   - Ideal starting point for understanding the basics

2. **`tmux_control_demo.sh`**: Comprehensive control pane demonstration
   - Creates a control pane that monitors variables and manages other panes
   - Implements three color-coded counter panes (green, blue, yellow)
   - Shows interactive control capabilities (closing panes, quitting session)
   - Uses stable pane IDs rather than indices for reliability
   - Demonstrates automatic layout management
   - Features comprehensive session display and monitoring
   - **Key Features**: Auto-registration of panes, control interface, monitoring

3. **`tmux_simple_manage.sh`**: Shows simplified management approach
   - Creates a basic monitoring interface
   - Focuses on clean organization and minimal code
   - Good for learning the core management concepts

4. **`tmux_status_example.sh`**: Demonstrates status display capabilities
   - Shows how to create informative status displays
   - Implements proper title management
   - Provides visual session feedback

### Shell Utility Samples (`Samples/sh-sample/`)

These examples demonstrate usage of the `sh-globals.sh` utility:

1. **`sh-globals_test_colors.sh`**: Demonstrates all color and formatting options
   - Shows all available message formatting functions
   - Visual demonstration of colors and styles
   - Useful reference for UI design

2. **`sh-globals_template.sh`**: Bare-bones template for new scripts
   - Minimal working example with proper initialization
   - Ready-to-use structure for new scripts
   - Includes standard error handling

### Parameter Handling Samples (`Samples/param-sample/`)

These examples demonstrate the parameter handling capabilities:

1. **`params_example.sh`**: Basic parameter handling demonstration
   - Shows simple named and positional parameters
   - Demonstrates automatic help generation
   - Includes parameter display functions

2. **`params_required_example.sh`**: Required parameter validation
   - Demonstrates parameter validation with custom validators
   - Shows required parameter enforcement
   - Implements interactive prompting for missing parameters

3. **`param_handler_formats.sh`**: Shows different output formats
   - Demonstrates exporting parameters in various formats
   - Shows JSON export capabilities
   - Illustrates environment variable exports

4. **`param_handler_usage.sh`**: Comprehensive usage examples
   - Complete reference for parameter handling features
   - Includes advanced usage patterns
   - Shows parameter state checking

5. **`param_handler_ordered_usage.sh`**: Ordered parameter handling
   - Demonstrates maintaining parameter order
   - Shows advanced parameter tracking
   - Implements comprehensive parameter testing

## Quick Start

Here's a minimal working example based on the `tmux_micro_counter.sh` template:

```bash
#!/usr/bin/env bash
# Source required utilities
source "$(dirname "$0")/sh-globals.sh"
source "$(dirname "$0")/tmux_base_utils.sh" # New dependency
source "$(dirname "$0")/tmux_script_generator.sh" # New dependency
source "$(dirname "$0")/tmux_utils1.sh"
sh-globals_init "$@"

# Create shared files for inter-pane communication
COUNT_GREEN="/tmp/counter_green_$$.txt"
COUNT_BLUE="/tmp/counter_blue_$$.txt"
echo "0" > "${COUNT_GREEN}"
echo "0" > "${COUNT_BLUE}"

# Monitor function to display both counters
monitor() {
    while true; do
        clear
        echo "=== MONITOR ==="
        echo "GREEN: $(cat ${COUNT_GREEN})"
        echo "BLUE: $(cat ${COUNT_BLUE})"
        sleep 1
    done
}

# Green counter function - increments by 2
green() {
    while true; do
        v=$(($(cat ${COUNT_GREEN}) + 2))
        echo ${v} > ${COUNT_GREEN}
        clear
        msg_bg_green "GREEN COUNTER (PANE 1)"
        msg_green "Value: ${v}"
        msg_green "Press '1' in control pane to close"
        sleep 1
    done
}

# Blue counter function - increments by 3 every 2 seconds
blue() {
    local session="$1"
    while true; do
        local current_blue=$(tmx_var_get "counter_blue" "$session")
        local v=$((current_blue + 3))
        tmx_var_set "counter_blue" "$v" "$session"
        clear
        msg_bg_blue "BLUE COUNTER (PANE 2)"
        msg_blue "Value: ${v}"
        msg_blue "Press '2' in control pane to close"
        sleep 2
    done
}

# Create tmux session and run functions in panes
main() {
    s=$(tmx_create_session "counter_$(date +%s)")
    
    # Start monitor in first pane
    tmx_execute_shell_function "${s}" 0 monitor "COUNT_GREEN COUNT_BLUE"
    
    # Create and populate additional panes
    p1=$(tmx_create_pane "${s}" "v")
    tmx_execute_shell_function "${s}" "${p1}" green "COUNT_GREEN"
    
    p2=$(tmx_create_pane "${s}")
    tmx_execute_shell_function "${s}" "${p2}" blue "COUNT_BLUE"
    
    # Set up cleanup on exit
    trap 'rm -f "${COUNT_GREEN}" "${COUNT_BLUE}"; exit 0' INT
    
    # Keep parent script running
    echo "Running in: ${s} - Press Ctrl+C to exit"
    while true; do sleep 1; done
}

main
```

---

# Combined Usage Example

This example demonstrates how to use `sh-globals.sh`, `param_handler.sh`, and the `tmux_utils1.sh` suite together, based on the `util-sh_combine_sample.sh` sample.

```bash
#!/usr/bin/env bash
# util-sh_combine_sample.sh - Combined example of utilities
# Demonstrates param handling and tmux session control
# shellcheck disable=SC1091,SC2317,SC2155,SC2034,SC2250,SC2162,SC2312

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the libraries (in the correct order)
source "${SCRIPT_DIR}/sh-globals.sh"
source "${SCRIPT_DIR}/param_handler.sh"
source "${SCRIPT_DIR}/tmux_base_utils.sh"
source "${SCRIPT_DIR}/tmux_script_generator.sh" 
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals with script arguments - this sets _MAIN_SCRIPT_NAME
sh-globals_init "$@"

# Initialize logging if not already initialized
[[ $_LOG_INITIALIZED -eq 0 ]] && log_init "" 0

# Set up logging - now get_script_name will return the correct script name
log_info "Starting script: $(get_script_name)"

# Print a header for the script
msg_header "TMUX CONTROL DEMO (Combined Example)"
msg_section "Environment Setup" 60 "-"

# Check dependencies
msg_info "Checking dependencies..."
if ! check_dependencies tmux; then
  msg_error "Missing required dependency: tmux"
  exit 1
fi

# Define parameters with param_handler
declare -a PARAMS=(
  "name:SESSION_NAME:session:Tmux session name (default: control_demo_TIMESTAMP)"
  "headless:HEADLESS:Run in headless mode (no terminal launch)"
)

# Process parameters
if ! param_handler::simple_handle PARAMS "$@"; then
  exit 1  # Help was shown or parameter validation failed
fi

# Set defaults for optional parameters
SESSION_NAME="${SESSION_NAME:-control_demo_$(date +%s)}"
LAUNCH_TERMINAL="true"
[[ -n "$HEADLESS" ]] && LAUNCH_TERMINAL="false"

# === Counter pane functions ===
# Green counter: Increments by 2 every second
Green() {
    local session="$1"
    while true; do
        local current_green=$(tmx_var_get "counter_green" "$session" 2>/dev/null || echo 0)
        local v=$((current_green + 2))
        tmx_var_set "counter_green" "$v" "$session"
        clear
        msg_bg_green "GREEN COUNTER (PANE 1)"
        msg_green "Value: ${v}"
        msg_green "Press '1' in control pane to close"
        sleep 1
    done
}

# Blue counter: Increments by 3 every 2 seconds
Blue() {
    local session="$1"
    while true; do
        local current_blue=$(tmx_var_get "counter_blue" "$session" 2>/dev/null || echo 0)
        local v=$((current_blue + 3))
        tmx_var_set "counter_blue" "$v" "$session"
        clear
        msg_bg_blue "BLUE COUNTER (PANE 2)"
        msg_blue "Value: ${v}"
        msg_blue "Press '2' in control pane to close"
        sleep 2
    done
}

# Yellow counter: Increments by 5 every 3 seconds
Yellow() {
    local session="$1"
    while true; do
        local current_yellow=$(tmx_var_get "counter_yellow" "$session" 2>/dev/null || echo 0)
        local v=$((current_yellow + 5))
        tmx_var_set "counter_yellow" "$v" "$session"
        clear
        msg_bg_yellow "YELLOW COUNTER (PANE 3)"
        msg_yellow "Value: ${v}"
        msg_yellow "Press '3' in control pane to close"
        sleep 3
    done
}

# === Shared variables ===
# Define which variables to initialize and track
COUNTER_VARS=("counter_green" "counter_blue" "counter_yellow")

# === Main function ===
main() {
  msg_section "Creating Tmux Session" 60 "-"
  
  # Create the session and initialize counter variables to 0
  msg_info "Creating tmux session: $SESSION_NAME"
  if ! tmx_create_session_with_vars "$SESSION_NAME" COUNTER_VARS 0 "$LAUNCH_TERMINAL"; then
    msg_error "Failed to create tmux session '$SESSION_NAME'"
    exit 1
  fi
  
  # Get the actual session name used (might be different if handled duplicates)
  local actual_session_name="${TMX_SESSION_NAME}"
  msg_success "Tmux session '$actual_session_name' created"

  # Create panes and run counter functions in them with auto-registration
  msg_info "Creating counter panes..."
  local p1_id=$(tmx_new_pane_func Green "$actual_session_name" "Green Counter")
  local p2_id=$(tmx_new_pane_func Blue "$actual_session_name" "Blue Counter")
  local p3_id=$(tmx_new_pane_func Yellow "$actual_session_name" "Yellow Counter")
  
  # Use pane 0 (the first pane) as the control pane
  msg_info "Creating monitoring control pane..."
  local p0_id=$(tmx_create_monitoring_control "$actual_session_name" COUNTER_VARS "PANE" "1" "0")
  
  # Make sure titles are enabled
  tmx_enable_pane_titles "$actual_session_name"
  
  # Display session information
  tmx_display_info "$actual_session_name"
  
  # Monitor the session until it terminates
  tmx_monitor_session "$actual_session_name" 0.5 "Monitoring session '$actual_session_name'... Press Ctrl+C to exit."
  
  msg_success "Session closed. Goodbye!"
}

# Run the main function
main
exit $? 
```

This example demonstrates:

1. **Initialization**: Setting up all libraries (`sh-globals`, `param_handler`, `tmux_base_utils`, `tmux_script_generator`, `tmux_utils1`) and initializing with script arguments.
2. **Logging**: Using both log functions and colorized message display from `sh-globals.sh`.
3. **Parameter Handling**: Using `param_handler.sh` to process command-line arguments like `--session` and `--headless`.
4. **Tmux Session Management**: Creating and managing a tmux session with multiple panes running counter functions.
5. **Tmux Function Usage**: Utilizing functions like `tmx_create_session_with_vars`, `tmx_new_pane_func`, `tmx_create_monitoring_control`, `tmx_enable_pane_titles`, `tmx_display_info`, and `tmx_monitor_session`.
6. **Variable Sharing**: Demonstrates variable sharing between panes using `tmx_var_set`/`tmx_var_get` within the counter functions.

## License

These utilities are provided as open source under the MIT License. Feel free to use and modify as needed.
