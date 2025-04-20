# 🛠️ ParamHandler - Bash CLI Parameter Handling Library

[![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-0052CC)](CHANGELOG.md)

A lightweight Bash library for handling both named and positional command-line parameters in shell scripts. ParamHandler simplifies argument parsing, parameter validation, and provides an easy-to-use interface for accessing parameter values.

## 🔗 Dependencies

This library depends on [getoptions](https://github.com/ko1nksm/getoptions), a powerful command-line argument parser for shell scripts.

### About getoptions

- **Repository**: [ko1nksm/getoptions](https://github.com/ko1nksm/getoptions)
- **License**: [Creative Commons Zero v1.0 Universal](https://github.com/ko1nksm/getoptions/blob/master/LICENSE)
- **Version**: v3.3.2 (included in this project)

getoptions is a high-performance command-line argument parser that provides:

- POSIX-compliant shell script argument parsing
- Support for both short and long options
- Automatic help message generation
- Type validation and conversion
- Subcommand support

## 📋 Features

### Core Functionality

- Handle both named (`--option value`) and positional parameters in a single script
- Automatic parameter registration and management
- Built-in help message generation
- Color-coded output for better readability
- Built on the robust [getoptions](https://github.com/ko1nksm/getoptions) library

### Parameter Management

- **Simple API** for quick implementation
- Support for both named and positional parameters
- Automatic parameter source tracking (named vs positional)
- Parameter count tracking
- Parameter value retrieval
- Parameter state checking

### Output and Display

- Color-coded parameter display
- Multiple display formats:
  - Basic parameter values
  - Extended display with source information
  - Parameter summary
  - Help message
- JSON export capability
- Environment variable export with prefix support

### Parameter Configuration

- Indexed array parameter definition format:
  - `"internal_name:VARIABLE_NAME:Description"`
  - `"internal_name:VARIABLE_NAME:option_name:Description"`
  - `"internal_name:VARIABLE_NAME:option_name:Description:REQUIRE"`
- Automatic variable creation
- Parameter description support
- Help message generation

### Error Handling

- Built-in help message display
- Error handling for invalid parameters
- Clear error messages with color coding
- Graceful exit on help request

### Integration Features

- Environment variable export
- JSON format export
- Custom prefix support for exports
- Automatic parameter initialization

## 📦 Requirements

- Bash 4.0+ (for associative arrays)
- [getoptions.sh](../Util-Sh/getoptions.sh) (included in this project)

## 📥 Installation

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

## 🚀 Quick Start

For a super minimal example, see [super_minimal_new.sh](Samples/params_example.sh):

```bash
#!/usr/bin/bash
source param_handler.sh

# Define parameters in an indexed array
# Format: "internal_name:VARIABLE_NAME[:option_name]:Description[:REQUIRE][:getter_func]"
# 
# internal_name: Used internally by the library (lowercase, no special chars)
# VARIABLE_NAME: The actual variable name in your script (uppercase)
# option_name: (Optional) Custom name for the command-line option (lowercase with hyphens)
# Description: Help text shown in help messages
# REQUIRE: (Optional) Mark the parameter as required
# getter_func: (Optional) Function name to validate or prompt for the parameter
#
# Example with all components:
# "user:USERNAME:username:Username for login:REQUIRE:validate_username"
#   - internal_name: "user"
#   - VARIABLE_NAME: "USERNAME"
#   - option_name: "username"
#   - Description: "Username for login"
#   - Creates: $USERNAME variable and --username option
#   - Required: Yes
#   - Validator: validate_username function
#
# Example without option_name:
# "user:USERNAME:Username for login"
#   - internal_name: "user"
#   - VARIABLE_NAME: "USERNAME"
#   - option_name: (uses internal_name "user")
#   - Description: "Username for login"
#   - Creates: $USERNAME variable and --user option
#
declare -a PARAMS=(
    # Basic format: internal_name:VARIABLE_NAME:Description
    "name:NAME:Person's name"
    
    # Basic format: internal_name:VARIABLE_NAME:Description
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

## 📝 PARAMS Array Format

The `PARAMS` array uses a specific format to define parameters. Here's a detailed explanation:

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

### Important Notes

1. The order of parameters in the array determines the order for positional parameters
2. Variable names should be uppercase by convention
3. Option names should be lowercase with hyphens
4. Internal names should be lowercase without special characters
5. All parameters are optional unless specified with REQUIRE

## 🔍 Accessing Parameter Values

After using `param_handler::simple_handle`, you can access your parameters in several ways:

### 1. Direct Variable Access

The simplest way to access parameters is using the variable names you defined:

```bash
# Define parameters
declare -a PARAMS=(
    "user:USERNAME:Username for login"
    "pass:PASSWORD:password:Password for authentication"
    "server:SERVER_ADDRESS:server-address:Server address"
)

# Process parameters
param_handler::simple_handle PARAMS "$@"

# Access variables directly
if [[ -n "$USERNAME" ]]; then
    echo "Username is set to: $USERNAME"
else
    echo "Username is not set"
fi

# Check if server address is set
if [[ -n "$SERVER_ADDRESS" ]]; then
    echo "Connecting to server: $SERVER_ADDRESS"
else
    echo "No server address specified"
fi
```

### 2. Check How Parameters Were Set

You can check if parameters were set by name (--option) or position:

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

You can get parameter values using the library function:

```bash
# Get parameter value
server_address=$(param_handler::get_param "server")
echo "Server address: $server_address"
```

### 4. Print All Parameters

See all parameters and how they were set:

```bash
# Print all parameters with their values and sources
param_handler::print_params_extended
```

### Complete Example

```bash
#!/usr/bin/bash
source param_handler.sh

# Define parameters
declare -a PARAMS=(
    "user:USERNAME:Username for login"
    "pass:PASSWORD:password:Password for authentication"
    "server:SERVER_ADDRESS:server-address:Server address"
)

# Process parameters
param_handler::simple_handle PARAMS "$@"

# 1. Direct variable access
echo "=== Direct Variable Access ==="
echo "Username: ${USERNAME:-not set}"
echo "Password: ${PASSWORD:+set}"  # Shows if set without revealing value
echo "Server: ${SERVER_ADDRESS:-not set}"

# 2. Check how parameters were set
echo -e "\n=== Parameter Source Check ==="
if param_handler::was_set_by_name "server"; then
    echo "Server was set via --server-address option"
elif param_handler::was_set_by_position "server"; then
    echo "Server was set as a positional parameter"
else
    echo "Server was not set"
fi

# 3. Get parameter values programmatically
echo -e "\n=== Programmatic Access ==="
server=$(param_handler::get_param "server")
echo "Server (via get_param): $server"

# 4. Print all parameters
echo -e "\n=== All Parameters ==="
param_handler::print_params_extended
```

### Usage Examples

```bash
# Named parameters
./myscript.sh --name "John" --age "30" --place "New York"

# Positional parameters (in order of declaration)
./myscript.sh "John" "30" "New York"

# Mixed (positional fills in what's not provided by name)
./myscript.sh --age "30" "John" "New York"

# Show help
./myscript.sh --help
```

## 🔍 Parameter Configuration

When defining parameters, you can use these formats:

1. **Simple format**: `"internal_name:VARIABLE_NAME:Description"`
   - The option name will be the same as the internal name
   - Example: `"user:USERNAME:User name"` creates a `--user` option

2. **Custom option format**: `"internal_name:VARIABLE_NAME:option_name:Description"`
   - Specifies a custom option name different from the internal name
   - Example: `"user:USERNAME:username:User name"` creates a `--username` option

3. **Required parameter format**: `"internal_name:VARIABLE_NAME:option_name:Description:REQUIRE"`
   - Marks the parameter as required
   - Example: `"user:USERNAME:username:User name:REQUIRE"` creates a required `--username` option

The parameters are processed in the order they are defined, which is important for positional parameter handling.

## 📊 Displaying Parameter Information

ParamHandler provides several functions to display parameter information:

```bash
# Basic parameter values display
param_handler::print_params

# Extended display with color-coded source information
param_handler::print_params_extended

# Summary of parameter counts
param_handler::print_summary

# Help message
param_handler::print_help
```

## 🔄 Exporting Parameters

You can export parameters to environment variables or as JSON:

```bash
# Export to environment variables with an optional prefix
param_handler::export_params --prefix "MY_APP_"

# Export as JSON
param_handler::export_params --format json
```

## 🎭 Parameter Type Example

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

## 📚 Additional Resources

- [super_minimal_new.sh](Samples/params_example.sh) - A minimal example of param_handler.sh usage
- [param_handler_usage.sh](Samples/param_handler_usage.sh) - Comprehensive example with multiple test cases
- [getoptions.sh](../Util-Sh/getoptions.sh) - The underlying parameter parsing library
- [getoptions GitHub Repository](https://github.com/ko1nksm/getoptions) - The original getoptions library

## 📜 License

MIT License - See [LICENSE](LICENSE) for full text.

## 👥 Contributing

Contributions, bug reports, and feature requests are welcome! Please feel free to submit a pull request or open an issue. 
