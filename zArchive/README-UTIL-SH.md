# Util-Sh - Bash Utility Libraries

A collection of comprehensive shell utility libraries providing common functions and tools for bash scripts.

## Overview

Util-Sh contains multiple utility libraries designed to simplify shell scripting:

1. **sh-globals.sh**: A comprehensive shell utility library with color definitions, string operations, file handling, error management, and more.
2. **param_handler.sh**: A lightweight Bash library for handling both named and positional command-line parameters in shell scripts.

These libraries aim to make shell scripting more robust, maintainable, and easier to implement.

## Installation

1. Download the required files:

```bash
# Clone the repository or download the files
git clone https://github.com/yourusername/Util-Sh.git
cd Util-Sh
```

2. Make the scripts executable:

```bash
chmod +x sh-globals.sh param_handler.sh
```

3. Source the libraries in your script:

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/sh-globals.sh"
source "$(dirname "$0")/param_handler.sh"

# Initialize libraries
sh-globals_init "$@"
```

## Dependencies

The `param_handler.sh` library depends on [getoptions](https://github.com/ko1nksm/getoptions), a powerful command-line argument parser for shell scripts.

- **Repository**: [ko1nksm/getoptions](https://github.com/ko1nksm/getoptions)
- **License**: [Creative Commons Zero v1.0 Universal](https://github.com/ko1nksm/getoptions/blob/master/LICENSE)
- **Version**: v3.3.2 (included in this project)

## Library 1: sh-globals.sh

`sh-globals.sh` is a comprehensive utility library that enhances your shell scripts with a wide range of functionality through carefully crafted functions, consistent error handling, and standardized output formatting.

### Key Features

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

### Getting Started

```bash
#!/usr/bin/env bash

# Source the library
source "$(dirname "$0")/sh-globals.sh"

# Initialize with your script's arguments
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

### Core Function Categories

#### Color and Formatting

The library provides comprehensive terminal color and formatting constants:

```bash
# Example usage
echo -e "${RED}Error:${NC} Something went wrong"
echo -e "${YELLOW}Warning:${BOLD} Important note${NC}"
echo -e "${BG_BLUE}${WHITE}Highlighted information${NC}"
```

Available constants include:
- Text colors: `BLACK`, `RED`, `GREEN`, `YELLOW`, `BLUE`, `MAGENTA`, `CYAN`, `WHITE`, `GRAY`
- Background colors: `BG_BLACK`, `BG_RED`, `BG_GREEN`, `BG_YELLOW`, `BG_BLUE`, `BG_MAGENTA`, `BG_CYAN`, `BG_WHITE`
- Text formatting: `BOLD`, `DIM`, `UNDERLINE`, `BLINK`, `REVERSE`, `HIDDEN`
- Reset: `NC` (No Color)

#### Message Functions

Modern formatted message functions for clear, consistent output:

```bash
msg "Standard message"
msg_info "Informational message"
msg_success "Success message"
msg_warning "Warning message"
msg_error "Error message"
msg_highlight "Highlighted message"
msg_header "SECTION HEADER"
msg_section "Configuration" 60 "-"
msg_debug "Debug information"  # Only shown when DEBUG=1
```

These functions use consistent colors and formatting, improving readability of script output.

#### Robust Logging System

Multi-level logging with optional file output:

```bash
# Initialize logging (optionally to file)
log_init "/var/log/myscript.log"

# Log with different severity levels
log_info "Operation started"
log_warn "Resource usage high"
log_error "Failed to connect"
log_debug "Variable state: $value"
log_success "Backup completed"

# Custom timestamp logging
log_with_timestamp "CUSTOM" "Special message"
```

#### Advanced String Operations

```bash
# String operations
name="  John Doe  "
trimmed=$(str_trim "$name")               # "John Doe"
upper=$(str_to_upper "$name")             # "  JOHN DOE  "
contains=$(str_contains "$name" "John")   # true (returns 0)
length=$(str_length "$trimmed")           # 8
replaced=$(str_replace "$name" "John" "Jane")  # "  Jane Doe  "

# String testing
if str_starts_with "$filename" "log-"; then
  echo "This is a log file"
fi

if str_ends_with "$filename" ".bak"; then
  echo "This is a backup file"
fi
```

