#!/usr/bin/env bash
# test-message-functions.sh - Tests for message functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Group for message functions
test_group "Message Functions"

# Helper function to capture output
capture_output() {
  local func_name="$1"
  shift
  local output
  output=$("$func_name" "$@" 2>&1)
  echo "$output"
}

# Test msg
test_msg() {
  # Basic message
  local output
  output=$(capture_output msg "Hello World")
  assert_eq "$output" "Hello World" "Basic message output incorrect"
  
  # Empty message
  output=$(capture_output msg "")
  assert_eq "$output" "" "Empty message output incorrect"
  
  # Message with special characters
  output=$(capture_output msg "Hello * World!")
  assert_eq "$output" "Hello * World!" "Special chars message output incorrect"
  
  return 0
}
test "msg function" test_msg

# Test msg_info
test_msg_info() {
  # Check that the function exists
  assert_success "type msg_info >/dev/null 2>&1" "msg_info function does not exist"
  
  # We can't easily check color output in unit tests
  # But we can check that it runs without error
  assert_success "msg_info 'Test message' >/dev/null 2>&1" "msg_info failed to run"
  
  return 0
}
test "msg_info function" test_msg_info

# Test msg_success
test_msg_success() {
  # Check that the function exists
  assert_success "type msg_success >/dev/null 2>&1" "msg_success function does not exist"
  
  # We can't easily check color output in unit tests
  # But we can check that it runs without error
  assert_success "msg_success 'Test message' >/dev/null 2>&1" "msg_success failed to run"
  
  return 0
}
test "msg_success function" test_msg_success

# Test msg_warning
test_msg_warning() {
  # Check that the function exists
  assert_success "type msg_warning >/dev/null 2>&1" "msg_warning function does not exist"
  
  # We can't easily check color output in unit tests
  # But we can check that it runs without error
  assert_success "msg_warning 'Test message' >/dev/null 2>&1" "msg_warning failed to run"
  
  return 0
}
test "msg_warning function" test_msg_warning

# Test msg_error
test_msg_error() {
  # Check that the function exists
  assert_success "type msg_error >/dev/null 2>&1" "msg_error function does not exist"
  
  # We can't easily check color output in unit tests
  # But we can check that it runs without error
  assert_success "msg_error 'Test message' >/dev/null 2>&1" "msg_error failed to run"
  
  return 0
}
test "msg_error function" test_msg_error

# Test msg_highlight
test_msg_highlight() {
  # Check that the function exists
  assert_success "type msg_highlight >/dev/null 2>&1" "msg_highlight function does not exist"
  
  # We can't easily check color output in unit tests
  # But we can check that it runs without error
  assert_success "msg_highlight 'Test message' >/dev/null 2>&1" "msg_highlight failed to run"
  
  return 0
}
test "msg_highlight function" test_msg_highlight

# Test msg_header
test_msg_header() {
  # Check that the function exists
  assert_success "type msg_header >/dev/null 2>&1" "msg_header function does not exist"
  
  # We can't easily check color output in unit tests
  # But we can check that it runs without error
  assert_success "msg_header 'Test message' >/dev/null 2>&1" "msg_header failed to run"
  
  return 0
}
test "msg_header function" test_msg_header

# Test msg_section
test_msg_section() {
  # Check that the function exists
  assert_success "type msg_section >/dev/null 2>&1" "msg_section function does not exist"
  
  # Test with a title (we can check basic pattern without color)
  local output
  output=$(msg_section "Test Section" 20 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g")
  
  # Should have a pattern like "==== Test Section ===="
  assert "echo '$output' | grep -q 'Test Section'" "Section title not found in output"
  assert "echo '$output' | grep -q '='" "Section separator not found in output"
  
  # Test without a title (just a line)
  output=$(msg_section "" 10 "-" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g")
  assert "echo '$output' | grep -q '^----------$'" "Line separator not correct"
  
  return 0
}
test "msg_section function" test_msg_section

# Test msg_subtle
test_msg_subtle() {
  # Check that the function exists
  assert_success "type msg_subtle >/dev/null 2>&1" "msg_subtle function does not exist"
  
  # We can't easily check color output in unit tests
  # But we can check that it runs without error
  assert_success "msg_subtle 'Test message' >/dev/null 2>&1" "msg_subtle failed to run"
  
  return 0
}
test "msg_subtle function" test_msg_subtle

# Test msg_color
test_msg_color() {
  # Check that the function exists
  assert_success "type msg_color >/dev/null 2>&1" "msg_color function does not exist"
  
  # Test with a custom color
  assert_success "msg_color 'Test message' '$RED' >/dev/null 2>&1" "msg_color failed with RED"
  assert_success "msg_color 'Test message' '$GREEN' >/dev/null 2>&1" "msg_color failed with GREEN"
  assert_success "msg_color 'Test message' '$BOLD$BLUE' >/dev/null 2>&1" "msg_color failed with BOLD+BLUE"
  
  return 0
}
test "msg_color function" test_msg_color

# Test msg_step
test_msg_step() {
  # Check that the function exists
  assert_success "type msg_step >/dev/null 2>&1" "msg_step function does not exist"
  
  # Test with step numbers and description
  assert_success "msg_step 1 3 'Step one' >/dev/null 2>&1" "msg_step failed to run"
  
  # Get output without color codes
  local output
  output=$(msg_step 2 5 "Testing step" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g")
  
  # Check format
  assert "echo '$output' | grep -q '\[2/5\]'" "Step format incorrect"
  assert "echo '$output' | grep -q 'Testing step'" "Step description missing"
  
  return 0
}
test "msg_step function" test_msg_step

# Test msg_debug
test_msg_debug() {
  # Check that the function exists
  assert_success "type msg_debug >/dev/null 2>&1" "msg_debug function does not exist"
  
  # Test with DEBUG=0 (should not output)
  DEBUG=0
  local output
  output=$(msg_debug "Debug message" 2>&1)
  assert_eq "$output" "" "Debug message should not display when DEBUG=0"
  
  # Test with DEBUG=1 (should output)
  DEBUG=1
  output=$(msg_debug "Debug message" 2>&1 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g")
  assert "echo '$output' | grep -q 'Debug message'" "Debug message not displayed when DEBUG=1"
  
  return 0
}
test "msg_debug function" test_msg_debug 