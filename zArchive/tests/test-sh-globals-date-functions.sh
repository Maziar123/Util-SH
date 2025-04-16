#!/usr/bin/env bash
# test-date-functions.sh - Tests for date and time functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Group for date and time functions
test_group "Date & Time Functions"

# Test get_timestamp
test_get_timestamp() {
  # Get timestamp
  local timestamp
  timestamp=$(get_timestamp)
  
  # Check that it's a number greater than 0
  assert "[ $timestamp -gt 0 ]" "Timestamp should be a positive number"
  
  # Check that it's a 10-digit number (Unix timestamp format)
  assert "[ ${#timestamp} -ge 10 ]" "Timestamp should be at least 10 digits"
  
  return 0
}
test "get_timestamp function" test_get_timestamp

# Test format_date
test_format_date() {
  # Define a specific timestamp for consistent testing (Jan 1, 2023 at 12:00:00 GMT)
  local test_timestamp=1672574400
  
  # Test basic date formatting
  assert "echo $(format_date '%Y-%m-%d' $test_timestamp) | grep -q '2023-01-01'" "Year-month-day formatting failed"
  
  # Test different format
  assert "echo $(format_date '%H:%M:%S' $test_timestamp) | grep -q '12:00:00'" "Hour:minute:second formatting failed"
  
  # Test current date (no timestamp provided)
  assert "format_date '%Y' | grep -q -E '^[0-9]{4}$'" "Current year formatting failed"
  
  return 0
}
test "format_date function" test_format_date

# Test time_diff_human
test_time_diff_human() {
  # Test seconds
  assert_eq "$(time_diff_human 1000 1030)" "30s" "Seconds difference failed"
  
  # Test minutes and seconds
  assert_eq "$(time_diff_human 1000 1090)" "1m 30s" "Minutes and seconds difference failed"
  
  # Test hours, minutes, seconds
  assert_eq "$(time_diff_human 1000 4830)" "1h 3m 50s" "Hours, minutes, seconds difference failed"
  
  # Test days, hours, minutes, seconds
  assert_eq "$(time_diff_human 1000 94430)" "1d 2h 3m 50s" "Days, hours, minutes, seconds difference failed"
  
  return 0
}
test "time_diff_human function" test_time_diff_human 