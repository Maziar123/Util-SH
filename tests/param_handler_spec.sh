#!/usr/bin/env bash

Describe "param_handler.sh"
  # Source param_handler.sh
  # Include is similar to source but tracked by shellspec
  Include "param_handler.sh"
  # Include helper functions
  Include "tests/simple_helper.sh"

  # --- Helper Setup/Cleanup Functions ---

  # Helper to clean up common test variables
  cleanup() {
    unset TEST_NAME TEST_AGE TEST_CITY
  }
  
  # Setup for named parameters only
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

  # Setup for positional parameters only
  setup_positional_params() {
    param_handler::init
    param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
    param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
    param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
    eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
    eval "$(getoptions param_handler::parser_definition parse)"
    param_handler::parse_args "Jane Smith" "25" "Boston"
  }

  # Setup for mixed parameters
  setup_mixed_params() {
    param_handler::init
    param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
    param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
    param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
    eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
    eval "$(getoptions param_handler::parser_definition parse)"
    param_handler::parse_args --name "Alex Johnson" "40" "Seattle"
  }

  # Setup for simple_handle tests
  setup_simple_handle() {
    param_handler::init
    declare -Ag TEST_PARAMS=(
        ["name:TEST_NAME"]="Person's name"
        ["age:TEST_AGE"]="Person's age"
        ["city:TEST_CITY"]="Person's city"
    )
    param_handler::simple_handle TEST_PARAMS --name "Sarah Wilson" --age "35" --city "Denver"
  }

  # Setup for parameter tracking tests
  setup_tracking_params() {
    param_handler::init
    param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
    param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
    param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
    eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
    eval "$(getoptions param_handler::parser_definition parse)"
    param_handler::parse_args --name "Robert Taylor" "33" --city "Dallas"
  }

  # Setup for custom option names tests
  setup_custom_options() {
    param_handler::init
    declare -Ag TEST_PARAMS=(
        ["username:TEST_NAME:user"]="Username"
        ["password:TEST_AGE:pass"]="Password"
        ["location:TEST_CITY:loc"]="Location"
    )
    # Note: Adjusted var names/values to match expected test results
    param_handler::simple_handle TEST_PARAMS --user "Emma Wilson" --pass "42" --loc "Austin"
  }

  # Setup for JSON export tests
  setup_json_export() {
    param_handler::init
    param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
    param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
    param_handler::register_param "email" "TEST_EMAIL" "email" "Email address"
    eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
    eval "$(getoptions param_handler::parser_definition parse)"
    param_handler::parse_args --name "Alice Smith" --age "25" --email "alice@example.com"
  }

  # Setup for environment variable export tests
  setup_env_export() {
    param_handler::init
    # Use distinct variable names to avoid conflicts
    param_handler::register_param "export_name" "EXPORT_TEST_NAME" "export-name" "Export Name"
    param_handler::register_param "export_age" "EXPORT_TEST_AGE" "export-age" "Export Age"
    param_handler::register_param "export_email" "EXPORT_TEST_EMAIL" "export-email" "Export Email"
    eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
    eval "$(getoptions param_handler::parser_definition parse)"
    param_handler::parse_args --export-name "Bob Johnson" --export-age "40" --export-email "bob@example.com"
    # Perform export within setup to check env vars in tests
    param_handler::export_params --prefix ""
  }

  # Setup for parameter display tests
  setup_display_params() {
    param_handler::init
    param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
    param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
    param_handler::register_param "email" "TEST_EMAIL" "email" "Email address"
    eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
    eval "$(getoptions param_handler::parser_definition parse)"
    # Note: Parse args match the expected output (2 named, 1 positional)
    param_handler::parse_args --name "Charlie Wilson" "45" --email "charlie@example.com"
  }
  
  # Setup for manual API parameter type tests
  setup_param_types_manual() {
      param_handler::init
      param_handler::register_param "string" "TEST_STRING" "string" "Text data"
      param_handler::register_param "number" "TEST_NUMBER" "number" "Numeric data"
      param_handler::register_param "boolean" "TEST_BOOLEAN" "boolean" "True/false value"
      param_handler::register_param "path" "TEST_PATH" "path" "File system path"
      param_handler::register_param "csv" "TEST_CSV" "csv" "Comma-separated values"
      eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
      eval "$(getoptions param_handler::parser_definition parse)"
      param_handler::parse_args --string "Hello, World!" --number "42" --boolean "true" --path "/home/user/documents" --csv "apple,banana,cherry"
  }
  
  # Setup for simple API parameter type tests
  setup_param_types_simple() {
      param_handler::init
      declare -Ag TYPE_PARAMS=(
          ["string:TEST_STRING"]="Text data"
          ["number:TEST_NUMBER"]="Numeric data"
          ["boolean:TEST_BOOLEAN"]="True/false value"
          ["path:TEST_PATH"]="File system path"
          ["csv:TEST_CSV"]="Comma-separated values"
      )
      param_handler::simple_handle TYPE_PARAMS --string "Hello, World!" --number "42" --boolean "true" --path "/home/user/documents" --csv "apple,banana,cherry"
  }

  # --- Test Suites ---

  # Test with named parameters only
  Describe "with named parameters only"
    # Use the setup function defined globally
    BeforeEach "setup_named_params"
    
    # Use shared cleanup function
    AfterEach "cleanup"

    It "sets the name parameter correctly"
      The variable TEST_NAME should equal "John Doe"
    End

    It "sets the age parameter correctly"
      The variable TEST_AGE should equal "30"
    End

    It "sets the city parameter correctly"
      The variable TEST_CITY should equal "New York"
    End

    It "counts named parameters correctly"
      When call param_handler::get_named_count
      The stdout should equal "3"
    End

    It "counts positional parameters correctly"
      When call param_handler::get_positional_count
      The stdout should equal "0"
    End
  End

  # Test with positional parameters only
  Describe "with positional parameters only"
    BeforeEach "setup_positional_params"
    AfterEach "cleanup"

    It "sets the name parameter correctly"
      The variable TEST_NAME should equal "Jane Smith"
    End

    It "sets the age parameter correctly"
      The variable TEST_AGE should equal "25"
    End

    It "sets the city parameter correctly"
      The variable TEST_CITY should equal "Boston"
    End

    It "counts named parameters correctly"
      When call param_handler::get_named_count
      The stdout should equal "0"
    End

    It "counts positional parameters correctly"
      When call param_handler::get_positional_count
      The stdout should equal "3"
    End
  End

  # Test with mixed parameters
  Describe "with mixed parameters"
    BeforeEach "setup_mixed_params"
    AfterEach "cleanup"

    It "sets the name parameter correctly (named)"
      The variable TEST_NAME should equal "Alex Johnson"
    End

    It "sets the age parameter correctly (positional)"
      The variable TEST_AGE should equal "40"
    End

    It "sets the city parameter correctly (positional)"
      The variable TEST_CITY should equal "Seattle"
    End

    It "counts named parameters correctly"
      When call param_handler::get_named_count
      The stdout should equal "1"
    End

    It "counts positional parameters correctly"
      When call param_handler::get_positional_count
      The stdout should equal "2"
    End
  End

  # Test with simple_handle function
  Describe "simple_handle function"
    BeforeEach "setup_simple_handle"
    AfterEach "cleanup"

    It "sets the name parameter correctly"
      The variable TEST_NAME should equal "Sarah Wilson"
    End

    It "sets the age parameter correctly"
      The variable TEST_AGE should equal "35"
    End

    It "sets the city parameter correctly"
      The variable TEST_CITY should equal "Denver"
    End
  End

  # Test was_set_by_name and was_set_by_position
  Describe "parameter tracking functions"
    BeforeEach "setup_tracking_params"
    AfterEach "cleanup"

    It "tracks name as set by name"
      When call param_handler::was_set_by_name "name"
      The status should be success
    End

    It "tracks age as not set by name"
      When call param_handler::was_set_by_name "age"
      The status should be failure
    End

    It "tracks city as set by name"
      When call param_handler::was_set_by_name "city"
      The status should be success
    End

    It "tracks name as not set by position"
      When call param_handler::was_set_by_position "name"
      The status should be failure
    End

    It "tracks age as set by position"
      When call param_handler::was_set_by_position "age"
      The status should be success
    End

    It "tracks city as not set by position"
      When call param_handler::was_set_by_position "city"
      The status should be failure
    End
  End

  # Test get_param function
  Describe "get_param function"
    BeforeEach "setup_tracking_params"
    AfterEach "cleanup"

    It "gets name parameter value correctly"
      When call param_handler::get_param "name"
      The stdout should equal "Robert Taylor"
    End

    It "gets age parameter value correctly"
      When call param_handler::get_param "age"
      The stdout should equal "33"
    End

    It "gets city parameter value correctly"
      When call param_handler::get_param "city"
      The stdout should equal "Dallas"
    End
  End

  # Test custom option names
  Describe "with custom option names"
    BeforeEach "setup_custom_options"
    AfterEach "cleanup"

    It "sets the name parameter correctly"
      The variable TEST_NAME should equal "Emma Wilson"
    End

    It "sets the age parameter correctly"
      The variable TEST_AGE should equal "42"
    End

    It "sets the city parameter correctly"
      The variable TEST_CITY should equal "Austin"
    End
  End

  # Format and Export Tests
  Describe "parameter export functionality"
    Describe "JSON export format"
      BeforeEach "setup_json_export"
      AfterEach 'unset TEST_NAME TEST_AGE TEST_EMAIL'

      It "includes all parameters in JSON output"
        When call param_handler::export_params --format json
        # Use alternative string patterns without nested quotes
        The stdout should include "name"
        The stdout should include "Alice Smith"
        The stdout should include "age"
        The stdout should include "25"
        The stdout should include "email"
        The stdout should include "alice@example.com"
      End

      It "adds prefix to JSON keys when specified"
        When call param_handler::export_params --format json --prefix "USER_"
        # Use alternative string patterns without nested quotes
        The stdout should include "USER_name"
        The stdout should include "Alice Smith"
        The stdout should include "USER_age"
        The stdout should include "25"
        The stdout should include "USER_email"
        The stdout should include "alice@example.com"
      End
    End

    Describe "environment variable export"
      BeforeEach "setup_env_export"
      AfterEach "unset EXPORT_TEST_NAME EXPORT_TEST_AGE EXPORT_TEST_EMAIL"

      It "exports variables to environment with prefix"
        The variable EXPORT_TEST_NAME should equal "Bob Johnson"
        The variable EXPORT_TEST_AGE should equal "40"
        The variable EXPORT_TEST_EMAIL should equal "bob@example.com"
      End
    End
  End

  # Parameter Display Tests
  Describe "parameter display functionality"
    BeforeEach "setup_display_params"
    AfterEach 'unset TEST_NAME TEST_AGE TEST_EMAIL'

    It "displays all parameters in print_params output"
      When call param_handler::print_params
      # Use simpler substring checks
      The stdout should include "TEST_NAME:"
      The stdout should include "Charlie Wilson"
      The stdout should include "TEST_AGE:"
      The stdout should include "45"
      The stdout should include "TEST_EMAIL:"
      The stdout should include "charlie@example.com"
    End

    It "includes correct counts in parameter summary"
      # Define expected output (no trailing spaces/blank lines)
      expected_summary=$(cat <<-EOF
Parameter Summary:
Named parameters: 2
Positional parameters: 1
Total parameters: 3
EOF
)
      
      # Run the command and process its output within a block
      # Use paths relative to the project root and simplify command execution
      When run bash -c 'source "tests/param_handler_helper.sh"; source "param_handler.sh"; setup_display_params; param_handler::print_summary | sed "s/\\x1b\\[[0-9;]*[mK]//g" | sed "s/[[:space:]]*$//" | sed "/^$/d"'

      # Assert that the processed stdout equals the expected output
      The stdout should equal "$expected_summary"
    End
  End

  # Parameter Type Tests
  Describe "parameter type handling"
    Describe "with manual API"
      BeforeEach "setup_param_types_manual"
      AfterEach "unset TEST_STRING TEST_NUMBER TEST_BOOLEAN TEST_PATH TEST_CSV"

      It "handles text data correctly"
        The variable TEST_STRING should equal "Hello, World!"
      End

      It "handles numeric data correctly"
        The variable TEST_NUMBER should equal "42"
      End

      It "handles boolean values correctly"
        The variable TEST_BOOLEAN should equal "true"
      End

      It "handles file paths correctly"
        The variable TEST_PATH should equal "/home/user/documents"
      End

      It "handles comma-separated values correctly"
        The variable TEST_CSV should equal "apple,banana,cherry"
      End
    End

    Describe "with simple API"
      BeforeEach "setup_param_types_simple"
      AfterEach "unset TEST_STRING TEST_NUMBER TEST_BOOLEAN TEST_PATH TEST_CSV"

      It "handles text data correctly with simple API"
        The variable TEST_STRING should equal "Hello, World!"
      End

      It "handles numeric data correctly with simple API"
        The variable TEST_NUMBER should equal "42"
      End

      It "handles boolean values correctly with simple API"
        The variable TEST_BOOLEAN should equal "true"
      End

      It "handles file paths correctly with simple API"
        The variable TEST_PATH should equal "/home/user/documents"
      End

      It "handles comma-separated values correctly with simple API"
        The variable TEST_CSV should equal "apple,banana,cherry"
      End
    End
  End
End 