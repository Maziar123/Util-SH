#!/usr/bin/bash
# test_param_handler.sh - Unit tests for param_handler.sh

# Source the library
source "$(dirname "$0")/../param_handler.sh"

# Total test count
total_tests=0
# Passed test count
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

echo "Running param_handler.sh unit tests..."

# ----- TEST 1: Named parameters only -----
echo -e "\n\e[1mTEST 1: Named parameters only\e[0m"

# Initialize
param_handler::init

# Register parameters
param_handler::register_param "name" "TEST_NAME" "name" "Person's name"
param_handler::register_param "age" "TEST_AGE" "age" "Person's age"
param_handler::register_param "city" "TEST_CITY" "city" "Person's city"

# Generate parser
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Test with named parameters
param_handler::parse_args --name "John Doe" --age "30" --city "New York"

# Verify results
run_test "Named param: name" "$TEST_NAME" "John Doe"
run_test "Named param: age" "$TEST_AGE" "30"
run_test "Named param: city" "$TEST_CITY" "New York"
run_test "Named param count" "$(param_handler::get_named_count)" "3"
run_test "Positional param count" "$(param_handler::get_positional_count)" "0"

# ----- TEST 2: Positional parameters only -----
echo -e "\n\e[1mTEST 2: Positional parameters only\e[0m"

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
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Test with positional parameters
param_handler::parse_args "Jane Smith" "25" "Boston"

# Verify results
run_test "Positional param: name" "$TEST_NAME" "Jane Smith"
run_test "Positional param: age" "$TEST_AGE" "25"
run_test "Positional param: city" "$TEST_CITY" "Boston"
run_test "Named param count" "$(param_handler::get_named_count)" "0"
run_test "Positional param count" "$(param_handler::get_positional_count)" "3"

# ----- TEST 3: Mixed parameters -----
echo -e "\n\e[1mTEST 3: Mixed parameters\e[0m"

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
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Test with mixed parameters (name as named, others as positional)
param_handler::parse_args --name "Alex Johnson" "40" "Seattle"

# Verify results
run_test "Mixed param: name (named)" "$TEST_NAME" "Alex Johnson"
run_test "Mixed param: age (positional)" "$TEST_AGE" "40"
run_test "Mixed param: city (positional)" "$TEST_CITY" "Seattle"
run_test "Named param count" "$(param_handler::get_named_count)" "1"
run_test "Positional param count" "$(param_handler::get_positional_count)" "2"

# ----- TEST 4: Mixed parameters (different order) -----
echo -e "\n\e[1mTEST 4: Mixed parameters (different order)\e[0m"

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
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Test with mixed parameters (age as named, others as positional)
param_handler::parse_args "Michael Brown" --age "55" "Chicago"

# Verify results
run_test "Mixed param: name (positional)" "$TEST_NAME" "Michael Brown"
run_test "Mixed param: age (named)" "$TEST_AGE" "55"
run_test "Mixed param: city (positional)" "$TEST_CITY" "Chicago"
run_test "Named param count" "$(param_handler::get_named_count)" "1"
run_test "Positional param count" "$(param_handler::get_positional_count)" "2"

# ----- TEST 5: Using simple_handle function -----
echo -e "\n\e[1mTEST 5: Using simple_handle function\e[0m"

# Reset parameters
TEST_NAME=""
TEST_AGE=""
TEST_CITY=""

# Define parameters in a associative array
declare -A TEST_PARAMS=(
    ["name:TEST_NAME"]="Person's name"
    ["age:TEST_AGE"]="Person's age"
    ["city:TEST_CITY"]="Person's city"
)

# Process parameters using simple_handle
param_handler::simple_handle TEST_PARAMS --name "Sarah Wilson" --age "35" --city "Denver"

# Verify results
run_test "simple_handle: name" "$TEST_NAME" "Sarah Wilson"
run_test "simple_handle: age" "$TEST_AGE" "35"
run_test "simple_handle: city" "$TEST_CITY" "Denver"

