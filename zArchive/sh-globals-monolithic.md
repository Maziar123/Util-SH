\
# sh-globals.sh - Comprehensive Bash Utility Library

A comprehensive shell utility library providing common functions, constants, and tools for bash scripts.

## Overview

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

## Installation

1.  Download the `sh-globals.sh` file to your project directory.
2.  Make the script executable:
    ```bash
    chmod +x sh-globals.sh
    ```
3.  Source it at the beginning of your scripts:
    ```bash
    #!/usr/bin/env bash

    # Source the library
    source "$(dirname "$0")/sh-globals.sh"

    # Initialize with your script's arguments (IMPORTANT)
    sh-globals_init "$@"

    # Now you can use all the library functions
    msg_info "Script initialized."
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

## Key Features & Function Reference

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

**Initialization (`log_init`)**:

-   `log_file`: Path to the log file. If omitted, defaults to `script_name.log` in the current directory.
-   `save_to_file`: Set to `1` (default) to save logs to the file, `0` to log only to the console (stderr/stdout).

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

# Output to terminal (colors vary):
# [INFO] Operation started
# [WARN] Resource usage high
# [ERROR] Failed to connect to server
# [DEBUG] Variable state: value=example
# [SUCCESS] Backup completed successfully
# [2023-10-27 10:30:00] CUSTOM: Special event occurred

# File content (/var/log/myscript.log if initialized):
# [2023-10-27 10:29:59] INFO: Logging initialized to /var/log/myscript.log
# [2023-10-27 10:30:00] INFO: Operation started
# [2023-10-27 10:30:00] WARN: Resource usage high
# [2023-10-27 10:30:00] ERROR: Failed to connect to server
# [2023-10-27 10:30:00] DEBUG: Variable state: value=example
# [2023-10-27 10:30:00] SUCCESS: Backup completed successfully
# [2023-10-27 10:30:00] CUSTOM: Special event occurred
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

if ! array_contains "kiwi" "${fruits[@]}"; then
  echo "Array does not contain kiwi" # Prints
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

**Temporary Resource Management**: Files and directories created with `create_temp_file` and `create_temp_dir` are automatically registered for cleanup when the script exits (due to the `EXIT` trap set by `sh-globals_init`).

Example:

```bash
# Check prerequisites
if ! command_exists "jq"; then
  msg_error "jq command not found. Please install jq."
  exit 1
fi

# Safe directory creation
safe_mkdir "/var/data/app/logs"

# File testing with better output
if ! file_exists "/etc/config.json"; then
  msg_error "Configuration file missing: /etc/config.json"
  exit 1
fi

if dir_exists "/tmp/my_app"; then
  msg_info "App directory exists"
fi

# Get file information
size=$(file_size "data.log")
msg_info "Log file size: $size bytes"

filename="archive.tar.gz"
ext=$(get_file_extension "$filename")    # "gz"
base=$(get_file_basename "$filename")    # "archive.tar"
msg_info "File: $filename, Base: $base, Extension: $ext"

# Safe copy
if safe_copy "source.txt" "backup/source.bak"; then
  msg_success "Backup created."
else
  msg_error "Failed to create backup."
fi

# Temporary file handling (auto-cleaned on exit)
temp_data=$(create_temp_file "data_proc_XXXX")
temp_dir=$(create_temp_dir "results_XXXX")
msg_info "Using temp file $temp_data and temp dir $temp_dir"
echo "Processing data..." > "$temp_data"
# ... process data, put results in $temp_dir ...

# Wait for file to appear (useful for async operations)
touch ./signal.file & # Simulate background task creating a file
if wait_for_file "./signal.file" 5; then # Wait up to 5 seconds
  msg_success "Signal file detected."
  rm ./signal.file
else
  msg_error "Timed out waiting for signal file."
