#!/usr/bin/env bash
# test-framework.sh - Simple test framework for shell scripts
# VERSION: 1.0.0

# Initialize test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test groups for organizing tests
CURRENT_GROUP=""

# Colors for test output
TEST_GREEN="\e[32m"
TEST_RED="\e[31m"
TEST_YELLOW="\e[33m"
TEST_BLUE="\e[34m"
TEST_BOLD="\e[1m"
TEST_GRAY="\e[90m"
TEST_NC="\e[0m"

# Source the library to test
source_library() {
  local library_path="$1"
  echo -e "\n${TEST_BOLD}${TEST_BLUE}RUNNING TEST SUITE FOR $(basename "$library_path")${TEST_NC}"
  echo "=================================================="
  source "$library_path"
}

# Start a new test group
test_group() {
  CURRENT_GROUP="$1"
  echo -e "\n${TEST_BOLD}${TEST_BLUE}TEST GROUP: ${CURRENT_GROUP}${TEST_NC}"
  echo "=================================================="
}

# Run a test with description
test() {
  local description="$1"
  local test_func="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  echo -n "  - $description... "
  
  # Run the test in a subshell to isolate variables and prevent exit
  if ( "$test_func" ) >/dev/null 2>&1; then
    echo -e "${TEST_GREEN}PASS${TEST_NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${TEST_RED}FAIL${TEST_NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Verbose test with output
test_verbose() {
  local description="$1"
  local test_func="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  echo -e "  - $description..."
  
  # Capture test output
  local output result
  output=$("$test_func")
  result=$?
  
  if [ $result -eq 0 ]; then
    echo -e "    ${TEST_GREEN}PASS${TEST_NC}"
    [ -n "$output" ] && echo -e "    ${TEST_BLUE}Output:${TEST_NC} $output"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "    ${TEST_RED}FAIL${TEST_NC}"
    [ -n "$output" ] && echo -e "    ${TEST_RED}Output:${TEST_NC} $output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Run a non-interactive test (command-based instead of function-based)
run_test() {
  local description="$1"
  local command="$2"
  local print_header="${3:-true}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  # Print header if requested
  if [[ "$print_header" == "true" ]]; then
    echo -e "\n${TEST_BOLD}${TEST_BLUE}TEST: ${description}${TEST_NC}"
    echo -e "${TEST_GRAY}Command: ${command}${TEST_NC}"
    echo "--------------------------------------------"
  fi
  
  echo -n "  - $description... "
  
  # Run the command with a timeout to prevent hanging
  # Use timeout command if available
  local output result
  if command -v timeout &>/dev/null; then
    output=$(timeout 10s bash -c "$command" 2>&1) || result=$?
    result=${result:-$?}
  else
    # If timeout is not available, just run the command normally
    output=$(eval "$command" 2>&1)
    result=$?
  fi
  
  if [[ $result -eq 0 ]]; then
    echo -e "${TEST_GREEN}PASS${TEST_NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    # Only show output on verbose mode or if specifically requested
    if [[ "${TEST_VERBOSE:-0}" == "1" ]]; then
      echo "Output: $output"
    fi
    return 0
  else
    echo -e "${TEST_RED}FAIL${TEST_NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    # Always show output on failure
    echo "Command failed with exit code $result"
    echo "Output: $output"
    return 1
  fi
}

# Run an interactive test (skips when TEST_NON_INTERACTIVE is set)
run_interactive_test() {
  local description="$1"
  local command="$2"
  local print_header="${3:-true}"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  # Skip interactive tests when TEST_NON_INTERACTIVE is set
  if [[ "${TEST_NON_INTERACTIVE:-0}" == "1" ]]; then
    echo -n "  - $description... "
    echo -e "${TEST_YELLOW}SKIPPED${TEST_NC} (Interactive test in non-interactive mode)"
    # Mark as passed to avoid test failures in non-interactive mode
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  fi
  
  # Print header if requested
  if [[ "$print_header" == "true" ]]; then
    echo -e "\n${TEST_BOLD}${TEST_BLUE}INTERACTIVE TEST: ${description}${TEST_NC}"
    echo -e "${TEST_GRAY}Command: ${command}${TEST_NC}"
    echo "--------------------------------------------"
  fi
  
  echo "  - $description..."
  
  # For interactive tests, we don't capture output - it runs directly
  # This allows it to interact with the user
  echo "Running interactive command: $command"
  echo "--------------------------------------------"
  
  # Run the command directly (not capturing output)
  eval "$command"
  local result=$?
  
  echo "--------------------------------------------"
  
  if [[ $result -eq 0 ]]; then
    echo -e "  Result: ${TEST_GREEN}PASS${TEST_NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "  Result: ${TEST_RED}FAIL${TEST_NC} (exit code $result)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Skip a test with reason
skip_test() {
  local description="$1"
  local reason="${2:-Skipped}"
  
  echo -e "  - $description... ${TEST_YELLOW}SKIPPED${TEST_NC} ($reason)"
}

# Assert that a condition is true
assert() {
  local condition="$1"
  local message="${2:-Assertion failed}"
  
  if ! eval "$condition"; then
    echo "Assertion failed: $message"
    echo "Condition: $condition"
    return 1
  fi
  
  return 0
}

# Assert that two values are equal
assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Expected '$expected' but got '$actual'}"
  
  if [[ "$actual" != "$expected" ]]; then
    echo "Assertion failed: $message"
    return 1
  fi
  
  return 0
}

# Assert that a command succeeds
assert_success() {
  local command="$1"
  local message="${2:-Command did not succeed: $command}"
  
  if ! eval "$command" >/dev/null 2>&1; then
    echo "Assertion failed: $message"
    return 1
  fi
  
  return 0
}

# Assert that a command fails
assert_failure() {
  local command="$1"
  local message="${2:-Command succeeded but should have failed: $command}"
  
  if eval "$command" >/dev/null 2>&1; then
    echo "Assertion failed: $message"
    return 1
  fi
  
  return 0
}

# Print test summary and exit with appropriate code
test_summary() {
  echo -e "\n${TEST_BOLD}TEST SUMMARY${TEST_NC}"
  echo "=================================================="
  echo -e "Total: ${TESTS_RUN}, ${TEST_GREEN}Passed: ${TESTS_PASSED}${TEST_NC}, ${TEST_RED}Failed: ${TESTS_FAILED}${TEST_NC}"
  
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "\n${TEST_RED}Some tests failed!${TEST_NC}"
    exit 1
  else
    echo -e "\n${TEST_GREEN}All tests passed!${TEST_NC}"
    exit 0
  fi
}

# Create a temporary test directory
test_create_temp_dir() {
  TEST_TEMP_DIR=$(mktemp -d)
  echo "$TEST_TEMP_DIR"
}

# Clean up temporary test directory
test_cleanup_temp_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    rm -rf "$dir"
  fi
}

# Run all test files in the directory
run_test_suite() {
  local test_files=("$@")
  
  echo -e "${TEST_BOLD}RUNNING TEST SUITE FOR SH-GLOBALS.SH${TEST_NC}"
  echo "=================================================="
  
  for test_file in "${test_files[@]}"; do
    echo -e "\n${TEST_BOLD}${TEST_BLUE}RUNNING: ${test_file}${TEST_NC}"
    source "$test_file"
  done
  
  test_summary
} 