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
sh-globals:init "$@"
```

## Dependencies

The `param_handler.sh` library depends on [getoptions](https://github.com/ko1nksm/getoptions), a powerful command-line argument parser for shell scripts.

- **Repository**: [ko1nksm/getoptions](https://github.com/ko1nksm/getoptions)
- **License**: [Creative Commons Zero v1.0 Universal](https://github.com/ko1nksm/getoptions/blob/master/LICENSE)
- **Version**: v3.3.2 (included in this project)

## Library 1: sh-globals.sh

### Key Features

- Color and formatting for terminal output
- Script information utilities
- Logging functions with file output support
- String manipulation functions
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
- Number Formatting Functions
- Path navigation functions

### Basic Usage

```bash
#!/usr/bin/env bash

# Source the utilities
source "$(dirname "$0")/sh-globals.sh"
sh-globals:init "$@"

# Initialize logging with defaults (uses script_name.log in current directory)
log_init

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

### Function Reference

#### Color and Formatting

| Variable | Description | Sample |
|----------|-------------|--------|
| `BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, GRAY` | Text colors | `echo -e "${RED}Error message${NC}"` |
| `BG_BLACK, BG_RED, BG_GREEN, BG_YELLOW, BG_BLUE, BG_MAGENTA, BG_CYAN, BG_WHITE` | Background colors | `echo -e "${BG_BLUE}${WHITE}Highlighted text${NC}"` |
| `BOLD, DIM, UNDERLINE, BLINK, REVERSE, HIDDEN` | Text formatting | `echo -e "${BOLD}Important note${NC}"` |
| `NC` | Reset color/formatting | `echo -e "${RED}Error:${NC} Something went wrong"` |

#### Script Information

| Function | Description | Sample |
|----------|-------------|--------|
| `get_script_dir` | Get the directory of the current script | `script_dir=$(get_script_dir)` |
| `get_script_name` | Get the name of the current script without path | `echo "Running $(get_script_name)"` |
| `get_script_path` | Get the absolute path of the current script | `script_path=$(get_script_path)` |
| `get_line_number` | Get the current line number in the script | `echo "Error at line $(get_line_number)"` |

#### Logging Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `log_init [log_file] [save_to_file]` | Initialize logging (both parameters optional) | `log_init "/var/log/myscript.log" 1` |
| `log_info [message]` | Log info message | `log_info "Starting database backup"` |
| `log_warn [message]` | Log warning message | `log_warn "Disk space below 20%"` |
| `log_error [message]` | Log error message | `log_error "Failed to connect to server"` |
| `log_debug [message]` | Log debug message (only if DEBUG=1) | `log_debug "Value of x: $x"` |
| `log_success [message]` | Log success message | `log_success "Backup completed"` |
| `log_with_timestamp [level] [message]` | Log with timestamp | `log_with_timestamp "INFO" "Server restarted"` |

#### String Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `str_contains [string] [substring]` | Check if string contains substring | `if str_contains "$output" "error"; then echo "Error found"; fi` |
| `str_starts_with [string] [prefix]` | Check if string starts with prefix | `if str_starts_with "$line" "#"; then echo "Comment line"; fi` |
| `str_ends_with [string] [suffix]` | Check if string ends with suffix | `if str_ends_with "$file" ".txt"; then echo "Text file"; fi` |
| `str_trim [string]` | Trim whitespace from string | `username=$(str_trim "$user_input")` |
| `str_to_upper [string]` | Convert string to uppercase | `upper_code=$(str_to_upper "$country_code")` |
| `str_to_lower [string]` | Convert string to lowercase | `email=$(str_to_lower "$email_input")` |
| `str_length [string]` | Get string length | `if [ $(str_length "$password") -lt 8 ]; then echo "Password too short"; fi` |
| `str_replace [string] [search] [replace]` | Replace all occurrences in string | `path=$(str_replace "$path" "\\" "/")` |

#### Array Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `array_contains [element] [array...]` | Check if array contains element | `if array_contains "apple" "${fruits[@]}"; then echo "Has apple"; fi` |
| `array_join [delimiter] [array...]` | Join array elements with delimiter | `csv=$(array_join "," "${items[@]}")` |
| `array_length [array_name]` | Get array length | `count=$(array_length my_array)` |