fi
```

### 7. User Interaction Functions

Functions to prompt the user for input, confirmation, and validated values.

| Function                                                      | Description                              | Parameters                                       | Returns          |
| :------------------------------------------------------------ | :--------------------------------------- | :----------------------------------------------- | :--------------- |
| `confirm [prompt="Are you sure?"] [default=n]`                | Confirm prompt (y/n)                     | `[prompt]` `[default=y\|n]`                    | Boolean (exit code) |
| `prompt_input [prompt] [default]`                             | Prompt for input with optional default   | `prompt` `[default]`                           | User input string |
| `prompt_password [prompt="Password:"]`                        | Prompt for password (hidden input)       | `[prompt]`                                     | Password string  |
| `get_number [prompt] [default] [min] [max]`                   | Get a validated numeric input            | `[prompt]` `[default]` `[min]` `[max]`         | Number           |
| `get_string [prompt] [default] [pattern] [error_msg]`         | Get string with optional regex validation| `[prompt]` `[default]` `[pattern]` `[error_msg]`| String           |
| `get_path [prompt] [default] [type] [must_exist=0]`           | Get file/directory path with validation  | `[prompt]` `[default]` `[type]` `[must_exist]`   | Path string      |
| `get_value [prompt] [default] [validator_func] [error_msg]` | Get value with custom validation function| `[prompt]` `[default]` `[validator]` `[error_msg]`| Validated value |

**Validation Functions (`get_number`, `get_string`, `get_path`, `get_value`)**: These functions will re-prompt the user until valid input is provided according to the specified constraints (range, pattern, existence, custom function).

Example:

```bash
# Simple confirmation (returns 0 for yes, 1 for no)
if confirm "Delete all temporary files?" "n"; then
  msg_info "Deleting files..."
  # ... delete files ...
else
  msg_info "Deletion cancelled."
fi

# Input with default value
name=$(prompt_input "Enter your name" "guest")
msg_info "Hello, $name!"

# Secure password input (hidden)
password=$(prompt_password "Enter database password:")
# Use "$password" carefully

# Validated numeric input
port=$(get_number "Enter server port" "8080" "1" "65535")
msg_info "Using port: $port"

# String with pattern validation
email=$(get_string "Enter your email" "" "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "Invalid email format")
msg_info "Email set to: $email"

# Path validation
config_file=$(get_path "Enter config file path" "./app.conf" "file" "1") # Must be an existing file
msg_info "Using config file: $config_file"

output_dir=$(get_path "Enter output directory" "/tmp/output" "dir" "0") # Can be non-existent directory
msg_info "Output directory: $output_dir"

# Custom validation function
validate_hostname() {
  # Simple check: allow letters, numbers, hyphens, dots
  [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9\.-]*[a-zA-Z0-9]$ ]]
}
server=$(get_value "Enter server hostname" "server1.example.com" validate_hostname "Invalid hostname format")
msg_info "Server hostname: $server"
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
msg_info "Using API Key (masked): ${api_key:0:3}..." # Be careful logging secrets
msg_info "Log Level: $log_level"

# Privilege checks
if ! is_root; then
  msg_warning "This script ideally runs as root, but proceeding."
fi
# Or enforce root:
# require_root # Script exits here if not root

# Get user/host info
user=$(get_current_user)
host=$(get_hostname)
msg_info "Running as user '$user' on host '$host'"

# Flags like DEBUG, VERBOSE are parsed by sh-globals_init
# Access them directly:
if [[ "${DEBUG:-0}" -eq 1 ]]; then
  msg_debug "Debug messages are enabled."
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
  # Add Linux-specific logic here
elif [[ "$os_type" == "mac" ]]; then
  msg_info "Running on macOS"
  # Add macOS-specific logic here
fi

if is_in_container; then
  msg_info "Running inside a container (Docker, LXC, etc.)"
else
  msg_info "Not running inside a known container type."
fi
```

### 10. Date & Time Functions

| Function                                     | Description                             | Parameters                      | Returns               |
| :------------------------------------------- | :-------------------------------------- | :------------------------------ | :-------------------- |
| `get_timestamp`                              | Get current timestamp (Unix epoch seconds)| None                            | Timestamp (integer)   |
| `format_date [format=%Y-%m-%d] [timestamp=now]` | Format date/time using `strftime`       | `[format]` `[timestamp]`        | Formatted date string |
| `time_diff_human [start] [end=now]`          | Human-readable time difference          | `start_ts` `[end_ts]`           | Formatted time string |

**Note on `format_date`**: Uses `TZ=UTC` internally for consistent output regardless of the system's timezone.

Example:

```bash
# Record start time
start_time=$(get_timestamp)
msg_info "Operation started at: $start_time"

# Format dates consistently
today=$(format_date "%Y-%m-%d") # Default format
log_ts=$(format_date "%Y%m%d_%H%M%S")
iso_ts=$(format_date "%Y-%m-%dT%H:%M:%SZ") # ISO 8601 format in UTC
msg_info "Today (UTC): $today"
msg_info "Timestamp for logs: $log_ts"
msg_info "ISO Timestamp: $iso_ts"

# Format a specific timestamp
past_event_ts=1609459200 # Jan 1, 2021 00:00:00 UTC
past_event_str=$(format_date "%Y-%m-%d %H:%M:%S" "$past_event_ts")
msg_info "Past event occurred at (UTC): $past_event_str" # Output: 2021-01-01 00:00:00

