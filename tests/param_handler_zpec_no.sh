#!/usr/bin/env bash

# Main test suite for param_handler.sh
Describe "param_handler.sh"
  Include "param_handler.sh"
  Include "tests/simple_helper.sh"
  
  # Common cleanup function
  cleanup_vars() {
    unset TEST_NAME TEST_AGE TEST_CITY EXPORT_PREFIX_NAME EXPORT_PREFIX_AGE EXPORT_PREFIX_CITY TEST_PARAMS
  }
  
  # ------------------------------
  # Named Parameters Tests
  # ------------------------------
  Describe "with named parameters"
    setup_named_params() {
      # Initialize param handler
      param_handler::init
      
      # Define parameters in an associative array
      declare -g -A TEST_PARAMS=(
        ["name:TEST_NAME"]="Person's name"
        ["age:TEST_AGE"]="Person's age"
        ["city:TEST_CITY"]="Person's city"
      )
      
      # Process parameters with simple_handle
      param_handler::simple_handle TEST_PARAMS --name "John Doe" --age "30" --city "New York"
    }
    
    BeforeEach "setup_named_params"
    AfterEach "cleanup_vars"
    
    It "sets all parameters correctly"
      The variable TEST_NAME should equal "John Doe"
      The variable TEST_AGE should equal "30"
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
  
  # ------------------------------
  # Positional Parameters Tests
  # ------------------------------
  Describe "with positional parameters"
    setup_positional_params() {
      param_handler::init
      
      # For debugging
      echo "Setting up positional parameters test"
      
      # Register parameters manually instead of using simple_handle
      param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
      param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
      param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
      
      # Generate parser
      eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
      eval "$(getoptions param_handler::parser_definition parse)"
      
      # Parse with positional parameters
      param_handler::parse_args "Jane Smith" "42" "Boston"
      
      # Debug output
      echo "After parsing: TEST_NAME='$TEST_NAME', TEST_AGE='$TEST_AGE', TEST_CITY='$TEST_CITY'"
    }
    
    BeforeEach "setup_positional_params"
    AfterEach "cleanup_vars"
    
    It "sets all parameters correctly"
      The variable TEST_NAME should equal "Jane Smith"
      The variable TEST_AGE should equal "42"
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
  
  # ------------------------------
  # Mixed Parameters Tests
  # ------------------------------
  Describe "with mixed parameters"
    setup_mixed_params() {
      param_handler::init
      
      declare -g -A TEST_PARAMS=(
        ["name:TEST_NAME"]="Person's name"
        ["age:TEST_AGE"]="Person's age"
        ["city:TEST_CITY"]="Person's city"
      )
      
      param_handler::simple_handle TEST_PARAMS --name "Alex Johnson" "42" --city "Chicago"
    }
    
    BeforeEach "setup_mixed_params"
    AfterEach "cleanup_vars"
    
    It "sets named parameters correctly"
      The variable TEST_NAME should equal "Alex Johnson"
      The variable TEST_CITY should equal "Chicago"
    End
    
    It "sets positional parameters correctly"
      The variable TEST_AGE should equal "42"
    End
    
    It "counts named parameters correctly"
      When call param_handler::get_named_count
      The stdout should equal "2"
    End
    
    It "counts positional parameters correctly"
      When call param_handler::get_positional_count
      The stdout should equal "1"
    End
  End
  
  # ------------------------------
  # Parameter Tracking Tests
  # ------------------------------
  Describe "parameter tracking functions"
    setup_tracking_params() {
      param_handler::init
      
      # Register parameters manually
      param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
      param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
      param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
      
      # Generate parser
      eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
      eval "$(getoptions param_handler::parser_definition parse)"
      
      # Parse with mixed parameters
      param_handler::parse_args --name "Robert Taylor" "33" --city "Dallas"
      
      echo "Tracking test variables: TEST_NAME='$TEST_NAME', TEST_AGE='$TEST_AGE', TEST_CITY='$TEST_CITY'"
    }
    
    BeforeEach "setup_tracking_params"
    AfterEach "cleanup_vars"
    
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
  
  # ------------------------------
  # Get Parameter Value Tests
  # ------------------------------
  Describe "get_param function"
    setup_get_param_test() {
      param_handler::init
      
      # Register parameters manually
      param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
      param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
      param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
      
      # Generate parser
      eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
      eval "$(getoptions param_handler::parser_definition parse)"
      
      # Parse with mixed parameters
      param_handler::parse_args --name "Charlie Wilson" "45" --city "Seattle"
      
      echo "Get param test variables: TEST_NAME='$TEST_NAME', TEST_AGE='$TEST_AGE', TEST_CITY='$TEST_CITY'"
    }
    
    BeforeEach "setup_get_param_test"
    AfterEach "cleanup_vars"
    
    It "gets name parameter value correctly"
      When call param_handler::get_param "name"
      The stdout should equal "Charlie Wilson"
    End
    
    It "gets age parameter value correctly"
      When call param_handler::get_param "age"
      The stdout should equal "45"
    End
    
    It "gets city parameter value correctly"
      When call param_handler::get_param "city"
      The stdout should equal "Seattle"
    End
  End
  
  # ------------------------------
  # Parameter Export Tests
  # ------------------------------
  Describe "parameter export functionality"
    setup_export_params() {
      param_handler::init
      
      # Register parameters manually
      param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
      param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
      param_handler::register_param "city" "TEST_CITY" "city" "Person's city"
      
      # Generate parser
      eval "$(param_handler::generate_parser_definition 'param_handler::parser_definition')"
      eval "$(getoptions param_handler::parser_definition parse)"
      
      # Parse with parameters
      param_handler::parse_args --name "David Miller" --age "38" --city "Portland"
      
      echo "Export test variables: TEST_NAME='$TEST_NAME', TEST_AGE='$TEST_AGE', TEST_CITY='$TEST_CITY'"
    }
    
    BeforeEach "setup_export_params"
    AfterEach "cleanup_vars"
    
    # Define this as a function for better testing
    export_and_check() {
      # Export the parameters with prefix
      param_handler::export_params --prefix "EXPORT_PREFIX_"
      
      # Debug output for variables
      echo "After export: EXPORT_PREFIX_NAME='$EXPORT_PREFIX_NAME'"
      echo "After export: EXPORT_PREFIX_AGE='$EXPORT_PREFIX_AGE'"
      echo "After export: EXPORT_PREFIX_CITY='$EXPORT_PREFIX_CITY'"
      
      # Return true to indicate success
      return 0
    }
    
    It "exports parameters with prefix"
      When call export_and_check
      The status should be success
      
      # Check individual variables
      When run test -n "$EXPORT_PREFIX_NAME"
      The status should be success
      
      When run test "$EXPORT_PREFIX_NAME" = "David Miller"
      The status should be success
      
      When run test "$EXPORT_PREFIX_AGE" = "38"
      The status should be success
      
      When run test "$EXPORT_PREFIX_CITY" = "Portland"
      The status should be success
    End

    It "exports parameters to JSON format"
      When call param_handler::export_params --format json
      The stdout should include "name"
      The stdout should include "David Miller"
      The stdout should include "age"
      The stdout should include "38"
      The stdout should include "city"
      The stdout should include "Portland"
    End
  End
  
  # ------------------------------
  # Custom Option Names Tests
  # ------------------------------
  Describe "with custom option names"
    setup_custom_options() {
      param_handler::init
      
      declare -g -A TEST_PARAMS=(
        ["name:TEST_NAME:username"]="Username"
        ["age:TEST_AGE:years"]="Age in years"
        ["city:TEST_CITY:location"]="Current location"
      )
      
      param_handler::simple_handle TEST_PARAMS --username "Emma Wilson" --years "42" --location "Austin"
    }
    
    BeforeEach "setup_custom_options"
    AfterEach "cleanup_vars"
    
    It "sets parameters correctly using custom option names"
      The variable TEST_NAME should equal "Emma Wilson"
      The variable TEST_AGE should equal "42"
      The variable TEST_CITY should equal "Austin"
    End
  End
End 