#### File and Directory Management

```bash
# Safe directory creation
safe_mkdir "/var/data/app"

# File testing with better output
if ! file_exists "/etc/config.json"; then
  msg_error "Configuration file missing"
  exit 1
fi

# Get file information
size=$(file_size "data.log")
ext=$(get_file_extension "document.pdf")  # "pdf"
name=$(get_file_basename "document.pdf")  # "document"

# Temporary file handling with automatic cleanup
temp_file=$(create_temp_file)
temp_dir=$(create_temp_dir)

# File operations with validation
safe_copy "source.txt" "backup/source.txt"

# Wait for file to appear (useful for async operations)
if wait_for_file "/var/run/service.pid" 5; then
  pid=$(cat "/var/run/service.pid")
fi
```

#### User Interaction

```bash
# Simple confirmation (returns true/false)
if confirm "Delete all files?" "n"; then
  # Delete files
fi

# Input with default value
name=$(prompt_input "Enter your name" "guest")

# Secure password input (hidden)
password=$(prompt_password "Enter password")

# Validated numeric input
age=$(get_number "Enter age" "30" "18" "120")

# String with pattern validation
email=$(get_string "Email address" "" "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "Invalid email format")

# Path with validation
config_file=$(get_path "Config file" "./config.json" "file" "1")

# Custom validation function
function validate_hostname() {
  [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](\.[a-zA-Z0-9-]{1,61})+$ ]]
}
hostname=$(get_value "Enter hostname" "localhost" validate_hostname "Invalid hostname format")
```

#### Date and Time Utilities

```bash
# Record start time
start_time=$(get_timestamp)

# Format dates consistently
today=$(format_date "%Y-%m-%d")
timestamp=$(format_date "%Y%m%d_%H%M%S")
specific_time=$(format_date "%Y-%m-%d %H:%M:%S" "1609459200")  # 2021-01-01 00:00:00

# Do some work...
sleep 5

# Get elapsed time in human-readable format
end_time=$(get_timestamp)
elapsed=$(time_diff_human "$start_time" "$end_time")  # "5s" or "2m 30s"
msg_info "Operation completed in $elapsed"
```

#### Path Navigation and Operations

```bash
# Get script-related paths
script_dir=$(get_script_dir)
script_name=$(get_script_name)
script_path=$(get_script_path)

# Navigate directories
parent_dir=$(get_parent_dir "/path/to/file.txt")  # "/path/to"
grandparent=$(get_parent_dir_n "/path/to/file.txt" 2)  # "/path"

# Path manipulation
relative_path="../config/settings.json"
absolute_path=$(to_absolute_path "$relative_path")
config_path=$(path_relative_to_script "config/settings.json")

# Source related files
source_relative "../lib/common.sh"
source_with_fallbacks "utils.sh" "../common/utils.sh" "/opt/utils.sh"
```

#### System and Environment

```bash
# OS detection
os_type=$(get_os)  # "linux", "mac", "windows"
if [[ "$os_type" == "linux" ]]; then
  distro=$(get_linux_distro)  # "ubuntu", "debian", "centos", etc.
fi

# Architecture
arch=$(get_arch)  # "amd64", "arm64", etc.

# Environment variables
api_key=$(env_or_default "API_KEY" "default-key")

# Network information
my_ip=$(get_external_ip)
if is_url_reachable "https://api.example.com" 3; then
  msg_success "API is reachable"
fi

# Check if ports are open
if is_port_open "db.example.com" 5432 2; then
  msg_success "Database is available"
fi
```

#### Error Handling and Process Management

