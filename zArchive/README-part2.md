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
    "age:AGE:age:Person's age:REQUIRE:validate_age"
    "email:EMAIL:email-address:Email address:REQUIRE:validate_email"
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

# Combined Usage Example

This example demonstrates how to use both libraries together:

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
declare -a PARAMS=(
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

## License

These utilities are provided as open source under the MIT License. Feel free to use and modify as needed. 