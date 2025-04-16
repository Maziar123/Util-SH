#!/usr/bin/env bash
# test-array-functions.sh - Tests for array functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Group for array functions
test_group "Array Functions"

# Test array_contains
test_array_contains() {
  # Create test array
  local test_array=("apple" "banana" "orange" "grape")
  
  # Positive test - element exists
  assert_eq "$(array_contains "banana" "${test_array[@]}" && echo "true" || echo "false")" "true"
  
  # Negative test - element does not exist
  assert_eq "$(array_contains "kiwi" "${test_array[@]}" && echo "true" || echo "false")" "false"
  
  # Empty array
  local empty_array=()
  assert_eq "$(array_contains "anything" "${empty_array[@]}" && echo "true" || echo "false")" "false"
  
  # Case sensitivity
  assert_eq "$(array_contains "Banana" "${test_array[@]}" && echo "true" || echo "false")" "false"
  assert_eq "$(array_contains "banana" "${test_array[@]}" && echo "true" || echo "false")" "true"
  
  # First element
  assert_eq "$(array_contains "apple" "${test_array[@]}" && echo "true" || echo "false")" "true"
  
  # Last element
  assert_eq "$(array_contains "grape" "${test_array[@]}" && echo "true" || echo "false")" "true"
  
  return 0
}
test "array_contains function" test_array_contains

# Test array_join
test_array_join() {
  # Create test array
  local test_array=("apple" "banana" "orange" "grape")
  
  # Join with comma
  assert_eq "$(array_join "," "${test_array[@]}")" "apple,banana,orange,grape"
  
  # Join with space
  assert_eq "$(array_join " " "${test_array[@]}")" "apple banana orange grape"
  
  # Join with multi-character delimiter
  assert_eq "$(array_join " | " "${test_array[@]}")" "apple | banana | orange | grape"
  
  # Single element array
  local single_array=("apple")
  assert_eq "$(array_join "," "${single_array[@]}")" "apple"
  
  # Empty array
  local empty_array=()
  assert_eq "$(array_join "," "${empty_array[@]}")" ""
  
  # Array with empty elements
  local mixed_array=("apple" "" "orange" "")
  assert_eq "$(array_join "," "${mixed_array[@]}")" "apple,,orange,"
  
  return 0
}
test "array_join function" test_array_join

# Test array_length
test_array_length() {
  # Create test arrays
  local test_array=("apple" "banana" "orange" "grape")
  local empty_array=()
  local single_array=("apple")
  
  # Declare arrays for testing with array_length
  declare -a declared_test_array=("apple" "banana" "orange" "grape")
  declare -a declared_empty_array=()
  declare -a declared_single_array=("apple")
  
  # Test regular array
  assert_eq "$(array_length declared_test_array)" "4"
  
  # Test empty array
  assert_eq "$(array_length declared_empty_array)" "0"
  
  # Test single element array
  assert_eq "$(array_length declared_single_array)" "1"
  
  return 0
}
test "array_length function" test_array_length 