# Do some work...
sleep 3

# Get elapsed time in human-readable format
end_time=$(get_timestamp)
elapsed=$(time_diff_human "$start_time" "$end_time") # e.g., "3s"
elapsed_long=$(time_diff_human "$start_time")      # Implicitly uses current time as end
msg_info "Operation completed in $elapsed"

# Example of longer durations
diff1=$(time_diff_human 0 95)       # "1m 35s"
diff2=$(time_diff_human 0 3725)     # "1h 2m 5s"
diff3=$(time_diff_human 0 90061)    # "1d 1h 1m 1s"
msg_info "Examples: 95s=$diff1, 3725s=$diff2, 90061s=$diff3"
```

### 11. Networking Functions

| Function                                     | Description                      | Parameters                    | Returns             |
| :------------------------------------------- | :------------------------------- | :---------------------------- | :------------------ |
| `is_url_reachable [url] [timeout=5]`         | Check if URL is reachable (HEAD/GET) | `url` `[timeout]`             | Boolean (exit code) |
| `get_external_ip`                            | Get external/public IP address   | None                          | IP address string   |
| `is_port_open [host] [port] [timeout=2]`     | Check if TCP port is open on host| `host` `port` `[timeout]`     | Boolean (exit code) |

**Dependencies**: These functions rely on `curl` or `wget` (`is_url_reachable`, `get_external_ip`) and `nc` (netcat) (`is_port_open`). Ensure these are installed.

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
else
  msg_warning "Could not determine external IP address."
fi

# Check service port
db_host="db.internal.net"
db_port=5432
if is_port_open "$db_host" "$db_port" 2; then
  msg_success "Database port $db_port is open on $db_host."
else
  msg_warning "Database port $db_port seems closed on $db_host."
fi
```

### 12. Script Lock Functions

Prevents multiple instances of the script from running simultaneously using a lock file.

| Function                     | Description                                         | Parameters    | Returns             |
| :--------------------------- | :-------------------------------------------------- | :------------ | :------------------ |
| `create_lock [lock_file]`    | Create lock file (fails if valid lock exists)       | `[lock_file]` | Boolean (exit code) |
| `release_lock`               | Release the lock file (usually done automatically) | None          | None                |

**Lock File Path**: If `lock_file` is not provided to `create_lock`, it defaults to `/tmp/script_name.lock`.
**Automatic Release**: The lock is automatically released when the script exits (cleanly or via error) due to the `EXIT` trap set by `sh-globals_init`. `release_lock` is mostly for manual release if needed before script end.

Example:

```bash
# Define a custom lock file path (optional)
LOCK_FILE="/var/run/my_app/$(get_script_name).pid"

# Attempt to create the lock
if ! create_lock "$LOCK_FILE"; then
# Or use default: if ! create_lock; then
  msg_error "Another instance is already running. Check lock file: $LOCK_FILE"
  exit 1
fi

msg_success "Lock acquired ($LOCK_FILE). Running exclusively."

# --- Main script logic here ---
# ... do work ...
sleep 10

# Lock will be released automatically on exit.
# Manual release example (rarely needed):
# msg_info "Releasing lock manually..."
# release_lock

msg_success "Script finished."
```

### 13. Error Handling Functions

Provides mechanisms for error trapping and stack traces.

| Function                                | Description                                  | Parameters                | Returns |
| :-------------------------------------- | :------------------------------------------- | :------------------------ | :------ |
| `print_stack_trace`                     | Print the current function call stack        | None                      | None    |
| `error_handler [exit_code] [line_number]` | Default ERR trap handler (logs, cleans up) | `exit_code` `line_number` | None    |
| `setup_traps`                           | Setup ERR and EXIT traps (used by init)    | None                      | None    |

**Automatic Handling**: `sh-globals_init` calls `setup_traps`, which sets the `error_handler` function to be called automatically when any command fails (due to `set -e`). The error handler logs the error, prints a stack trace, cleans up temporary resources and locks, and then exits the script with the command's exit code.

Example:

