#!/usr/bin/env bash
# test-system-functions.sh - Tests for system and environment functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Group for system functions
test_group "System & Environment Functions"

# Test env_or_default
test_env_or_default() {
  # Set a test environment variable
  export TEST_ENV_VAR="test_value"
  
  # Test getting existing env var
  assert_eq "$(env_or_default TEST_ENV_VAR default)" "test_value" "Getting existing env var failed"
  
  # Test getting default for non-existent env var
  assert_eq "$(env_or_default NONEXISTENT_ENV_VAR default)" "default" "Getting default value failed"
  
  # Clean up
  unset TEST_ENV_VAR
  
  return 0
}
test "env_or_default function" test_env_or_default

# Test is_root
test_is_root() {
  # We can't easily test becoming root, so we'll test the opposite case
  # This assumes the test isn't run as root
  if [ "$(id -u)" -ne 0 ]; then
    assert_eq "$(is_root && echo true || echo false)" "false" "is_root should return false for non-root user"
  else
    # If test is run as root, skip
    skip_test "is_root function" "Test running as root"
  fi
  
  return 0
}
test "is_root function" test_is_root

# Test get_current_user
test_get_current_user() {
  # Get current user from system
  local system_user
  system_user=$(id -un)
  
  # Get user from our function
  local func_user
  func_user=$(get_current_user)
  
  # Compare
  assert_eq "$func_user" "$system_user" "get_current_user should return the current username"
  
  return 0
}
test "get_current_user function" test_get_current_user

# Test get_hostname
test_get_hostname() {
  # Get hostname from system
  local system_hostname
  system_hostname=$(hostname)
  
  # Get hostname from our function
  local func_hostname
  func_hostname=$(get_hostname)
  
  # Compare
  assert_eq "$func_hostname" "$system_hostname" "get_hostname should return the system hostname"
  
  return 0
}
test "get_hostname function" test_get_hostname

# Test get_os
test_get_os() {
  # Just ensure the function returns something
  local os
  os=$(get_os)
  
  assert "[ -n \"$os\" ]" "get_os should return non-empty value"
  
  # Check for common OS names
  assert "echo \"$os\" | grep -qE '^(linux|mac|windows)$'" "get_os should return linux, mac, or windows"
  
  return 0
}
test "get_os function" test_get_os

# Test get_arch
test_get_arch() {
  # Just ensure the function returns something
  local arch
  arch=$(get_arch)
  
  assert "[ -n \"$arch\" ]" "get_arch should return non-empty value"
  
  # Should be a common architecture name
  assert "echo \"$arch\" | grep -qE '^(x86_64|amd64|arm64|i386)'" "get_arch should return a valid architecture"
  
  return 0
}
test "get_arch function" test_get_arch 