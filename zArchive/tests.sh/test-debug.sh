#!/usr/bin/bash
# Debug script to test the run_test function

# Source the test framework
source "$(dirname "$0")/tests/test-framework.sh"

# Run a simple test that should succeed
echo "Running a simple test that should succeed:"
run_test "Echo test" "echo 'This is a test'" 

# Run a simple test that should fail
echo -e "\nRunning a simple test that should fail:"
run_test "Fail test" "false"

echo -e "\nDone!" 