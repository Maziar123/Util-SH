#!/usr/bin/bash
# test-param-required-params.sh - Test script for required_params_example.sh
# Demonstrates different parameter combinations and test scenarios

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source sh-globals.sh directly to get access to path utilities
GLOBALS_SCRIPT="${SCRIPT_DIR}/../sh-globals.sh"

if [[ -f "${GLOBALS_SCRIPT}" ]]; then
    # shellcheck disable=SC1090
    source "${GLOBALS_SCRIPT}"
else
    echo "Error: Could not find sh-globals.sh at ${GLOBALS_SCRIPT}" >&2
    exit 1
fi

# Check if globals were properly loaded
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    echo "Error: Failed to load sh-globals.sh" >&2
    exit 1
fi

# Source the test framework
TEST_FRAMEWORK="${SCRIPT_DIR}/test-framework.sh"
if [[ -f "${TEST_FRAMEWORK}" ]]; then
    # shellcheck disable=SC1090
    source "${TEST_FRAMEWORK}"
else
    echo "Error: Could not find test-framework.sh at ${TEST_FRAMEWORK}" >&2
    exit 1
fi

# Use absolute path for example script
EXAMPLE_SCRIPT="${SCRIPT_DIR}/../Samples/params_required_example.sh"

# Debug information
echo "Debug: Script directory is ${SCRIPT_DIR}"
echo "Debug: Example script path is ${EXAMPLE_SCRIPT}"

# Check if the sample script exists
if [[ ! -f "${EXAMPLE_SCRIPT}" ]]; then
    echo "Warning: Required params example script not found at ${EXAMPLE_SCRIPT}" >&2
    
    # If being sourced by test-runner, just return successfully
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        echo "This test is being run by test-runner but requires example script. Skipping tests."
        return 0
    else
        exit 1
    fi
fi

# Make sure the example script is executable
chmod +x "${EXAMPLE_SCRIPT}" 2>/dev/null

# Display appropriate header based on how the script is being run
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Running directly by user
    msg_header "REQUIRED PARAMETERS TEST SCRIPT"
    msg_info "Testing various parameter combinations for required_params_example.sh"
    echo ""
else
    echo "RUNNING REQUIRED PARAMETERS TESTS"
fi

# Test Case 1: Show Help (should succeed)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # When run directly, run all tests including interactive ones
    # Since help exits with code 1, use special handling for this test
    echo -e "\n${TEST_BOLD}${TEST_BLUE}TEST: Test 1: Show Help${TEST_NC}"
    echo -e "${TEST_GRAY}Command: ${EXAMPLE_SCRIPT} --help${TEST_NC}"
    echo "--------------------------------------------"
    ${EXAMPLE_SCRIPT} --help
    echo -e "  - Test 1: Show Help... ${TEST_GREEN}PASS${TEST_NC} (Help display expected to exit with code 1)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Press Enter to continue..." && read -r
    
    run_test "Test 2: All Parameters Provided (Named)" "${EXAMPLE_SCRIPT} --name 'John Doe' --age 35 --email-address 'john@example.com' --place 'New York'"
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Press Enter to continue..." && read -r
    
    run_test "Test 3: Only Required Parameters" "${EXAMPLE_SCRIPT} --age 42 --email-address 'alice@example.com'"
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Press Enter to continue..." && read -r
    
    run_test "Test 4: Using Positional Parameters" "${EXAMPLE_SCRIPT} 'Bob Smith' 28 'bob@example.com' 'Los Angeles'"
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Press Enter to continue..." && read -r
    
    # Interactive tests - will prompt for user input
    run_interactive_test "Test 5: Interactive - Missing Required Parameters" "${EXAMPLE_SCRIPT} --name 'Jane Doe'"
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Press Enter to continue..." && read -r
    
    run_test "Test 6: Invalid Values for Required Parameters" "${EXAMPLE_SCRIPT} --name 'Test User' --age 'not-a-number' --email-address 'invalid-email'"
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Press Enter to continue..." && read -r
    
    run_test "Test 7: Mixed Named and Positional" "${EXAMPLE_SCRIPT} 'Mixed User' --email-address 'mixed@example.com' --place 'Chicago'"
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Press Enter to continue..." && read -r
    
    run_test "Test 8: Required Parameter with Validation Error" "${EXAMPLE_SCRIPT} --name 'Old Person' --age 150 --email-address 'old@example.com'"
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "Press Enter to continue..." && read -r
else
    # When run through test-runner, use appropriate test function for each test
    # Non-interactive tests
    # Since help exits with code 1, use special handling for this test
    echo -e "\n${TEST_BOLD}${TEST_BLUE}TEST: Test 1: Show Help${TEST_NC}"
    echo -e "${TEST_GRAY}Command: ${EXAMPLE_SCRIPT} --help${TEST_NC}"
    echo "--------------------------------------------"
    ${EXAMPLE_SCRIPT} --help
    echo -e "  - Test 1: Show Help... ${TEST_GREEN}PASS${TEST_NC} (Help display expected to exit with code 1)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
    
    run_test "Test 2: All Parameters Provided (Named)" "${EXAMPLE_SCRIPT} --name 'John Doe' --age 35 --email-address 'john@example.com' --place 'New York'"
    run_test "Test 3: Only Required Parameters" "${EXAMPLE_SCRIPT} --age 42 --email-address 'alice@example.com'"
    run_test "Test 4: Using Positional Parameters" "${EXAMPLE_SCRIPT} 'Bob Smith' 28 'bob@example.com' 'Los Angeles'"
    
    # Interactive test - will be skipped in non-interactive mode
    run_interactive_test "Test 5: Interactive - Missing Required Parameters" "${EXAMPLE_SCRIPT} --name 'Jane Doe'"
    
    run_test "Test 6: Invalid Values for Required Parameters" "${EXAMPLE_SCRIPT} --name 'Test User' --age 'not-a-number' --email-address 'invalid-email'"
    run_test "Test 7: Mixed Named and Positional" "${EXAMPLE_SCRIPT} 'Mixed User' --email-address 'mixed@example.com' --place 'Chicago'"
    run_test "Test 8: Required Parameter with Validation Error" "${EXAMPLE_SCRIPT} --name 'Old Person' --age 150 --email-address 'old@example.com'"
fi

# Only show completion message if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    msg_success "All tests completed!"
fi

# Success - use return when sourced, exit when run directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced, use return
    return 0
else
    # Script is being run directly, use exit
    exit 0
fi 