```bash
# setup_traps is called by sh-globals_init automatically

# Function to demonstrate stack trace
function inner_function() {
  msg_info "Inside inner_function"
  # Manually print stack trace (for debugging, not typically needed)
  print_stack_trace
  # Cause an error
  ls /nonexistent_directory
}

function outer_function() {
  msg_info "Inside outer_function"
  inner_function
}

msg_info "Calling outer_function..."
outer_function
msg_info "This message will not be reached if an error occurs above."

# Example Output on Error:
# Calling outer_function...
# Inside outer_function
# Inside inner_function
# Stack trace:
#   1: ./my_script.sh:55 in function inner_function
#   2: ./my_script.sh:61 in function outer_function
#   3: ./my_script.sh:64 in function main
# ls: cannot access '/nonexistent_directory': No such file or directory
# [ERROR] Error on line 58, exit code 2
# Stack trace:
#   1: ./my_script.sh:58 in function inner_function
#   2: ./my_script.sh:61 in function outer_function
#   3: ./my_script.sh:64 in function main
# (Script exits here, temporary files/locks cleaned up)
```

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

msg_success "All required dependencies found: git, docker, kubectl, helm"
```

### 15. Number Formatting Functions

Format numbers into human-readable strings using SI prefixes or byte units.

| Function                                  | Description                                     | Parameters             | Returns          |
| :---------------------------------------- | :---------------------------------------------- | :--------------------- | :--------------- |
| `format_si_number [number] [precision=1]` | Format number with SI prefixes (K, M, G, T, P, m, μ, n) | `number` `[precision]` | Formatted string |
| `format_bytes [bytes] [precision=1]`      | Format bytes to human-readable size (KB, MB, GB, TB) | `bytes` `[precision]`  | Formatted string |

Example:

```bash
# Format numbers with SI prefixes
users=8543210
rate=0.00045
large_num=1234567890123
formatted_users=$(format_si_number "$users")      # "8.5M"
formatted_rate=$(format_si_number "$rate" 3)      # "450.0μ" (micro)
formatted_large=$(format_si_number "$large_num" 2) # "1.23T"

msg_info "Users: $formatted_users"
msg_info "Rate: $formatted_rate /s"
msg_info "Large Number: $formatted_large"

# Format bytes with appropriate units
file_size_bytes=2684354560
small_size_bytes=1536
formatted_size=$(format_bytes "$file_size_bytes")      # "2.5GB"
formatted_small=$(format_bytes "$small_size_bytes")   # "1.5KB"
precise_size=$(format_bytes 1500000 2)               # "1.43MB"

msg_info "File Size: $formatted_size"
msg_info "Small Size: $formatted_small"
msg_info "Precise Size: $precise_size"

# Display disk usage (example using system command + formatting)
# disk_used_bytes=$(df / | awk 'NR==2 {print $3 * 1024}') # Example command
# formatted_disk_used=$(format_bytes "$disk_used_bytes" 1)
# msg_info "Disk Used: $formatted_disk_used"
```

### 16. Path Navigation Functions

Utilities for manipulating file paths and sourcing files relative to the script.

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
log_info "Running script: $script_name in $script_dir (Full path: $script_path)"

# Path navigation
config_dir=$(get_parent_dir "$script_dir")
log_info "Parent (config?) directory: $config_dir"

project_root=$(get_parent_dir_n "$script_dir" 2)
log_info "Project root (2 levels up): $project_root"

# Get absolute path relative to script
data_file_path=$(path_relative_to_script "../data/input.csv")
log_info "Absolute path to data file: $data_file_path"

# Convert potentially relative path to absolute
user_input_path="./output"
absolute_output_path=$(to_absolute_path "$user_input_path")
log_info "Absolute output path: $absolute_output_path"

# Source a library relative to the script
if ! source_relative "../lib/common_funcs.sh"; then
  msg_error "Failed to source common functions library."
  exit 1
fi

# Source a utility with fallbacks
if ! source_with_fallbacks "config.sh" "conf/settings.sh" "/etc/app/config.sh"; then
  msg_warning "Could not find config.sh using fallback paths."
fi

# Create parent path references
three_levels_up=$(parent_path 3) # "../../../"
log_info "Path to go three levels up: $three_levels_up"
cd "$project_root/${three_levels_up}some/other/branch" # Example usage
```

## Advanced Usage Patterns

### Complete Error Handling Example

Leveraging `set -e` and the automatic `error_handler` trap.

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"

# Initialize logging
log_init "/var/log/myapp_adv.log"

# Function that might fail
perform_operation() {
  local path="$1"
  msg_info "Attempting operation on: $path"

  # This command will fail if path doesn't exist, triggering ERR trap
  ls "$path" > /dev/null

  # This part is reached only if ls succeeds
  msg_success "Operation successful on: $path"
  return 0
}

