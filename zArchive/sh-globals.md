# sh-globals.sh

A comprehensive shell utility library providing common functions and constants for bash scripts.

## Overview

`sh-globals.sh` is a reusable library that provides a wide range of utility functions for shell scripts, including color definitions, string operations, file handling, error management, and more. It aims to simplify shell scripting by providing ready-to-use functions for common tasks.

## Installation

1. Download the `sh-globals.sh` file to your project directory
2. Source it in your scripts:

```bash
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"  # Initialize with script arguments
```

## Key Features

- Color and formatting for terminal output
- Script information utilities
- Logging functions with file output support
- String manipulation
- Array operations
- File and directory management
- Temporary file handling with automatic cleanup
- User interaction helpers
- System and environment utilities
- OS detection
- Date and time functions
- Networking utilities
- Script locking to prevent multiple instances
- Error handling with stack traces
- Dependency management
- Number Formatting Functions.

## Function Reference

### Color and Formatting

| Variable | Description |
|----------|-------------|
| `BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, GRAY` | Text colors |
| `BG_BLACK, BG_RED, BG_GREEN, BG_YELLOW, BG_BLUE, BG_MAGENTA, BG_CYAN, BG_WHITE` | Background colors |
| `BOLD, DIM, UNDERLINE, BLINK, REVERSE, HIDDEN` | Text formatting |
| `NC` | Reset color/formatting |

Example:

```bash
# Example of using colors
echo -e "${RED}Error:${NC} Something went wrong"
echo -e "${GREEN}Success:${NC} Operation completed"
echo -e "${BOLD}${BLUE}Important:${NC} Read this carefully"

# Output:
# Error: Something went wrong (in red)
# Success: Operation completed (in green)
# Important: Read this carefully (in bold blue)
```

### Script Information

| Function | Description |
|----------|-------------|
| `get_script_dir` | Get the directory of the current script |
| `get_script_name` | Get the name of the current script without path |
| `get_script_path` | Get the absolute path of the current script |
| `get_line_number` | Get the current line number in the script |

Example:

```bash
# Get script information
script_dir=$(get_script_dir)
script_name=$(get_script_name)
script_path=$(get_script_path)
line=$(get_line_number)

echo "Directory: $script_dir"
echo "Name: $script_name"
echo "Path: $script_path"
echo "Current line: $line"

# Output (example):
# Directory: /home/user/scripts
# Name: my_script.sh
# Path: /home/user/scripts/my_script.sh
# Current line: 42
```

### Logging Functions

| Function | Description |
|----------|-------------|
| `log_init [log_file] [save_to_file]` | Initialize logging (both parameters optional). log_file defaults to script_name.log in current directory, save_to_file defaults to 1 (save to file) |
| `log_info [message]` | Log info message |
| `log_warn [message]` | Log warning message |
| `log_error [message]` | Log error message |
| `log_debug [message]` | Log debug message (only if DEBUG=1) |
| `log_success [message]` | Log success message |
| `log_with_timestamp [level] [message]` | Log with timestamp |

Example:

```bash
# Initialize logging with all defaults
# Log file will be the current script name with .log extension in the current directory
log_init

# Or specify just the log file
log_init "/var/log/my_script.log"

# Or specify both log file and whether to save to file
log_init "/var/log/my_script.log" 1  # Save to file
log_init "/var/log/my_script.log" 0  # Console only

# Set debug mode
DEBUG=1

# Log messages at different levels
log_info "Starting process"
log_warn "Resource usage is high"
log_error "Failed to connect to server"
log_debug "Variable x = 42"
log_success "Backup completed"
log_with_timestamp "INFO" "Server started"

# Output to terminal:
# [INFO] Starting process (in green)
# [WARN] Resource usage is high (in yellow, to stderr)
# [ERROR] Failed to connect to server (in red, to stderr)
# [DEBUG] Variable x = 42 (in cyan, to stderr, only if DEBUG=1)
# [SUCCESS] Backup completed (in green)
# [2023-05-15 14:32:45] INFO: Server started

# File content (if save_to_file=1):
# [2023-05-15 14:32:40] INFO: Logging initialized to /var/log/my_script.log
# [2023-05-15 14:32:41] INFO: Starting process
# [2023-05-15 14:32:42] WARN: Resource usage is high
# [2023-05-15 14:32:43] ERROR: Failed to connect to server
# [2023-05-15 14:32:44] DEBUG: Variable x = 42
# [2023-05-15 14:32:44] SUCCESS: Backup completed
# [2023-05-15 14:32:45] INFO: Server started
```

