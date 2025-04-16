#!/usr/bin/env bash
# test-network-functions.sh - Tests for networking functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Group for networking functions
test_group "Networking Functions"

# Test is_url_reachable
test_is_url_reachable() {
  # Skip the actual network test and just test that the function exists
  assert_success "type is_url_reachable >/dev/null 2>&1" "is_url_reachable function does not exist"
  
  # Mock test - we'll check the function structure but not make actual network requests
  # The function should take at least two arguments (URL and timeout)
  is_url_reachable_args=$(type is_url_reachable | grep -o 'local [^=]*=' | wc -l)
  assert "[ $is_url_reachable_args -ge 2 ]" "is_url_reachable function should take at least URL and timeout arguments"
  
  return 0
}
test "is_url_reachable function" test_is_url_reachable

# Test get_external_ip
test_get_external_ip() {
  # Skip the actual network test and just test that the function exists
  assert_success "type get_external_ip >/dev/null 2>&1" "get_external_ip function does not exist"
  
  return 0
}
test "get_external_ip function" test_get_external_ip

# Test is_port_open
test_is_port_open() {
  # Skip the actual network test and just test that the function exists
  assert_success "type is_port_open >/dev/null 2>&1" "is_port_open function does not exist"
  
  # Mock test - we'll check the function structure
  # The function should take at least three arguments (host, port, timeout)
  is_port_open_args=$(type is_port_open | grep -o 'local [^=]*=' | wc -l)
  assert "[ $is_port_open_args -ge 3 ]" "is_port_open function should take at least host, port, and timeout arguments"
  
  return 0
}
test "is_port_open function" test_is_port_open 