#### File & Directory Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `command_exists [command]` | Check if a command exists | `if ! command_exists "docker"; then echo "Docker not installed"; fi` |
| `safe_mkdir [directory]` | Create directory if it doesn't exist | `safe_mkdir "/var/data/app"` |
| `file_exists [path]` | Check if file exists and is readable | `if ! file_exists "config.json"; then echo "Config missing"; fi` |
| `dir_exists [path]` | Check if directory exists | `if dir_exists "backup"; then echo "Backup dir exists"; fi` |
| `file_size [path]` | Get file size in bytes | `size=$(file_size "data.log")` |
| `safe_copy [src] [dst]` | Copy file with verification | `safe_copy "source.txt" "backup/source.txt"` |
| `create_temp_file [template]` | Create a temp file (auto-cleaned) | `temp=$(create_temp_file); echo "data" > "$temp"` |
| `create_temp_dir [template]` | Create a temp directory (auto-cleaned) | `temp_dir=$(create_temp_dir); cp data/* "$temp_dir/"` |
| `wait_for_file [file] [timeout] [interval]` | Wait for a file to exist | `if wait_for_file "output.txt" 10 1; then cat output.txt; fi` |
| `get_file_extension [filename]` | Get file extension | `ext=$(get_file_extension "$filename")` |
| `get_file_basename [filename]` | Get filename without extension | `base=$(get_file_basename "document.pdf")` |

#### User Interaction Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `confirm [prompt] [default]` | Confirm prompt (y/n) | `if confirm "Delete all files?" "n"; then rm -rf *; fi` |
| `prompt_input [prompt] [default]` | Prompt for input with default value | `name=$(prompt_input "Enter your name" "guest")` |
| `prompt_password [prompt]` | Prompt for password (hidden input) | `pass=$(prompt_password "Enter password")` |

#### System & Environment Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `env_or_default [var_name] [default]` | Get env var or default | `db_host=$(env_or_default "DB_HOST" "localhost")` |
| `is_root` | Check if script is run as root | `if ! is_root; then echo "Run as root"; exit 1; fi` |
| `require_root` | Exit if not running as root | `require_root # Script will exit if not root` |
| `parse_flags [args...]` | Parse common command flags | `parse_flags "--debug" "--verbose"` |
| `get_current_user` | Get current username | `user=$(get_current_user)` |
| `get_hostname` | Get hostname | `host=$(get_hostname)` |

#### OS Detection Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `get_os` | Get OS type (linux, mac, windows) | `os=$(get_os); if [ "$os" = "mac" ]; then echo "On Mac"; fi` |
| `get_linux_distro` | Get Linux distribution name | `if [ "$(get_linux_distro)" = "ubuntu" ]; then apt update; fi` |
| `get_arch` | Get processor architecture | `arch=$(get_arch)` |
| `is_in_container` | Check if running in a container | `if is_in_container; then echo "In container"; fi` |

#### Date & Time Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `get_timestamp` | Get current timestamp in seconds | `start=$(get_timestamp)` |
| `format_date [format] [timestamp]` | Format date | `today=$(format_date "%Y-%m-%d")` |
| `time_diff_human [start] [end]` | Human-readable time difference | `duration=$(time_diff_human "$start_time" "$end_time")` |

#### Networking Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `is_url_reachable [url] [timeout]` | Check if URL is reachable | `if is_url_reachable "https://example.com" 3; then echo "Site up"; fi` |
| `get_external_ip` | Get external IP address | `my_ip=$(get_external_ip)` |
| `is_port_open [host] [port] [timeout]` | Check if port is open | `if is_port_open "db.example.com" 3306 2; then echo "DB reachable"; fi` |

#### Script Lock Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `create_lock [lock_file]` | Create lock file to prevent multiple instances | `if ! create_lock "/tmp/myapp.lock"; then exit 1; fi` |
| `release_lock` | Release the lock file | `release_lock # Release before exiting conditionally` |