```bash
# Enable automatic error trapping (already done in sh-globals_init)
setup_traps

# Get script execution details
current_line=$(get_line_number)

# Script locking to prevent multiple instances
if ! create_lock "/var/run/myscript.lock"; then
  msg_error "Another instance is already running"
  exit 1
fi

# When done (automatically handled by traps, but can be manual)
release_lock

# Check dependencies before starting
if ! check_dependencies docker kubectl helm; then
  msg_error "Please install missing dependencies"
  exit 1
fi

# Privilege checks
if ! is_root; then
  msg_error "This script must be run as root"
  exit 1
fi
# Or more directly:
require_root
```

### Advanced Usage Patterns

#### Complete Error Handling Example

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

#### Temporary File Management Pattern

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

### Tips for Effective Use

1. **Always initialize**: Call `sh-globals_init "$@"` at the beginning of your script to set up traps and other features.

2. **Prefer msg_* over echo**: Use `msg_info`, `msg_error`, etc. instead of direct echo commands for consistent, colorized output.

3. **Use log_* for persistent logs**: When you need to track script execution over time, initialize logging with `log_init` and use the `log_*` functions.

4. **Let error handling work for you**: The library sets up error trapping automatically. Let errors propagate naturally and rely on the cleanup functions.

5. **Leverage temporary resource creation**: Use `create_temp_file` and `create_temp_dir` to get auto-cleaned temporary resources.

6. **Build on validation functions**: Compose complex validation by combining the `get_*` input functions with custom validators.

#### Human-Readable Formatting

```bash
# Format numbers with SI prefixes
num_users=$(format_si_number 8543210)       # "8.5M"
small_value=$(format_si_number 0.00045 3)   # "450.0μ"

# Format bytes with appropriate units
file_size=$(format_bytes 2684354560)        # "2.5GB" 
small_size=$(format_bytes 1536)             # "1.5KB"

# Display large sets of data with human-readable sizes
for file in /var/log/*.log; do
  size=$(stat -c %s "$file")
  h_size=$(format_bytes "$size")
  printf "%-30s %10s\n" "$file" "$h_size"
done
```

### Complete Function Reference

Below is a comprehensive listing of all functions available in sh-globals.sh:

#### Script Information Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get_script_dir` | Get the directory containing the script | None | Script directory path |
| `get_script_name` | Get the filename of the script | None | Script filename |
| `get_script_path` | Get the full path to the script | None | Full script path |
| `get_line_number` | Get the current line number | None | Current line number |

#### Logging Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `log_init` | Initialize logging system | `[file_path]` `[save_to_file=1]` | None |
| `log_info` | Log informational message | `message...` | None |
| `log_warn` | Log warning message | `message...` | None |
| `log_error` | Log error message | `message...` | None |
| `log_debug` | Log debug message (only if DEBUG=1) | `message...` | None |
| `log_success` | Log success message | `message...` | None |
| `log_with_timestamp` | Log with custom level | `level` `message...` | None |

#### String Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `str_contains` | Check if string contains substring | `string` `substring` | Boolean (exit code) |
| `str_starts_with` | Check if string starts with prefix | `string` `prefix` | Boolean (exit code) |
| `str_ends_with` | Check if string ends with suffix | `string` `suffix` | Boolean (exit code) |
| `str_trim` | Trim whitespace from string | `string` | Trimmed string |
| `str_to_upper` | Convert string to uppercase | `string` | Uppercase string |
| `str_to_lower` | Convert string to lowercase | `string` | Lowercase string |
| `str_length` | Get string length | `string` | Length (integer) |
| `str_replace` | Replace substring in string | `string` `search` `replace` | Modified string |

#### Array Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `array_contains` | Check if array contains element | `element` `array...` | Boolean (exit code) |
| `array_join` | Join array elements with delimiter | `delimiter` `array...` | Joined string |
| `array_length` | Get array length | `array_name` | Length (integer) |