### String Functions

| Function | Description |
|----------|-------------|
| `str_contains [string] [substring]` | Check if string contains substring |
| `str_starts_with [string] [prefix]` | Check if string starts with prefix |
| `str_ends_with [string] [suffix]` | Check if string ends with suffix |
| `str_trim [string]` | Trim whitespace from string |
| `str_to_upper [string]` | Convert string to uppercase |
| `str_to_lower [string]` | Convert string to lowercase |
| `str_length [string]` | Get string length |
| `str_replace [string] [search] [replace]` | Replace all occurrences in string |

Example:

```bash
# String operations
text="  Hello World!  "

# String tests (return boolean)
if str_contains "$text" "World"; then
  echo "Text contains 'World'"  # This will print
fi

if str_starts_with "$text" "  Hello"; then
  echo "Text starts with '  Hello'"  # This will print
fi

if str_ends_with "$text" "!  "; then
  echo "Text ends with '!  '"  # This will print
fi

# String transformations
trimmed=$(str_trim "$text")
echo "Trimmed: '$trimmed'"  # Output: 'Hello World!'

upper=$(str_to_upper "$text")
echo "Uppercase: $upper"  # Output: '  HELLO WORLD!  '

lower=$(str_to_lower "$text")
echo "Lowercase: $lower"  # Output: '  hello world!  '

len=$(str_length "$text")
echo "Length: $len"  # Output: 15

replaced=$(str_replace "$text" "World" "Universe")
echo "Replaced: $replaced"  # Output: '  Hello Universe!  '
```

### Array Functions

| Function | Description |
|----------|-------------|
| `array_contains [element] [array...]` | Check if array contains element |
| `array_join [delimiter] [array...]` | Join array elements with delimiter |
| `array_length [array_name]` | Get array length |

Example:

```bash
# Define an array
fruits=("apple" "banana" "orange" "grape")

# Check if array contains element
if array_contains "banana" "${fruits[@]}"; then
  echo "Array contains banana"  # This will print
fi

if ! array_contains "kiwi" "${fruits[@]}"; then
  echo "Array does not contain kiwi"  # This will print
fi

# Join array elements
joined=$(array_join ", " "${fruits[@]}")
echo "Joined: $joined"  # Output: apple, banana, orange, grape

# Get array length
declare -a colors=("red" "green" "blue")
len=$(array_length colors)
echo "Array length: $len"  # Output: 3
```

### File & Directory Functions

| Function | Description |
|----------|-------------|
| `command_exists [command]` | Check if a command exists |
| `safe_mkdir [directory]` | Create directory if it doesn't exist |
| `file_exists [path]` | Check if file exists and is readable |
| `dir_exists [path]` | Check if directory exists |
| `file_size [path]` | Get file size in bytes |
| `safe_copy [src] [dst]` | Copy file with verification |
| `create_temp_file [template]` | Create a temp file (auto-cleaned) |
| `create_temp_dir [template]` | Create a temp directory (auto-cleaned) |
| `wait_for_file [file] [timeout] [interval]` | Wait for a file to exist |
| `get_file_extension [filename]` | Get file extension |
| `get_file_basename [filename]` | Get filename without extension |

Example:

```bash
# Check if commands exist
if command_exists "docker"; then
  echo "Docker is installed"
fi

# Directory operations
safe_mkdir "output/logs"
echo "Directory created or already exists"

if dir_exists "output"; then
  echo "Output directory exists"
fi

# File operations
if file_exists "/etc/passwd"; then
  echo "Password file exists and is readable"
  size=$(file_size "/etc/passwd")
  echo "File size: $size bytes"
fi

# Copy with verification
if safe_copy "source.txt" "destination.txt"; then
  echo "File copied successfully"
fi

# Get file parts
filename="document.example.pdf"
ext=$(get_file_extension "$filename")
base=$(get_file_basename "$filename")
echo "Extension: $ext"  # Output: pdf
echo "Basename: $base"  # Output: document.example

# Temporary files
temp_file=$(create_temp_file)
echo "Created temp file: $temp_file"  # Output: /tmp/tmp.XXXXXXXXXX
echo "Data" > "$temp_file"
# File will be automatically deleted when script exits

# Wait for file
touch delayed_file.txt &  # Create file in background
if wait_for_file "delayed_file.txt" 5 1; then
  echo "File appeared within timeout"
fi
```

