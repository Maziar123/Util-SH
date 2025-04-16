#!/usr/bin/env bash
# test-string-functions.sh - Tests for string functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Group for string functions
test_group "String Functions"

# Test str_contains
test_str_contains() {
  # Positive test
  assert_eq "$(str_contains "Hello World" "World" && echo "true" || echo "false")" "true" 
  
  # Negative test
  assert_eq "$(str_contains "Hello World" "Universe" && echo "true" || echo "false")" "false"
  
  # Empty string
  assert_eq "$(str_contains "" "test" && echo "true" || echo "false")" "false"
  
  # Empty substring
  assert_eq "$(str_contains "Hello" "" && echo "true" || echo "false")" "true"
  
  return 0
}
test "str_contains function" test_str_contains

# Test str_starts_with
test_str_starts_with() {
  # Positive test
  assert_eq "$(str_starts_with "Hello World" "Hello" && echo "true" || echo "false")" "true"
  
  # Negative test
  assert_eq "$(str_starts_with "Hello World" "World" && echo "true" || echo "false")" "false"
  
  # Exact match
  assert_eq "$(str_starts_with "Hello" "Hello" && echo "true" || echo "false")" "true"
  
  # Empty string
  assert_eq "$(str_starts_with "" "test" && echo "true" || echo "false")" "false"
  
  # Empty prefix
  assert_eq "$(str_starts_with "Hello" "" && echo "true" || echo "false")" "true"
  
  return 0
}
test "str_starts_with function" test_str_starts_with

# Test str_ends_with
test_str_ends_with() {
  # Positive test
  assert_eq "$(str_ends_with "Hello World" "World" && echo "true" || echo "false")" "true"
  
  # Negative test
  assert_eq "$(str_ends_with "Hello World" "Hello" && echo "true" || echo "false")" "false"
  
  # Exact match
  assert_eq "$(str_ends_with "Hello" "Hello" && echo "true" || echo "false")" "true"
  
  # Empty string
  assert_eq "$(str_ends_with "" "test" && echo "true" || echo "false")" "false"
  
  # Empty suffix
  assert_eq "$(str_ends_with "Hello" "" && echo "true" || echo "false")" "true"
  
  return 0
}
test "str_ends_with function" test_str_ends_with

# Test str_trim
test_str_trim() {
  # Spaces on both sides
  assert_eq "$(str_trim "  Hello World  ")" "Hello World"
  
  # Spaces on left
  assert_eq "$(str_trim "  Hello World")" "Hello World"
  
  # Spaces on right
  assert_eq "$(str_trim "Hello World  ")" "Hello World"
  
  # No spaces
  assert_eq "$(str_trim "Hello")" "Hello"
  
  # Only spaces
  assert_eq "$(str_trim "  ")" ""
  
  # Empty string
  assert_eq "$(str_trim "")" ""
  
  return 0
}
test "str_trim function" test_str_trim

# Test str_to_upper
test_str_to_upper() {
  # Mixed case
  assert_eq "$(str_to_upper "Hello World")" "HELLO WORLD"
  
  # Already uppercase
  assert_eq "$(str_to_upper "HELLO")" "HELLO"
  
  # Lowercase
  assert_eq "$(str_to_upper "hello")" "HELLO"
  
  # With numbers and symbols
  assert_eq "$(str_to_upper "Hello123!@#")" "HELLO123!@#"
  
  # Empty string
  assert_eq "$(str_to_upper "")" ""
  
  return 0
}
test "str_to_upper function" test_str_to_upper

# Test str_to_lower
test_str_to_lower() {
  # Mixed case
  assert_eq "$(str_to_lower "Hello World")" "hello world"
  
  # Already lowercase
  assert_eq "$(str_to_lower "hello")" "hello"
  
  # Uppercase
  assert_eq "$(str_to_lower "HELLO")" "hello"
  
  # With numbers and symbols
  assert_eq "$(str_to_lower "HELLO123!@#")" "hello123!@#"
  
  # Empty string
  assert_eq "$(str_to_lower "")" ""
  
  return 0
}
test "str_to_lower function" test_str_to_lower

# Test str_length
test_str_length() {
  # Normal string
  assert_eq "$(str_length "Hello World")" "11"
  
  # Empty string
  assert_eq "$(str_length "")" "0"
  
  # With special characters
  assert_eq "$(str_length "Hello, World!")" "13"
  
  # Unicode characters (assuming your locale supports it)
  assert_eq "$(str_length "café")" "4"
  
  return 0
}
test "str_length function" test_str_length

# Test str_replace
test_str_replace() {
  # Replace single occurrence
  assert_eq "$(str_replace "Hello World" "World" "Universe")" "Hello Universe"
  
  # Replace multiple occurrences
  assert_eq "$(str_replace "Hello Hello Hello" "Hello" "Hi")" "Hi Hi Hi"
  
  # Replace with empty string
  assert_eq "$(str_replace "Hello World" "World" "")" "Hello "
  
  # Replace non-existent substring
  assert_eq "$(str_replace "Hello World" "Universe" "Nowhere")" "Hello World"
  
  # Empty base string
  assert_eq "$(str_replace "" "test" "replace")" ""
  
  return 0
}
test "str_replace function" test_str_replace 