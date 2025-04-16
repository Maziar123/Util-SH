#!/usr/bin/bash
# test-param-handler-format-simple.sh - Format tests for simple API

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

echo "Running param_handler.sh format tests (Simple API)..."

# ----- TEST 1: Simple Handle with Standard Option Names -----
echo -e "\n\e[1mTEST 1: Simple Handle with Standard Option Names\e[0m"

# Define parameters with standard option names
TEST_NAME="" TEST_AGE="" TEST_EMAIL=""
declare -A SIMPLE_PARAMS=(
    ["name:TEST_NAME"]="Person's name"                
    ["age:TEST_AGE"]="Person's age"                   
    ["email:TEST_EMAIL"]="Email address"              
)

# Process parameters using simple_handle
param_handler::simple_handle SIMPLE_PARAMS --name "Eva Garcia" --age "28" --email "eva@example.com"

# Display results
echo "Simple handle results:"
echo "Name: $TEST_NAME"
echo "Age: $TEST_AGE"
echo "Email: $TEST_EMAIL"

# Verify results
run_test "Simple handle: name" "$TEST_NAME" "Eva Garcia"
run_test "Simple handle: age" "$TEST_AGE" "28"
run_test "Simple handle: email" "$TEST_EMAIL" "eva@example.com"

# Export to JSON
echo -e "\nJSON export of simple handle results:"
param_handler::export_params --format json

# ----- TEST 2: Simple API with Multiple Parameter Sets -----
echo -e "\n\e[1mTEST 2: Simple API with Multiple Parameter Sets\e[0m"

# First parameter set
TEST_NAME1="" TEST_AGE1=""
declare -A PARAMS1=(
    ["name:TEST_NAME1"]="First name"
    ["age:TEST_AGE1"]="First age"
)
param_handler::simple_handle PARAMS1 --name "John Doe" --age "30"

# Second parameter set
TEST_NAME2="" TEST_AGE2=""
declare -A PARAMS2=(
    ["name:TEST_NAME2"]="Second name"
    ["age:TEST_AGE2"]="Second age"
)
param_handler::simple_handle PARAMS2 --name "Jane Smith" --age "25"

echo "Multiple parameter sets results:"
echo "Set 1 - Name: $TEST_NAME1, Age: $TEST_AGE1"
echo "Set 2 - Name: $TEST_NAME2, Age: $TEST_AGE2"

# Verify results
run_test "Multiple sets: first name" "$TEST_NAME1" "John Doe"
run_test "Multiple sets: first age" "$TEST_AGE1" "30"
run_test "Multiple sets: second name" "$TEST_NAME2" "Jane Smith"
run_test "Multiple sets: second age" "$TEST_AGE2" "25"

# Export both sets
echo -e "\nEnvironment export of multiple sets:"
param_handler::export_params --prefix "EXPORTED_"
echo "First set exported: EXPORTED_TEST_NAME1=$EXPORTED_TEST_NAME1"
echo "Second set exported: EXPORTED_TEST_NAME2=$EXPORTED_TEST_NAME2"

# ----- TEST 3: Parameter Types with Simple API -----
echo -e "\n\e[1mTEST 3: Parameter Types with Simple API\e[0m"

# Different data types
TEST_STRING="" TEST_NUMBER="" TEST_BOOLEAN="" TEST_PATH="" TEST_CSV=""

# Define parameters with different data types
declare -A TYPE_PARAMS=(
    ["string:TEST_STRING"]="Text data"
    ["number:TEST_NUMBER"]="Numeric data"
    ["boolean:TEST_BOOLEAN"]="True/false value"
    ["path:TEST_PATH"]="File system path"
    ["csv:TEST_CSV"]="Comma-separated values"
)

# Process parameters
param_handler::simple_handle TYPE_PARAMS --string "Hello, World!" \
                                         --number "42" \
                                         --boolean "true" \
                                         --path "/home/user/documents" \
                                         --csv "apple,banana,cherry"

# Display results
echo "Parameter types test results:"
echo "String: $TEST_STRING"
echo "Number: $TEST_NUMBER"
echo "Boolean: $TEST_BOOLEAN"
echo "Path: $TEST_PATH"
echo "CSV: $TEST_CSV"

# Verify results
run_test "Parameter types: string" "$TEST_STRING" "Hello, World!"
run_test "Parameter types: number" "$TEST_NUMBER" "42"
run_test "Parameter types: boolean" "$TEST_BOOLEAN" "true"
run_test "Parameter types: path" "$TEST_PATH" "/home/user/documents"
run_test "Parameter types: csv" "$TEST_CSV" "apple,banana,cherry"

# Export as JSON
echo -e "\nJSON export with different data types:"
param_handler::export_params --format json

# ----- TEST 4: Custom Option Names -----
echo -e "\n\e[1mTEST 4: Custom Option Names\e[0m"

# Define parameters with custom option names
TEST_USER="" TEST_PASS="" TEST_SERVER=""
declare -A CUSTOM_PARAMS=(
    ["username:TEST_USER:user"]="Username"
    ["password:TEST_PASS:pass"]="Password"
    ["server:TEST_SERVER:srv"]="Server address"
)

# Process parameters
param_handler::simple_handle CUSTOM_PARAMS --user "admin" --pass "secret123" --srv "example.com"

# Display results
echo "Custom option names results:"
echo "Username: $TEST_USER"
echo "Password: $TEST_PASS"
echo "Server: $TEST_SERVER"

# Verify results
run_test "Custom options: username" "$TEST_USER" "admin"
run_test "Custom options: password" "$TEST_PASS" "secret123"
run_test "Custom options: server" "$TEST_SERVER" "example.com"

# ----- TEST 5: Required Parameters -----
echo -e "\n\e[1mTEST 5: Required Parameters\e[0m"

# Define parameters with required flag
TEST_REQUIRED="" TEST_OPTIONAL=""
declare -A REQUIRED_PARAMS=(
    ["required:TEST_REQUIRED:req:REQUIRE"]="Required parameter"
    ["optional:TEST_OPTIONAL:opt"]="Optional parameter"
)

# Process parameters (not using --handle-help to avoid interactive prompts in tests)
param_handler::simple_handle REQUIRED_PARAMS --req "must-have-value" --opt "optional-value"

# Display results
echo "Required parameters results:"
echo "Required: $TEST_REQUIRED"
echo "Optional: $TEST_OPTIONAL"

# Verify results
run_test "Required param" "$TEST_REQUIRED" "must-have-value"
run_test "Optional param" "$TEST_OPTIONAL" "optional-value"

# ----- Summary -----
echo -e "\n\e[1mTest Summary\e[0m"
echo -e "Total tests: $total_tests"
echo -e "Passed tests: \e[32m$passed_tests\e[0m"
if [[ $passed_tests -eq $total_tests ]]; then
    echo -e "\e[32mAll tests passed!\e[0m"
else
    echo -e "\e[31mFailed tests: $(($total_tests - $passed_tests))\e[0m"
fi
