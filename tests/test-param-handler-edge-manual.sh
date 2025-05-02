#!/usr/bin/bash
# test-param-handler-edge-manual.sh - Edge case tests for manual registration API

# Source the library
source "$(dirname "$0")/../param_handler.sh"

# Total test count and passed test count
total_tests=0
passed_tests=0

# Test function
run_test() {
    local test_name="$1"
    local result="$2"
    local expected="$3"
    
    ((total_tests++))
    
    if [[ "$result" == "$expected" ]]; then
        echo -e "\e[32mPASS\e[0m: $test_name"
        ((passed_tests++))
    else
        echo -e "\e[31mFAIL\e[0m: $test_name"
        echo "  Expected: '$expected'"
        echo "  Got:      '$result'"
    fi
}

echo "Running param_handler.sh edge case tests (Manual Registration API)..."

# ----- TEST 1: Empty parameters -----
echo -e "\n\e[1mTEST 1: Empty parameters\e[0m"
param_handler::init
param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
param_handler::register_param "age" "TEST_AGE" "age" "Person's age"

# Generate parser
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Parse with empty parameters
param_handler::parse_args

# Verify results
run_test "Empty params: name" "$TEST_NAME" ""
run_test "Empty params: age" "$TEST_AGE" ""

# ----- TEST 2: Parameters with spaces -----
echo -e "\n\e[1mTEST 2: Parameters with spaces\e[0m"
TEST_NAME=""
TEST_AGE=""
param_handler::init
param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
param_handler::register_param "age" "TEST_AGE" "age" "Person's age"

# Generate parser
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Parse with parameters containing spaces
param_handler::parse_args --name "John Smith" --age "42 years"

# Verify results
run_test "Spaces in params: name" "$TEST_NAME" "John Smith"
run_test "Spaces in params: age" "$TEST_AGE" "42 years"

# ----- TEST 3: Parameters with special characters -----
echo -e "\n\e[1mTEST 3: Parameters with special characters\e[0m"
TEST_NAME=""
TEST_AGE=""
param_handler::init
param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
param_handler::register_param "age" "TEST_AGE" "age" "Person's age"

# Generate parser
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Parse with parameters containing special characters
param_handler::parse_args --name "O'Reilly-Smith" --age "30+"

# Verify results
run_test "Special chars: name" "$TEST_NAME" "O'Reilly-Smith"
run_test "Special chars: age" "$TEST_AGE" "30+"

# ----- TEST 4: Only some parameters provided -----
echo -e "\n\e[1mTEST 4: Only some parameters provided\e[0m"
TEST_NAME=""
TEST_AGE=""
TEST_CITY=""
param_handler::init
param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
param_handler::register_param "city" "TEST_CITY" "city" "Person's city"

# Generate parser
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Parse with only some parameters
param_handler::parse_args --name "Jane Doe"

# Verify results
run_test "Some params: name" "$TEST_NAME" "Jane Doe"
run_test "Some params: age" "$TEST_AGE" ""
run_test "Some params: city" "$TEST_CITY" ""

# ----- Summary -----
echo -e "\n\e[1mTest Summary\e[0m"
echo -e "Total tests: $total_tests"
echo -e "Passed tests: \e[32m$passed_tests\e[0m"
if [[ $passed_tests -eq $total_tests ]]; then
    echo -e "\e[32mAll tests passed!\e[0m"
else
    echo -e "\e[31mFailed tests: $(($total_tests - $passed_tests))\e[0m"
fi
