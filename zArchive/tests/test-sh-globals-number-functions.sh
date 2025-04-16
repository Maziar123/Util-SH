#!/usr/bin/env bash
# test-number-functions.sh - Tests for number formatting functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Group for number functions
test_group "Number Formatting Functions"

# Test format_si_number
test_format_si_number() {
  # Test basic SI formatting
  assert_eq "$(format_si_number 1500)" "1.5K" "Basic SI formatting failed"
  
  # Test larger numbers
  assert_eq "$(format_si_number 1500000)" "1.5M" "Megaunit formatting failed"
  assert_eq "$(format_si_number 1500000000)" "1.5G" "Gigaunit formatting failed"
  
  # Test small numbers
  assert_eq "$(format_si_number 0.001)" "1m" "Milli formatting failed"
  assert_eq "$(format_si_number 0.000001)" "1μ" "Micro formatting failed"
  
  # Test with custom precision
  assert_eq "$(format_si_number 1234567 2)" "1.23M" "Custom precision formatting failed"
  
  # Test value that doesn't need SI prefix
  assert_eq "$(format_si_number 123)" "123" "No-prefix formatting failed"
  
  return 0
}
test "format_si_number function" test_format_si_number

# Test format_bytes
test_format_bytes() {
  # Test basic byte formatting
  assert_eq "$(format_bytes 1024)" "1KB" "Basic byte formatting failed"
  
  # Test larger byte values
  assert_eq "$(format_bytes 1048576)" "1MB" "Megabyte formatting failed"
  assert_eq "$(format_bytes 1073741824)" "1GB" "Gigabyte formatting failed"
  
  # Test with custom precision
  assert_eq "$(format_bytes 1234567 2)" "1.18MB" "Custom precision byte formatting failed"
  
  # Test small value that doesn't need a prefix
  assert_eq "$(format_bytes 123)" "123B" "Small bytes formatting failed"
  
  return 0
}
test "format_bytes function" test_format_bytes 