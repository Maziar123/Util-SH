#!/usr/bin/env bash
# param_handler_helper.sh - Helper functions for param_handler ShellSpec tests

# Mock for get_value function
get_value() {
  echo "test_default_value"
}

# Helper to clean up test environment
cleanup_test_vars() {
  # Clean global test variables
  unset TEST_NAME TEST_AGE TEST_CITY
}

# Mock log_error function
log_error() {
  echo "ERROR: $*" >&2
}

# Helper to simulate user input
simulate_input() {
  local input="$1"
  echo "$input"
}

# Setup for named parameters only test
setup_named_params() {
  # Initialize
  param_handler::init
  
  # Register parameters
  param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
  param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
  param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
  
  # Generate parser
  eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
  eval "$(getoptions param_handler::parser_definition parse)"
  
  # Parse with named parameters
  param_handler::parse_args --name "John Doe" --age "30" --city "New York"
}

# Setup for positional parameters only test
setup_positional_params() {
  # Reset parameters
  TEST_NAME=""
  TEST_AGE=""
  TEST_CITY=""
  param_handler::init
  
  # Register parameters
  param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
  param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
  param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
  
  # Generate parser
  eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
  eval "$(getoptions param_handler::parser_definition parse)"
  
  # Parse with positional parameters
  param_handler::parse_args "Jane Smith" "25" "Boston"
}

# Setup for mixed parameters test
setup_mixed_params() {
  # Reset parameters
  TEST_NAME=""
  TEST_AGE=""
  TEST_CITY=""
  param_handler::init
  
  # Register parameters
  param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
  param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
  param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
  
  # Generate parser
  eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
  eval "$(getoptions param_handler::parser_definition parse)"
  
  # Parse with mixed parameters
  param_handler::parse_args --name "Alex Johnson" "40" "Seattle"
}

# Setup for simple_handle function test
setup_simple_handle() {
  # Reset parameters
  TEST_NAME=""
  TEST_AGE=""
  TEST_CITY=""
  
  # Define parameters in ordered array
  declare -a TEST_PARAMS=(
    "name:TEST_NAME:name:Person's name"
    "age:TEST_AGE:age:Person's age"
    "city:TEST_CITY:city:Person's city"
  )
  
  # Process parameters using simple_handle
  param_handler::simple_handle TEST_PARAMS --name "Sarah Wilson" --age "35" --city "Denver"
}

# Setup for parameter tracking functions test
setup_tracking_params() {
  # Reset parameters
  TEST_NAME=""
  TEST_AGE=""
  TEST_CITY=""
  param_handler::init
  
  # Register parameters
  param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
  param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
  param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
  
  # Generate parser
  eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
  eval "$(getoptions param_handler::parser_definition parse)"
  
  # Parse with mixed parameters
  param_handler::parse_args --name "Robert Taylor" "33" --city "Dallas"
}

# Setup for custom option names test
setup_custom_options() {
  # Reset parameters
  TEST_NAME=""
  TEST_AGE=""
  TEST_CITY=""
  
  # Define parameters in associative array with custom option names
  declare -A TEST_PARAMS=(
    ["name:TEST_NAME:username"]="Person's name"
    ["age:TEST_AGE:user-age"]="Person's age"
    ["city:TEST_CITY:location"]="Person's city"
  )
  
  # Process parameters using simple_handle
  param_handler::simple_handle TEST_PARAMS --username "Emma Wilson" --user-age "42" --location "Austin"
}

# Setup for parameter type tests with manual API
setup_param_types_manual() {
  # Initialize
  param_handler::init
  
  # Register parameters of different types
  param_handler::register_param "string" "TEST_STRING" "string" "Text data"
  param_handler::register_param "number" "TEST_NUMBER" "number" "Numeric data"
  param_handler::register_param "boolean" "TEST_BOOLEAN" "boolean" "True/false value"
  param_handler::register_param "path" "TEST_PATH" "path" "File system path"
  param_handler::register_param "csv" "TEST_CSV" "csv" "Comma-separated values"
  
  # Generate parser
  eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
  eval "$(getoptions param_handler::parser_definition parse)"
  
  # Parse with different parameter types
  param_handler::parse_args --string "Hello, World!" --number "42" --boolean "true" --path "/home/user/documents" --csv "apple,banana,cherry"
}

# Setup for parameter type tests with simple API
setup_param_types_simple() {
  # Reset parameters
  TEST_STRING=""
  TEST_NUMBER=""
  TEST_BOOLEAN=""
  TEST_PATH=""
  TEST_CSV=""
  
  # Define parameters with different data types
  declare -A TYPE_PARAMS=(
    ["string:TEST_STRING"]="Text data"
    ["number:TEST_NUMBER"]="Numeric data"
    ["boolean:TEST_BOOLEAN"]="True/false value"
    ["path:TEST_PATH"]="File system path"
    ["csv:TEST_CSV"]="Comma-separated values"
  )
  
  # Process parameters
  param_handler::simple_handle TYPE_PARAMS --string "Hello, World!" --number "42" --boolean "true" --path "/home/user/documents" --csv "apple,banana,cherry"
}

# Setup for JSON export format test
setup_json_export() {
  # Initialize and set up parameters
  param_handler::init
  
  # Register parameters
  param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
  param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
  param_handler::register_param "email" "TEST_EMAIL" "email" "Email address"
  
  # Generate parser
  eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
  eval "$(getoptions param_handler::parser_definition parse)"
  
  # Parse with parameters
  param_handler::parse_args --name "Alice Smith" --age "25" --email "alice@example.com"
}

# Setup for environment variable export test
setup_env_export() {
  # Initialize and set up parameters
  param_handler::init
  
  # Register parameters
  param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
  param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
  param_handler::register_param "email" "TEST_EMAIL" "email" "Email address"
  
  # Generate parser
  eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
  eval "$(getoptions param_handler::parser_definition parse)"
  
  # Parse with parameters
  param_handler::parse_args --name "Bob Johnson" --age "40" --email "bob@example.com"
  
  # Export with prefix for testing
  param_handler::export_params --prefix "EXPORT_"
}

# Setup for parameter display test
setup_display_params() {
  # Initialize and set up parameters
  param_handler::init
  
  # Register parameters
  param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
  param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
  param_handler::register_param "email" "TEST_EMAIL" "email" "Email address"
  
  # Generate parser
  eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
  eval "$(getoptions param_handler::parser_definition parse)"
  
  # Parse with mixed parameters
  param_handler::parse_args --name "Charlie Wilson" "45" --email "charlie@example.com"
} 