#### Error Handling Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `print_stack_trace` | Print stack trace | `print_stack_trace # Print current stack trace` |
| `error_handler [exit_code] [line_number]` | Error trap handler | `trap 'error_handler $? $LINENO' ERR` |
| `setup_traps` | Setup trap handlers | `setup_traps # Already called in sh-globals:init` |

#### Dependency Management

| Function | Description | Sample |
|----------|-------------|--------|
| `check_dependencies [cmd...]` | Check if required commands exist | `check_dependencies curl jq docker || exit 1` |

#### Number Formatting Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `format_si_number [number] [precision]` | Format number with SI prefixes (K, M, G, T, P) | `echo "$(format_si_number 1500000) users"` |
| `format_bytes [bytes] [precision]` | Format bytes to human-readable size (KB, MB, GB, TB) | `echo "Size: $(format_bytes 1073741824)"` |

#### Message Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `msg [message]` | Display a plain message | `msg "Processing file..."` |
| `msg_info [message]` | Display an informational message (blue) | `msg_info "Loading configuration"` |
| `msg_success [message]` | Display a success message (green) | `msg_success "Files transferred successfully"` |
| `msg_warning [message]` | Display a warning message (yellow) to stderr | `msg_warning "Low disk space"` |
| `msg_error [message]` | Display an error message (red) to stderr | `msg_error "Failed to connect to server"` |
| `msg_highlight [message]` | Display a highlighted message (cyan) | `msg_highlight "Important note"` |
| `msg_header [message]` | Display a header message (bold, magenta) | `msg_header "INSTALLATION"` |
| `msg_section [text] [width] [char]` | Display a section divider with text | `msg_section "Configuration" 50 "-"` |
| `msg_subtle [message]` | Display a subtle/dim message (gray) | `msg_subtle "Hint: use --help for options"` |
| `msg_color [message] [color]` | Display a message with custom color | `msg_color "Custom message" "$MAGENTA"` |
| `msg_step [step] [total] [description]` | Display a step or progress message | `msg_step 2 5 "Installing dependencies"` |
| `msg_debug [message]` | Display debug message only when DEBUG=1 | `msg_debug "Variable x = $x"` |

#### Get Value Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `get_number [prompt] [default] [min] [max]` | Get a validated numeric input | `age=$(get_number "Enter age" "30" "18" "100")` |
| `get_string [prompt] [default] [pattern] [error_msg]` | Get string with optional regex validation | `email=$(get_string "Email" "" "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "Invalid email")` |
| `get_path [prompt] [default] [type] [must_exist]` | Get file/directory path with validation | `config=$(get_path "Config file" "./config.json" "file" "1")` |
| `get_value [prompt] [default] [validator_func] [error_msg]` | Get value with custom validation function | `hostname=$(get_value "Hostname" "localhost" is_valid_hostname "Invalid hostname")` |

#### Path Navigation Functions

| Function | Description | Sample |
|----------|-------------|--------|
| `get_parent_dir [path]` | Get parent directory of a path | `parent=$(get_parent_dir "/path/to/file.txt")` |
| `get_parent_dir_n [path] [levels]` | Get parent directory N levels up | `grandparent=$(get_parent_dir_n "/path/to/file.txt" 2)` |
| `path_relative_to_script [relative_path]` | Make a path relative to script location | `config=$(path_relative_to_script "../config.json")` |
| `to_absolute_path [path] [base_dir]` | Convert relative path to absolute path | `abs_path=$(to_absolute_path "../logs" "/var/app")` |
| `source_relative [relative_path]` | Source a file relative to the calling script | `source_relative "../lib/common.sh"` |
| `source_with_fallbacks [filename] [fallback_paths...]` | Source file with fallback paths | `source_with_fallbacks "utils.sh" "../common/utils.sh" "/opt/utils.sh"` |
| `parent_path [levels]` | Create a path with n parent directory references | `path_prefix=$(parent_path 2) # Returns "../../"` |

## Library 2: param_handler.sh

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
| `param_handler::was_set_by_name [param_name]` | Check if set by name | `if param_handler::was_set_by_name "server"; then echo "Set via --server"; fi` |
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
sh-globals:init "$@"

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
sh-globals:init "$@"

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
sh-globals:init "$@"

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
sh-globals:init "$@"

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