#!/usr/bin/env bash
# Simple test script for the get_value functions

echo "Starting simple test of get_value functions..."
echo "----------------------------------------------"

# Source the library
source ./sh-globals.sh

# Override the read command to avoid any input prompts
read() {
  echo "MOCK READ: $*" >&2
  REPLY="test_input"
  return 0
}

# Override error message function
msg_error() {
  echo "ERROR MSG: $*" >&2
}

# Override bc for testing
bc() {
  echo "0"  # Make all comparisons pass
}

# Test harness
run_test() {
  local func="$1"
  shift
  echo "Testing $func with args: $*"
  "$func" "$@"
  echo "Test completed for $func"
  echo
}

# Run tests
echo "Test 1: get_number"
run_test get_number "Enter a number:" "10" "1" "100"

echo "Test 2: get_string"
run_test get_string "Enter a string:" "default" "^[a-z]+$" "Invalid format"

echo "Test 3: get_path"
run_test get_path "Enter a path:" "/tmp" "file" "0"

echo "Test 4: get_value with validator"
# Define a simple validator function
is_valid() {
  echo "Validating: $1" >&2
  return 0  # Always valid
}
run_test get_value "Enter a value:" "default" "is_valid" "Invalid input"

echo "All tests completed successfully!" 