### User Interaction Functions

| Function | Description |
|----------|-------------|
| `confirm [prompt] [default]` | Confirm prompt (y/n) |
| `prompt_input [prompt] [default]` | Prompt for input with default value |
| `prompt_password [prompt]` | Prompt for password (hidden input) |

Example:

```bash
# Confirmation prompt
if confirm "Continue with operation?" "y"; then
  echo "User confirmed"
  # Returns true (0) if user enters y/yes or accepts default "y"
else
  echo "User declined"
  # Returns false (1) if user enters n/no or accepts default "n"
fi

# Input with default
name=$(prompt_input "Enter your name" "guest")
echo "Hello, $name!"
# If user presses Enter without typing, returns "guest"
# Otherwise returns what the user typed

# Password input (not echoed to screen)
password=$(prompt_password "Enter your password")
echo "Password length: ${#password} characters"
# Returns the password entered by user (not shown on screen)
```

### System & Environment Functions

| Function | Description |
|----------|-------------|
| `env_or_default [var_name] [default]` | Get env var or default |
| `is_root` | Check if script is run as root |
| `require_root` | Exit if not running as root |
| `parse_flags [args...]` | Parse common command flags |
| `get_current_user` | Get current username |
| `get_hostname` | Get hostname |

Example:

```bash
# Environment variables
db_host=$(env_or_default "DB_HOST" "localhost")
echo "Database host: $db_host"  # Uses env var if set, or "localhost"

# User and permissions
user=$(get_current_user)
echo "Current user: $user"  # Output: username

host=$(get_hostname)
echo "Hostname: $host"  # Output: server-name

if is_root; then
  echo "Running as root"
else
  echo "Not running as root"
fi

# To require root:
# require_root
# The script will exit here if not running as root

# Parse flags
parse_flags "--debug" "--verbose"
# Sets DEBUG=1 and VERBOSE=1
# Can be accessed as $DEBUG and $VERBOSE
```

### OS Detection Functions

| Function | Description |
|----------|-------------|
| `get_os` | Get OS type (linux, mac, windows) |
| `get_linux_distro` | Get Linux distribution name |
| `get_arch` | Get processor architecture |
| `is_in_container` | Check if running in a container |

Example:

```bash
# Detect OS information
os_type=$(get_os)
echo "Operating System: $os_type"  # Output: linux, mac, windows

if [ "$os_type" = "linux" ]; then
  distro=$(get_linux_distro)
  echo "Linux Distribution: $distro"  # Output: ubuntu, debian, centos, etc.
fi

arch=$(get_arch)
echo "Architecture: $arch"  # Output: amd64, arm64, etc.

if is_in_container; then
  echo "Running inside a container"
else
  echo "Not running in a container"
fi
```

### Date & Time Functions

| Function | Description |
|----------|-------------|
| `get_timestamp` | Get current timestamp in seconds |
| `format_date [format] [timestamp]` | Format date |
| `time_diff_human [start] [end]` | Human-readable time difference |

Example:

```bash
# Current timestamp
now=$(get_timestamp)
echo "Current timestamp: $now"  # Output: 1684159234 (Unix timestamp)

# Format dates
today=$(format_date "%Y-%m-%d")
echo "Today: $today"  # Output: 2023-05-15

custom_date=$(format_date "%d %b %Y, %H:%M" "$now")
echo "Formatted date: $custom_date"  # Output: 15 May 2023, 14:40

# Time difference
start=$(get_timestamp)
sleep 2
end=$(get_timestamp)
diff=$(time_diff_human "$start" "$end")
echo "Operation took: $diff"  # Output: 2s

# Longer example
echo "Time differences:"
echo "$(time_diff_human 0 60)"  # Output: 1m 0s
echo "$(time_diff_human 0 3665)"  # Output: 1h 1m 5s
echo "$(time_diff_human 0 90000)"  # Output: 1d 1h 0m 0s
```

### Networking Functions