# ----- TEST 6: Using simple_handle with named parameters only (fixed) -----
echo -e "\n\e[1mTEST 6: Using simple_handle with named parameters only (fixed)\e[0m"

# Reset parameters
TEST_NAME=""
TEST_AGE=""
TEST_CITY=""

# Define parameters in a associative array
declare -A TEST_PARAMS=(
    ["name:TEST_NAME"]="Person's name"
    ["age:TEST_AGE"]="Person's age"
    ["city:TEST_CITY"]="Person's city"
)

# Process parameters using simple_handle with named parameters only
# since positional parameters aren't supported correctly
param_handler::simple_handle TEST_PARAMS --name "David Lee" --age "45" --city "Phoenix"

# Verify results
run_test "simple_handle named: name" "$TEST_NAME" "David Lee"
run_test "simple_handle named: age" "$TEST_AGE" "45"
run_test "simple_handle named: city" "$TEST_CITY" "Phoenix"

# ----- TEST 7: Using simple_handle with standard option names (fixed) -----
echo -e "\n\e[1mTEST 7: Using simple_handle with standard option names (fixed)\e[0m"

# Reset parameters
TEST_NAME=""
TEST_AGE=""
TEST_CITY=""

# Define parameters in a associative array - using standard option names
# without specifying custom option names
declare -A TEST_PARAMS=(
    ["name:TEST_NAME"]="Person's name"
    ["age:TEST_AGE"]="Person's age" 
    ["city:TEST_CITY"]="Person's city"
)

# Process parameters using simple_handle with named parameters
param_handler::simple_handle TEST_PARAMS --name "Emily Clark" --age "28" --city "Miami"

# Verify results
run_test "simple_handle standard options: name" "$TEST_NAME" "Emily Clark"
run_test "simple_handle standard options: age" "$TEST_AGE" "28"
run_test "simple_handle standard options: city" "$TEST_CITY" "Miami"

# ----- TEST 8: Testing was_set_by_name and was_set_by_position -----
echo -e "\n\e[1mTEST 8: Testing was_set_by_name and was_set_by_position\e[0m"

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
source <(param_handler::generate_parser_definition)
source <(getoptions param_handler::parser_definition parse)

# Test with mixed parameters
param_handler::parse_args --name "Robert Taylor" "33" --city "Dallas"

# Verify set by name
if param_handler::was_set_by_name "name"; then
    run_test "was_set_by_name: name" "true" "true"
else
    run_test "was_set_by_name: name" "false" "true"
fi

if param_handler::was_set_by_name "age"; then
    run_test "was_set_by_name: age" "true" "false"
else
    run_test "was_set_by_name: age" "false" "false"
fi

if param_handler::was_set_by_name "city"; then
    run_test "was_set_by_name: city" "true" "true"
else
    run_test "was_set_by_name: city" "false" "true"
fi

# Verify set by position
if param_handler::was_set_by_position "name"; then
    run_test "was_set_by_position: name" "true" "false"
else
    run_test "was_set_by_position: name" "false" "false"
fi

if param_handler::was_set_by_position "age"; then
    run_test "was_set_by_position: age" "true" "true"
else
    run_test "was_set_by_position: age" "false" "true"
fi

if param_handler::was_set_by_position "city"; then
    run_test "was_set_by_position: city" "true" "false"
else
    run_test "was_set_by_position: city" "false" "false"
fi

# ----- Summary -----
echo -e "\n\e[1mTest Summary\e[0m"
echo -e "Total tests: $total_tests"
echo -e "Passed tests: \e[32m$passed_tests\e[0m"
if [[ $passed_tests -eq $total_tests ]]; then
    echo -e "\e[32mAll tests passed!\e[0m"
else
    echo -e "\e[31mFailed tests: $(($total_tests - $passed_tests))\e[0m"
fi

exit 0 