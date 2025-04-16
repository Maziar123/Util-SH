#!/usr/bin/bash
# test-param-handler-format-manual.sh - Format tests for manual registration API

# Source the library
source "$(dirname "$0")/../param_handler.sh"

# Define a function to create a clean environment for each test
setup_test() {
    local test_name="$1"
    echo -e "\n\e[1m$test_name\e[0m"
    
    # Clear environment
    param_handler::init
    
    # Setup basic parameters
    param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
    param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
    param_handler::register_param "email" "TEST_EMAIL" "email" "Email address"
    
    # Generate parser
    source <(param_handler::generate_parser_definition)
    source <(getoptions param_handler::parser_definition parse)
    
    # Set default values
    TEST_NAME="John Doe"
    TEST_AGE="30"
    TEST_EMAIL="john.doe@example.com"
}

# Test 1: JSON Export Format
setup_test "TEST 1: JSON Export Format"
# Parse some arguments to set parameters
param_handler::parse_args --name "Alice Smith" --age "25" --email "alice@example.com"

# Test JSON export
echo "JSON Export:"
param_handler::export_params --format json

# Test JSON export with prefix
echo -e "\nJSON Export with prefix:"
param_handler::export_params --format json --prefix "USER_"

# Test 2: Environment Export
setup_test "TEST 2: Environment Export Format"
# Parse some arguments to set parameters
param_handler::parse_args --name "Bob Johnson" --age "40" --email "bob@example.com"

# Test environment export
echo "Environment Export:"
param_handler::export_params
echo "Exported variables:"
echo "TEST_NAME=$TEST_NAME"
echo "TEST_AGE=$TEST_AGE"
echo "TEST_EMAIL=$TEST_EMAIL"

# Test environment export with prefix
echo -e "\nEnvironment Export with prefix:"
param_handler::export_params --prefix "USER_"
echo "Exported variables with prefix:"
echo "USER_TEST_NAME=$USER_TEST_NAME"
echo "USER_TEST_AGE=$USER_TEST_AGE"
echo "USER_TEST_EMAIL=$USER_TEST_EMAIL"

# Test 3: Parameter Summary Display
setup_test "TEST 3: Parameter Summary Display"
# Parse mixed parameters
param_handler::parse_args --name "Charlie Wilson" "45" --email "charlie@example.com"

# Standard parameter display
echo "Standard Parameter Display:"
param_handler::print_params

# Extended parameter display with colors
echo -e "\nExtended Parameter Display:"
param_handler::print_params_extended

# Just the summary
echo -e "\nParameter Summary:"
param_handler::print_summary

# Test 4: Parameter Access Methods
setup_test "TEST 4: Parameter Access Methods"
# Parse parameters
param_handler::parse_args --name "Diana Brown" --age "35" --email "diana@example.com"

# Test getting parameter values
echo "Getting parameter values using param_handler::get_param:"
echo "Name: $(param_handler::get_param "name")"
echo "Age: $(param_handler::get_param "age")"
echo "Email: $(param_handler::get_param "email")"

# Test checking if parameters were set by name
echo -e "\nChecking if parameters were set by name:"
if param_handler::was_set_by_name "name"; then echo "Name was set by name"; else echo "Name was not set by name"; fi
if param_handler::was_set_by_name "age"; then echo "Age was set by name"; else echo "Age was not set by name"; fi
if param_handler::was_set_by_name "email"; then echo "Email was set by name"; else echo "Email was not set by name"; fi

# Test 5: Parameter Types
setup_test "TEST 5: Parameter Types (Manual)"

# Define different data types
TEST_STRING=""
TEST_NUMBER=""
TEST_BOOLEAN=""
TEST_PATH=""
TEST_CSV=""

# Register parameters
param_handler::register_param "string" "TEST_STRING" "string" "Text data"
param_handler::register_param "number" "TEST_NUMBER" "number" "Numeric data"
param_handler::register_param "boolean" "TEST_BOOLEAN" "boolean" "True/false value"
param_handler::register_param "path" "TEST_PATH" "path" "File system path"
param_handler::register_param "csv" "TEST_CSV" "csv" "Comma-separated values"

# Generate parser
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Parse parameters with different types
param_handler::parse_args --string "Hello, World!" \
                          --number "42" \
                          --boolean "true" \
                          --path "/home/user/documents" \
                          --csv "apple,banana,cherry"

# Display results
echo "Parameter types test results:"
param_handler::print_params

# Export as JSON
echo -e "\nJSON export with different data types:"
param_handler::export_params --format json