#### File & Directory Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `command_exists` | Check if command exists | `command` | Boolean (exit code) |
| `safe_mkdir` | Create directory if it doesn't exist | `directory` | None |
| `file_exists` | Check if file exists and is readable | `path` | Boolean (exit code) |
| `dir_exists` | Check if directory exists | `path` | Boolean (exit code) |
| `file_size` | Get file size in bytes | `path` | Size (bytes) |
| `safe_copy` | Copy file with verification | `src` `dst` | Boolean (exit code) |
| `create_temp_file` | Create a temp file (auto-cleaned) | `[template]` | Temp file path |
| `create_temp_dir` | Create a temp directory (auto-cleaned) | `[template]` | Temp dir path |
| `wait_for_file` | Wait for a file to exist | `file` `[timeout=30]` `[interval=1]` | Boolean (exit code) |
| `get_file_extension` | Get file extension | `filename` | Extension (no dot) |
| `get_file_basename` | Get filename without extension | `filename` | Base filename |
| `cleanup_temp` | Clean up temporary files/dirs | None | None |

#### User Interaction Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `confirm` | Confirm prompt (y/n) | `[prompt]` `[default=n]` | Boolean (exit code) |
| `prompt_input` | Prompt for input with default value | `prompt` `[default]` | User input |
| `prompt_password` | Prompt for password (hidden input) | `[prompt]` | Password string |
| `get_number` | Get a validated numeric input | `[prompt]` `[default]` `[min]` `[max]` | Number |
| `get_string` | Get string with validation | `[prompt]` `[default]` `[pattern]` `[error_msg]` | String |
| `get_path` | Get file/directory path | `[prompt]` `[default]` `[type]` `[must_exist=0]` | Path |
| `get_value` | Get value with custom validation | `[prompt]` `[default]` `[validator_func]` `[error_msg]` | Validated value |

#### System & Environment Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `env_or_default` | Get env var or default | `var_name` `[default]` | Value |
| `is_root` | Check if script is run as root | None | Boolean (exit code) |
| `require_root` | Exit if not running as root | None | None (exits if not root) |
| `parse_flags` | Parse command flags | `args...` | None (sets variables) |
| `get_current_user` | Get current username | None | Username |
| `get_hostname` | Get hostname | None | Hostname |

#### OS Detection Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get_os` | Get OS type | None | OS string (linux, mac, windows) |
| `get_linux_distro` | Get Linux distribution name | None | Distro name |
| `get_arch` | Get processor architecture | None | Architecture |
| `is_in_container` | Check if running in a container | None | Boolean (exit code) |

#### Date & Time Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get_timestamp` | Get current timestamp in seconds | None | Timestamp |
| `format_date` | Format date | `[format=%Y-%m-%d]` `[timestamp=now]` | Formatted date string |
| `time_diff_human` | Human-readable time difference | `start` `[end=now]` | Formatted time string |

#### Networking Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `is_url_reachable` | Check if URL is reachable | `url` `[timeout=5]` | Boolean (exit code) |
| `get_external_ip` | Get external IP address | None | IP address |
| `is_port_open` | Check if port is open | `host` `port` `[timeout=2]` | Boolean (exit code) |

#### Script Lock Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `create_lock` | Create lock file | `[lock_file]` | Boolean (exit code) |
| `release_lock` | Release the lock file | None | None |

#### Error Handling Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `print_stack_trace` | Print stack trace | None | None |
| `error_handler` | Error trap handler | `exit_code` `line_number` | None |
| `setup_traps` | Setup trap handlers | None | None |

#### Dependency Management

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `check_dependencies` | Check if required commands exist | `commands...` | Boolean (exit code) |

#### Number Formatting Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `format_si_number` | Format number with SI prefixes | `number` `[precision=1]` | Formatted string |
| `format_bytes` | Format bytes to human-readable size | `bytes` `[precision=1]` | Formatted string |

