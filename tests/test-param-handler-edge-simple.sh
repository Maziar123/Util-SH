#!/usr/bin/bash
# test-param-handler-edge-simple.sh - Edge case tests for simple API

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

# ----- TEST 1: Standard option names -----
echo -e "\n\e[1mTEST 1: Standard option names\e[0m"
# Reset parameters
TEST_NAME=""
TEST_AGE=""

# Define parameters using standard option names
declare -a TEST_PARAMS=(
    "name:TEST_NAME::Person's name"
    "age:TEST_AGE::Person's age"
)

# Process parameters using simple_handle
param_handler::simple_handle TEST_PARAMS --name "Mary Johnson" --age "42"

# Verify results
run_test "Standard option names: name" "$TEST_NAME" "Mary Johnson"
run_test "Standard option names: age" "$TEST_AGE" "42"

# ----- TEST 2: Positional parameters -----
echo -e "\n\e[1mTEST 2: Positional parameters\e[0m"
TEST_NAME=""
TEST_AGE=""
declare -a TEST_PARAMS=(
    "name:TEST_NAME::Person's name"
    "age:TEST_AGE::Person's age"
)
param_handler::simple_handle TEST_PARAMS "John Smith" "35"
run_test "Positional params: name" "$TEST_NAME" "John Smith"
run_test "Positional params: age" "$TEST_AGE" "35"

# ----- TEST 3: Parameters with spaces and special characters -----
echo -e "\n\e[1mTEST 3: Parameters with spaces and special characters\e[0m"
TEST_NAME=""
TEST_AGE=""
declare -a TEST_PARAMS=(
    "name:TEST_NAME::Person's name"
    "age:TEST_AGE::Person's age"
)
param_handler::simple_handle TEST_PARAMS --name "Robert O'Neill Jr." --age "45+"
run_test "Special chars: name" "$TEST_NAME" "Robert O'Neill Jr."
run_test "Special chars: age" "$TEST_AGE" "45+"

# ----- TEST 4: Empty and missing parameters -----
echo -e "\n\e[1mTEST 4: Empty and missing parameters\e[0m"
TEST_NAME=""
TEST_AGE=""
TEST_CITY=""
declare -a TEST_PARAMS=(
    "name:TEST_NAME::Person's name"
    "age:TEST_AGE::Person's age"
    "city:TEST_CITY::Person's city"
)
param_handler::simple_handle TEST_PARAMS --name "William Turner"
run_test "Missing params: name" "$TEST_NAME" "William Turner"
run_test "Missing params: age" "$TEST_AGE" ""
run_test "Missing params: city" "$TEST_CITY" ""

# ----- TEST 5: Multiple parameter sets -----
echo -e "\n\e[1mTEST 5: Multiple parameter sets\e[0m"
USER_NAME=""
USER_AGE=""
ADMIN_NAME=""
ADMIN_AGE=""

# First parameter set
declare -a USER_PARAMS=(
    "name:USER_NAME::User's name"
    "age:USER_AGE::User's age"
)
param_handler::simple_handle USER_PARAMS --name "Regular User" --age "30"

# Second parameter set
declare -a ADMIN_PARAMS=(
    "name:ADMIN_NAME::Admin's name"
    "age:ADMIN_AGE::Admin's age"
)
param_handler::simple_handle ADMIN_PARAMS --name "System Admin" --age "35"

# Verify results
run_test "Multiple sets: user name" "$USER_NAME" "Regular User"
run_test "Multiple sets: user age" "$USER_AGE" "30"
run_test "Multiple sets: admin name" "$ADMIN_NAME" "System Admin"
run_test "Multiple sets: admin age" "$ADMIN_AGE" "35"

# ----- Summary -----
echo -e "\n\e[1mTest Summary\e[0m"
echo -e "Total tests: $total_tests"
echo -e "Passed tests: \e[32m$passed_tests\e[0m"
if [[ $passed_tests -eq $total_tests ]]; then
    echo -e "\e[32mAll tests passed!\e[0m"
else
    echo -e "\e[31mFailed tests: $(($total_tests - $passed_tests))\e[0m"
fi