| Function | Description |
|----------|-------------|
| `is_url_reachable [url] [timeout]` | Check if URL is reachable |
| `get_external_ip` | Get external IP address |
| `is_port_open [host] [port] [timeout]` | Check if port is open |

Example:

```bash
# Check if URL is reachable
if is_url_reachable "https://www.example.com" 3; then
  echo "Website is reachable"
else
  echo "Website is not reachable"
fi
# Returns true (0) if URL is reachable within timeout

# Get external IP
ip=$(get_external_ip)
echo "External IP: $ip"  # Output: your public IP address

# Check if port is open
if is_port_open "localhost" 22 2; then
  echo "SSH port is open"
else
  echo "SSH port is closed"
fi
# Returns true (0) if port is open
```

### Script Lock Functions

| Function | Description |
|----------|-------------|
| `create_lock [lock_file]` | Create lock file to prevent multiple instances |
| `release_lock` | Release the lock file |

Example:

```bash
# Create a lock file to ensure only one instance runs
if create_lock "/tmp/my_script.lock"; then
  echo "Lock acquired, running exclusively"
  
  # Do work here...
  sleep 5
  
  # Lock will be released automatically on exit
  # But can be manually released if needed:
  # release_lock
else
  echo "Another instance is already running"
  exit 1
fi
# Returns true (0) if lock was created, false (1) if already exists
```

### Error Handling Functions

| Function | Description |
|----------|-------------|
| `print_stack_trace` | Print stack trace |
| `error_handler [exit_code] [line_number]` | Error trap handler |
| `setup_traps` | Setup trap handlers |

Example:

```bash
# Setup error traps (already done in init function)
setup_traps

# Manually print stack trace
function level_3() {
  print_stack_trace
}
function level_2() { level_3; }
function level_1() { level_2; }
level_1

# Output:
# Stack trace:
#   1: /path/to/script.sh:123 in level_3
#   2: /path/to/script.sh:122 in level_2
#   3: /path/to/script.sh:121 in level_1
#   4: /path/to/script.sh:124 in main

# Error handler is automatically called on script errors
# when setup_traps is used
bad_command_causing_error
# Output:
# [ERROR] Error on line 130, exit code 127
# Stack trace:
#   1: /path/to/script.sh:130 in main
```

### Dependency Management

| Function | Description |
|----------|-------------|
| `check_dependencies [cmd...]` | Check if required commands exist |

Example:

```bash
# Check if all required commands are available
if check_dependencies curl jq docker; then
  echo "All dependencies are installed"
else
  echo "Missing dependencies, exiting"
  exit 1
fi
# Returns true (0) if all dependencies exist
# Returns false (1) if any dependency is missing
# Also outputs error message listing missing dependencies
```

### Number Formatting Functions

| Function | Description |
|----------|-------------|
| `format_si_number [number] [precision]` | Format number with SI prefixes (K, M, G, T, P) |
| `format_bytes [bytes] [precision]` | Format bytes to human-readable size (KB, MB, GB, TB) |

Example:

```bash
# Format numbers with SI prefixes
echo $(format_si_number 1500)       # Output: 1.5K
echo $(format_si_number 1500000)    # Output: 1.5M
echo $(format_si_number 1500000000) # Output: 1.5G
echo $(format_si_number 0.001)      # Output: 1m
echo $(format_si_number 0.000001)   # Output: 1μ

# Format with custom precision
echo $(format_si_number 1234567 2)  # Output: 1.23M

# Format file sizes
echo $(format_bytes 1024)         # Output: 1KB
echo $(format_bytes 1048576)      # Output: 1MB
echo $(format_bytes 1073741824)   # Output: 1GB
echo $(format_bytes 1234567 2)    # Output: 1.18MB
```

### Message Functions

| Function | Description |
|----------|-------------|
| `msg [message]` | Display a plain message |
| `msg_info [message]` | Display an informational message (blue) |
| `msg_success [message]` | Display a success message (green) |
| `msg_warning [message]` | Display a warning message (yellow) to stderr |
| `msg_error [message]` | Display an error message (red) to stderr |
| `msg_highlight [message]` | Display a highlighted message (cyan) |
| `msg_header [message]` | Display a header message (bold, magenta) |
| `msg_section [text] [width] [char]` | Display a section divider with text |
| `msg_subtle [message]` | Display a subtle/dim message (gray) |
| `msg_color [message] [color]` | Display a message with custom color |
| `msg_step [step] [total] [description]` | Display a step or progress message |
| `msg_debug [message]` | Display debug message only when DEBUG=1 |