#### Message Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `msg` | Display a plain message | `message...` | None |
| `msg_info` | Display an informational message | `message...` | None |
| `msg_success` | Display a success message | `message...` | None |
| `msg_warning` | Display a warning message | `message...` | None |
| `msg_error` | Display an error message | `message...` | None |
| `msg_highlight` | Display a highlighted message | `message...` | None |
| `msg_header` | Display a header message | `message...` | None |
| `msg_section` | Display a section divider | `[text]` `[width=80]` `[char=]` | None |
| `msg_subtle` | Display a subtle/dim message | `message...` | None |
| `msg_color` | Display with custom color | `message` `color` | None |
| `msg_step` | Display a step/progress message | `step` `total` `description` | None |
| `msg_debug` | Display debug message (if DEBUG=1) | `message...` | None |

#### Path Navigation Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get_parent_dir` | Get parent directory of a path | `[path=pwd]` | Parent directory path |
| `get_parent_dir_n` | Get parent directory N levels up | `[path=pwd]` `[levels=1]` | Path N levels up |
| `path_relative_to_script` | Make a path relative to script | `relative_path` | Absolute path |
| `to_absolute_path` | Convert relative path to absolute path | `path` `[base_dir=pwd]` | Absolute path |
| `source_relative` | Source a file relative to calling script | `relative_path` | Boolean (exit code) |
| `source_with_fallbacks` | Source file with fallback paths | `filename` `[fallback_paths...]` | Boolean (exit code) |
| `parent_path` | Create a path with n parent references | `[levels=1]` | Path string (e.g., "../../") |

## Library 2: param_handler.sh

The `param_handler.sh` library simplifies handling both named and positional command-line parameters in shell scripts.

### Key Features

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

### Quick Start

```bash
#!/usr/bin/bash
source param_handler.sh

# Define parameters in a single associative array
declare -A PARAMS=(
    # Basic format: internal_name:VARIABLE_NAME
    ["name:NAME"]="Person's name"  # Creates $NAME and --name option
    
    # Basic format: internal_name:VARIABLE_NAME
    ["age:AGE"]="Person's age"     # Creates $AGE and --age option
    
    # Extended format: internal_name:VARIABLE_NAME:option_name
    ["location:LOCATION:place"]="Person's location"  # Creates $LOCATION and --place option
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
declare -A PARAMS=(
    ["internal_name:VARIABLE_NAME"]="Description"
)
```

#### Extended Format with Custom Option Name

```bash
declare -A PARAMS=(
    ["internal_name:VARIABLE_NAME:option_name"]="Description"
)
```

#### Required Parameter Format

```bash
declare -A PARAMS=(
    ["internal_name:VARIABLE_NAME:option_name:REQUIRE"]="Description (required)"
)
```

#### Required Parameter with Validator Function

```bash
declare -A PARAMS=(
    ["internal_name:VARIABLE_NAME:option_name:REQUIRE:validator_function"]="Description (required with validation)"
)
```

#### Format Components

1. **Key Format**: `"internal_name:VARIABLE_NAME[:option_name[:REQUIRE[:validator_function]]]"`
   - `internal_name`: Used internally by the library (e.g., "user", "server")
   - `VARIABLE_NAME`: The actual variable name in your script (e.g., "USERNAME", "SERVER_ADDRESS")
   - `option_name`: (Optional) Custom name for the command-line option
   - `REQUIRE`: (Optional) Mark parameter as required
   - `validator_function`: (Optional) Function name to validate input

2. **Value**: The description shown in help messages

### Parameter Validation

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

### Accessing Parameter Values

After using `param_handler::simple_handle`, you can access your parameters in several ways:

#### 1. Direct Variable Access

```bash
# Access variables directly
if [[ -n "$USERNAME" ]]; then
    echo "Username is set to: $USERNAME"
else
    echo "Username is not set"
fi
```

#### 2. Check How Parameters Were Set

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

#### 3. Get Parameter Values Programmatically

```bash
# Get parameter value
server_address=$(param_handler::get_param "server")
echo "Server address: $server_address"
```

#### 4. Print All Parameters

```bash
# Print all parameters with their values and sources
param_handler::print_params_extended
```

### Core Functions Reference

#### Simple API (Recommended)

