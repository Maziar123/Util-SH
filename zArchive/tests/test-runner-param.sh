#!/usr/bin/env bash
# test-runner-param.sh - Runner for param_handler.sh unit tests
# VERSION: 1.0.0

# Get the directory of this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the test framework
source "$TEST_DIR/test-framework.sh"

# Source the param_handler library
source_library "$(dirname "$TEST_DIR")/param_handler.sh"

# Find all param_handler test files
PARAM_TEST_FILES=()
for file in "$TEST_DIR"/test-param*.sh; do
  echo "Found file: $file"
  # Skip the test runner itself
  if [[ "$file" != "$TEST_DIR/test-runner-param.sh" ]]; then
    PARAM_TEST_FILES+=("$file")
    echo "Added to test files list: $file"
  else
    echo "Skipping test runner file: $file"
  fi
done

# Print all test files before running
echo "Test files to run:"
for test_file in "${PARAM_TEST_FILES[@]}"; do
  echo "  - $test_file"
done

# Modified approach: Run each test file in its own subprocess but capture all output
echo -e "\n${TEST_BOLD}RUNNING TESTS INDIVIDUALLY${TEST_NC}"
echo "=================================================="

# Track overall results
OVERALL_TESTS_PASSED=0
OVERALL_TESTS_FAILED=0

for test_file in "${PARAM_TEST_FILES[@]}"; do
  echo -e "\n${TEST_BOLD}${TEST_BLUE}RUNNING: ${test_file}${TEST_NC}"
  
  # Run the test file in a subprocess, set TEST_NON_INTERACTIVE=1 to indicate non-interactive mode
  # This prevents clearing the screen and skips interactive tests
  echo "Running in non-interactive mode (TEST_NON_INTERACTIVE=1)"
  output=$(TEST_NON_INTERACTIVE=1 TEST_VERBOSE=1 bash "$test_file" 2>&1)
  test_result=$?
  
  # Display the captured output
  echo "$output"
  
  if [[ $test_result -eq 0 ]]; then
    ((OVERALL_TESTS_PASSED++))
  else
    ((OVERALL_TESTS_FAILED++))
  fi
  
  # Add a separator between test outputs
  echo -e "\n${TEST_BOLD}${TEST_BLUE}TEST COMPLETE: ${test_file}${TEST_NC}"
  echo "=================================================="
done

# Print overall summary
echo -e "\n${TEST_BOLD}OVERALL TEST SUMMARY${TEST_NC}"
echo "=================================================="
echo -e "Total test files: $((OVERALL_TESTS_PASSED + OVERALL_TESTS_FAILED))"
echo -e "Passed: ${TEST_GREEN}${OVERALL_TESTS_PASSED}${TEST_NC}"
echo -e "Failed: ${TEST_RED}${OVERALL_TESTS_FAILED}${TEST_NC}"

if [[ $OVERALL_TESTS_FAILED -gt 0 ]]; then
  echo -e "\n${TEST_RED}Some test files failed!${TEST_NC}"
  exit 1
else
  echo -e "\n${TEST_GREEN}All test files passed!${TEST_NC}"
  exit 0
fi 