#!/usr/bin/env bash
# test-runner.sh - Runner for sh-globals.sh unit tests
# VERSION: 1.0.0

# Get the directory of this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the test framework
source "$TEST_DIR/test-framework.sh"

# Find all test files matching the new pattern
TEST_FILES=()
for file in "$TEST_DIR"/test-sh-globals-*.sh; do
  # Skip the framework and runner themselves
  if [[ "$file" != "$TEST_DIR/test-framework.sh" && "$file" != "$TEST_DIR/test-runner.sh" ]]; then
    TEST_FILES+=("$file")
  fi
done

# Run all tests
run_test_suite "${TEST_FILES[@]}" 