| Function | Description | Sample |
|----------|-------------|--------|
| `param_handler::simple_handle [params_array] [args...]` | Process parameters in one step | `param_handler::simple_handle PARAMS "$@"` |
| `param_handler::get_param [param_name]` | Get parameter value | `value=$(param_handler::get_param "name")` |
| `param_handler::was_set_by_name [param_name]` | Check if set by name | `if param_handler::was_set_by_name "server"; then echo "Set via --server-address option"; fi` |
| `param_handler::was_set_by_position [param_name]` | Check if set by position | `if param_handler::was_set_by_position "user"; then echo "Set positionally"; fi` |
| `param_handler::print_params` | Display parameter values | `param_handler::print_params # Show all param values` |
| `param_handler::print_help` | Display help message | `param_handler::print_help # Show help message` |
| `param_handler::export_params [--format type] [--prefix prefix]` | Export parameters | `param_handler::export_params --format json` |

#### Display Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `param_handler::print_params` | Basic parameter values display | `param_handler::print_params` |
| `param_handler::print_params_extended` | Display with source information | `param_handler::print_params_extended` |
| `param_handler::print_summary` | Summary of parameter counts | `param_handler::print_summary` |
| `param_handler::print_help` | Help message | `param_handler::print_help` |

#### Export Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `param_handler::export_params --prefix [prefix]` | Export to environment variables | `param_handler::export_params --prefix "APP_"` |
| `param_handler::export_params --format json` | Export as JSON | `param_handler::export_params --format json` |

## Examples

### Example 1: Basic Script with Logging and Parameters

```bash
#!/usr/bin/env bash

# Source the libraries
source "$(dirname "$0")/sh-globals.sh"
source "$(dirname "$0")/param_handler.sh"

# Initialize sh-globals
sh-globals_init "$@"

# Initialize logging
log_init

# Define parameters
declare -A PARAMS=(
    ["server:SERVER"]="Server address"
    ["port:PORT"]="Server port"
    ["user:USERNAME"]="Username for authentication"
)

# Process parameters
if ! param_handler::simple_handle PARAMS "$@"; then
    exit 0  # Help was shown, exit successfully
fi

# Log parameter values
log_info "Server: $SERVER"
log_info "Port: $PORT"
log_info "Username: $USERNAME"

# Check dependencies
if ! check_dependencies curl jq; then
    log_error "Missing required dependencies"
    exit 1
fi

# Create lock to prevent multiple instances
if ! create_lock; then
    log_error "Script already running"
    exit 1
fi

# Check if server is reachable
if is_url_reachable "$SERVER" 5; then
    log_success "Server is reachable"
else
    log_error "Cannot reach server $SERVER"
    exit 1
fi

# Print summary
log_success "Script completed successfully"
```

### Example 2: User Interaction with Parameter Handling

```bash
#!/usr/bin/env bash

# Source the libraries
source "$(dirname "$0")/sh-globals.sh"
source "$(dirname "$0")/param_handler.sh"

# Initialize sh-globals
sh-globals_init "$@"

# Define parameters
declare -A PARAMS=(
    ["name:NAME"]="User's name"
    ["action:ACTION"]="Action to perform (create, update, delete)"
)

# Process parameters
if ! param_handler::simple_handle PARAMS "$@"; then
    exit 0  # Help was shown, exit successfully
fi

# If name not provided, prompt for it
if [[ -z "$NAME" ]]; then
    NAME=$(prompt_input "Enter your name" "guest")
fi

# If action not provided, confirm with user
if [[ -z "$ACTION" ]]; then
    if confirm "Do you want to create a new record?" "y"; then
        ACTION="create"
    else
        ACTION="update"
    fi
fi

# Display parameter values
msg_header "Operation Details"
msg_info "Name: $NAME"
msg_info "Action: $ACTION"

# Perform action based on parameter
case "$ACTION" in
    create)
        msg_success "Created new record for $NAME"
        ;;
    update)
        msg_success "Updated record for $NAME"
        ;;
    delete)
        if confirm "Are you sure you want to delete $NAME?" "n"; then
            msg_success "Deleted record for $NAME"
        else
            msg_warning "Deletion cancelled"
        fi
        ;;
    *)
        msg_error "Unknown action: $ACTION"
        exit 1
        ;;
esac
```