# Main processing logic
main() {
  log_info "Advanced Script started"

  # Create a lock
  if ! create_lock; then
    # error_handler will NOT be called for explicit exit
    log_error "Another instance is already running. Exiting."
    exit 1 # Manually exit; cleanup trap still runs
  fi
  log_info "Lock acquired."

  # Perform operations
  perform_operation "/etc/hosts" # This should succeed

  # This will likely fail and trigger the error handler
  perform_operation "/nonexistent/path/here"

  # This line will not be reached if the previous command failed
  log_success "Script completed all operations successfully"
}

# Run main function
main
# The EXIT trap ensures cleanup_temp and release_lock run regardless
# of whether the script exits normally or via the error_handler.
```

### Temporary File Management Pattern

Using `create_temp_file` and `create_temp_dir` for automatically cleaned resources.

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"

process_data() {
  local url="$1"
  local output_file="$2"

  msg_info "Processing data from $url"

  # Create temporary resources needed for processing
  local temp_dir
  local raw_data_file
  local sorted_data_file
  temp_dir=$(create_temp_dir "dataproc_XXXXXX")
  raw_data_file=$(create_temp_file "raw_XXXXXX")
  sorted_data_file=$(create_temp_file "sorted_XXXXXX")
  msg_debug "Using temp dir: $temp_dir"
  msg_debug "Using raw data file: $raw_data_file"
  msg_debug "Using sorted data file: $sorted_data_file"

  # Simulate download
  msg_info "Downloading data..."
  # curl -sSL "$url" -o "$raw_data_file" # Real command
  echo -e "banana\napple\norange" > "$raw_data_file" # Dummy data
  if [[ $? -ne 0 ]]; then
     msg_error "Failed to download data"
     return 1 # Error handler will trigger cleanup
  fi

  # Simulate processing (sort)
  msg_info "Sorting data..."
  sort "$raw_data_file" > "$sorted_data_file"
  if [[ $? -ne 0 ]]; then
     msg_error "Failed to sort data"
     return 1 # Error handler will trigger cleanup
  fi

  # Simulate final step (copy result)
  msg_info "Saving final result to $output_file"
  cp "$sorted_data_file" "$output_file"
  if [[ $? -ne 0 ]]; then
     msg_error "Failed to save final result"
     return 1 # Error handler will trigger cleanup
  fi

  # Temp files/dir ($temp_dir, $raw_data_file, $sorted_data_file)
  # will be automatically cleaned up on script exit (success or error).
  msg_success "Data processing complete. Result in $output_file"
  return 0
}

# Main script
OUTPUT_DIR="./processed_results"
safe_mkdir "$OUTPUT_DIR"
RESULT_FILE="$OUTPUT_DIR/final_data.txt"
DATA_URL="http://example.com/dummy_data.txt" # Dummy URL

if process_data "$DATA_URL" "$RESULT_FILE"; then
  msg_info "Final result:"
  cat "$RESULT_FILE"
else
  msg_error "Data processing failed."
  # Cleanup still happens automatically via EXIT/ERR traps
  exit 1
fi
```

## Tips for Effective Use

1.  **Always Initialize**: Call `sh-globals_init "$@"` right after sourcing the library. This is essential for error handling, flag parsing, and cleanup to work correctly.
2.  **Prefer `msg_*` over `echo`**: Use `msg_info`, `msg_error`, `msg_success`, etc., for console output. They provide consistent formatting, color-coding, and proper stream handling (e.g., errors to stderr).
3.  **Use `log_*` for Persistent Logs**: When you need a record of execution (especially for background jobs or debugging), initialize logging with `log_init` and use the `log_*` functions (`log_info`, `log_error`, etc.).
4.  **Leverage Automatic Error Handling**: Rely on `set -e` (set by default) and the `ERR` trap. Write your code assuming commands succeed. If a command fails, the `error_handler` will automatically log, clean up, and exit. Avoid excessive manual error checking unless specific recovery logic is needed.
5.  **Use Temporary Resource Functions**: Use `create_temp_file` and `create_temp_dir`. This ensures temporary resources are cleaned up automatically, even if the script fails unexpectedly.
6.  **Utilize Input Validation**: Use `get_number`, `get_string`, `get_path`, and `get_value` for robust user input, preventing errors caused by invalid formats or values.
7.  **Check Dependencies Early**: Use `check_dependencies` at the beginning of your script to ensure required tools are available, providing a clear error message if they are not.
8.  **Use Script Locking**: Employ `create_lock` for scripts that should not run concurrently (e.g., cron jobs modifying the same resource).

## License

This utility (`sh-globals.sh`) is provided as open source under the MIT License. Feel free to use, modify, and distribute as needed. 