Example:

```bash
# Basic message
msg "This is a plain message"

# Colored messages
msg_info "This is an informational message"
msg_success "This is a success message"
msg_warning "This is a warning message"
msg_error "This is an error message"
msg_highlight "This is a highlighted message"
msg_header "This is a header message"
msg_subtle "This is a subtle message"

# Custom color
msg_color "This is a custom colored message" "$MAGENTA"

# Section dividers
msg_section "Section Title"
msg_section "Narrow Section" 40 "-"
msg_section "" 60 "*"  # Just a line without text

# Progress steps
msg_step 1 5 "Downloading resources"
msg_step 2 5 "Extracting files"

# Debug message (displays only when DEBUG=1)
DEBUG=1
msg_debug "This is a debug message"
```

### Get Value Functions

| Function | Description |
|----------|-------------|
| `get_number [prompt] [default] [min] [max]` | Get a validated numeric input |
| `get_string [prompt] [default] [pattern] [error_msg]` | Get string with optional regex validation |
| `get_path [prompt] [default] [type] [must_exist]` | Get file/directory path with validation |
| `get_value [prompt] [default] [validator_func] [error_msg]` | Get value with custom validation function |

Example:

```bash
# Get a numeric value with validation
age=$(get_number "Enter your age" "30" "18" "120")
echo "Age: $age years"  # Ensures value is between 18-120

# Get a string that matches a pattern
email=$(get_string "Enter email address" "" "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "Invalid email format")
echo "Email: $email"  # Validates email format

# Get a file path that must exist
config_file=$(get_path "Enter config file path" "./config.json" "file" "1")
echo "Config file: $config_file"  # Shows absolute path to existing file

# Get a directory path (doesn't need to exist)
output_dir=$(get_path "Enter output directory" "./output" "dir" "0")
echo "Output will be saved to: $output_dir"

# Custom validation
is_valid_hostname() {
  [[ "$1" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]
}
hostname=$(get_value "Enter hostname" "localhost" is_valid_hostname "Invalid hostname format")
echo "Hostname: $hostname"
```

### Initialization

| Function | Description |
|----------|-------------|
| `sh-globals_init [args...]` | Initialize the shell globals |

Example:

```bash
# Source the utilities and initialize
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"

# This does:
# - Sets up trap handlers
# - Enables pipefail
# - Initializes DEBUG, VERBOSE, QUIET, FORCE variables
# - Parses common flags from arguments
# - Sets up temp file/directory cleanup
echo "Shell utilities initialized"

# Now other functions can be used
log_info "Script starting"
```

## Usage Examples

### Basic Usage with File Logging

```bash
#!/usr/bin/env bash

# Source the utilities
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"

# Initialize logging with defaults (uses script_name.log in current directory)
log_init

# Or specify log file and output type:
# log_init "/var/log/my_script.log" 1  # Both console and file output
# log_init "/var/log/my_script.log" 0  # Console output only

# Log messages
log_info "Starting script: $(get_script_name)"
log_debug "Debug mode enabled"

# Check dependencies
if ! check_dependencies curl jq; then
  log_error "Missing required dependencies"
  exit 1
fi

# Script locking
if ! create_lock; then
  log_error "Script already running"
  exit 1
fi

# Do your work...
log_success "Script completed successfully"
```

### User Interaction

```bash
if confirm "Do you want to continue?" "y"; then
  log_info "User confirmed"
else
  log_info "User canceled"
  exit 0
fi

name=$(prompt_input "Enter your name" "anonymous")
log_info "Hello, $name!"

password=$(prompt_password "Enter password")
```

### File Operations

```bash
if ! file_exists "config.json"; then
  log_error "Config file not found"
  exit 1
fi

# Create a temp file that will be auto-cleaned on exit
temp_file=$(create_temp_file)
echo "Temporary data" > "$temp_file"
log_info "Wrote to temp file: $temp_file"

# Safe directory creation
safe_mkdir "output/data"
```

### String Manipulation

```bash
if str_contains "$input" "error"; then
  log_warn "Input contains error"
fi

hostname=$(str_to_lower "$(get_hostname)")
```

## License

This utility is provided as open source. Feel free to use and modify as needed. 