### Example 3: Using Path Navigation Functions

```bash
#!/usr/bin/env bash

# Source the utilities
source "$(dirname "$0")/sh-globals.sh"
sh-globals_init "$@"

# Get script location information
script_dir=$(get_script_dir)
script_name=$(get_script_name)
log_info "Running script: $script_name in $script_dir"

# Using path navigation functions
config_dir=$(get_parent_dir "$script_dir")
log_info "Config directory (parent): $config_dir"

project_root=$(get_parent_dir_n "$script_dir" 2)
log_info "Project root (2 levels up): $project_root"

# Source a library relative to the script
source_relative "../lib/helpers.sh"

# Convert a relative path to absolute
data_path=$(to_absolute_path "../data" "$script_dir")
log_info "Data path: $data_path"

# Create paths with parent references
parent_ref=$(parent_path 3)  # Returns "../../../"
log_info "Parent reference: $parent_ref"

# Download a configuration file to a path relative to the script
config_path=$(path_relative_to_script "config/settings.json")
log_info "Will save config to: $config_path"

# Make sure the directory exists
safe_mkdir "$(dirname "$config_path")"

# Source a utility file with fallbacks
source_with_fallbacks "utils.sh" "../common/utils.sh" "/opt/utils.sh"
```

### Example 4: Required Parameters with Validation

```bash
#!/usr/bin/bash

# Source the libraries
source "$(dirname "$0")/sh-globals.sh"
source "$(dirname "$0")/param_handler.sh"

# Initialize sh-globals
sh-globals_init "$@"

# Define validator functions
# These functions should return 0 for valid input, non-zero for invalid
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
declare -A PARAMS=(
    # Optional parameter (standard)
    ["name:NAME"]="Person's name"
    
    # Required parameter with validator
    ["age:AGE:age:REQUIRE:validate_age"]="Person's age (required, 1-120)"
    
    # Required parameter with custom option name and validator
    ["email:EMAIL:email-address:REQUIRE:validate_email"]="Email address (required)"
    
    # Optional parameter with custom option name
    ["location:LOCATION:place"]="Person's location"
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

if param_handler::was_set_by_name "email"; then
    msg_success "Email was provided via --email-address option"
elif param_handler::was_set_by_position "email"; then
    msg_highlight "Email was provided as a positional parameter"
else
    msg_warning "Email was provided via prompt (required parameter)"
fi

# Display parameter details
param_handler::print_params_extended
```

## Testing Framework

A lightweight test framework for shell scripts is included in the `tests` directory. It provides simple test organization, assertions, and test running capabilities.

### Key Features

- Easy test organization with groups
- Support for both command-based and function-based tests
- Interactive and non-interactive test modes
- Basic assertion utilities
- Colorized output for better readability

### Basic Usage

1. Create a test file for your shell script/library
2. Source the test framework
3. Define and run your tests

```bash
#!/usr/bin/env bash
# test-example.sh

# Source the test framework
source "./test-framework.sh"

# Source the library under test
source_library "../your-script.sh"

# Define a test group
test_group "String Functions"

# Simple test with function
test "should work correctly" test_function_name

test_function_name() {
  # Your test code
  assert_eq "expected" "actual"
}

# Command-based test
run_test "file check" "[ -f '../your-script.sh' ]"
```

Execute tests using the test runner:

```bash
./test-runner.sh
```

See the [Test Framework README](tests/README.md) for complete documentation on available functions and examples.

## License

This utility is provided as open source. Feel free to use and modify as needed.

- **sh-globals.sh**: MIT License
- **param_handler.sh**: MIT License
- **getoptions.sh**: Creative Commons Zero v1.0 Universal 