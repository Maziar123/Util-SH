#!/usr/bin/bash
# test_param_handler_edge_simple.sh - Edge case tests for simple API

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

echo "Running param_handler.sh edge case tests (Simple API)..."

# Extract Test 9 from original file
echo -e "\n\e[1mTEST 1: Testing with simple_handle using standard option names\e[0m"
# Reset parameters
TEST_NAME=""
TEST_AGE=""
param_handler::init

# Define parameters using standard option names
declare -A TEST_PARAMS=(
    ["name:TEST_NAME"]="Person's name"
    ["age:TEST_AGE"]="Person's age"
)

# Process parameters using simple_handle
param_handler::simple_handle TEST_PARAMS --name "Mary Johnson" --age "42"

# Verify results
run_test "Standard option names: name" "$TEST_NAME" "Mary Johnson"
run_test "Standard option names: age" "$TEST_AGE" "42"

# Add more simple API tests
echo -e "\n\e[1mTEST 2: Simple API with positional parameters\e[0m"
TEST_NAME=""
TEST_AGE=""
declare -A TEST_PARAMS=(
    ["name:TEST_NAME"]="Person's name"
    ["age:TEST_AGE"]="Person's age"
)
param_handler::simple_handle TEST_PARAMS "John Smith" "35"
run_test "Positional params: name" "$TEST_NAME" "John Smith"
run_test "Positional params: age" "$TEST_AGE" "35"

# Summary
echo -e "\n\e[1mTest Summary\e[0m"
echo -e "Total tests: $total_tests"
echo -e "Passed tests: \e[32m$passed_tests\e[0m"
if [[ $passed_tests -eq $total_tests ]]; then
    echo -e "\e[32mAll tests passed!\e[0m"
else
    echo -e "\e[31mFailed tests: $(($total_tests - $passed_tests))\e[0m"
fi 