#!/usr/bin/bash
# test_params_example.sh - Test script for params_example.sh

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the test framework
TEST_FRAMEWORK="${SCRIPT_DIR}/test-framework.sh"
if [[ -f "${TEST_FRAMEWORK}" ]]; then
    # shellcheck disable=SC1090
    source "${TEST_FRAMEWORK}"
else
    echo "Error: Could not find test-framework.sh at ${TEST_FRAMEWORK}" >&2
    exit 1
fi

# Path to the example script
SCRIPT_PATH="${SCRIPT_DIR}/../Samples/params_example.sh"
SCRIPT_NAME="$(basename "${SCRIPT_PATH}")"

echo "=== Testing ${SCRIPT_NAME} ==="

test_group "Parameter Example Tests"

assert_contains() {
    local output="$1"
    local pattern="$2"
    if [[ "$output" == *"$pattern"* ]]; then
        return 0
    else
        echo "Pattern not found: '$pattern' in output: '$output'"
        return 1
    fi
}

test_case() {
    local description="$1"
    local command="$2"
    local expected_pattern="$3"
    
    local output
    output=$($command 2>&1)
    if assert_contains "$output" "$expected_pattern"; then
        echo -e "${TEST_GREEN}PASS${TEST_NC}: $description"
        return 0
    else
        echo -e "${TEST_RED}FAIL${TEST_NC}: $description"
        return 1
    fi
}

test "Named parameters" "test_case 'All named params' '${SCRIPT_PATH} --name John --age 30 --place \"New York\"' 'Name: John'"
test "Positional parameters" "test_case 'All positional params' '${SCRIPT_PATH} David 35 Chicago' 'Name: David'"
test "Mixed parameters" "test_case 'Mixed params' '${SCRIPT_PATH} Grace --place Seattle' 'Name: Grace'"
test "Help display" "test_case 'Help command' '${SCRIPT_PATH} --help' 'Parameter Values:'"

test_summary 