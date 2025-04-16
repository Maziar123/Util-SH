# Unit Tests for Util-Sh

This directory contains unit tests for the components in Util-Sh, including `sh-globals.sh` and `param_handler.sh`.

## Test Framework

The test framework is implemented in `test-framework.sh`. It provides a simple yet powerful way to write and run unit tests for shell scripts.

Features:

- Grouping tests by functionality
- Support for setup and teardown
- Assertions for equality, success/failure, and custom conditions
- Skip tests with reason
- Detailed test summaries
- Temporary test directory creation
- Test isolation

## Running Tests

To run all tests:

```bash
./test-runner.sh
```

To run parameter handler tests:

```bash
./test-runner-param.sh
```

To run a specific test file:

```bash
source test-framework.sh
source <test-file-name>.sh
```

## Available Test Files

### Generic Test Framework

| Test File | Description | Primary Functions | Test Summary |
|-----------|-------------|-------------------|--------------|
| `test-framework.sh` | Core test framework with assertion and test management functions | `test_group`, `test`, `assert_*` | Implements the core testing framework with assertions, setup/teardown, and test tracking functionality |
| `test-runner.sh` | Runner script for all sh-globals tests | N/A | Automatically runs all test files for sh-globals components in the correct order |
| `test-runner-param.sh` | Runner script for parameter handler tests | N/A | Automatically runs all parameter handler test files in the correct order |

### sh-globals Tests

| Test File | Description | Primary Functions Tested | Test Summary |
|-----------|-------------|--------------------------|--------------|
| `test-sh-globals-array-functions.sh` | Tests for array manipulation functions | `array_*` functions | Tests array creation, manipulation, filtering, joining, and iteration functionality |
| `test-sh-globals-cheatsheet.sh` | Quick reference examples for sh-globals functions | Various | Provides practical examples of common functions with expected outputs for reference |
| `test-sh-globals-date-functions.sh` | Tests for date handling utilities | `date_*` functions | Tests date formatting, comparison, validation, and conversion functions |
| `test-sh-globals-file-functions.sh` | Tests for file and directory operations | `file_*` functions | Tests file existence, permissions, content manipulation, path handling, and attributes |
| `test-sh-globals-function-preview.sh` | Function preview and documentation tests | Function documentation system | Tests documentation generation, help text formatting, and function discovery features |
| `test-sh-globals-get-value-functions.sh` | Tests for value retrieval functions | `get_*` functions | Tests interactive input, default values, validation, and environment variable access |
| `test-sh-globals-interactive-demo.sh` | Interactive demonstration of functionality | Various | Showcases interactive usage patterns with examples of common operations |
| `test-sh-globals-message-functions.sh` | Tests for message formatting and display | `message_*` functions | Tests colored output, logging, formatting, error handling, and progress displays |
| `test-sh-globals-network-functions.sh` | Tests for network-related utilities | `network_*` functions | Tests URL validation, connectivity checks, and network interface operations |
| `test-sh-globals-number-functions.sh` | Tests for numeric operations | `number_*` functions | Tests numeric validation, comparison, range checking, and arithmetic operations |
| `test-sh-globals-string-functions.sh` | Tests for string manipulation functions | `string_*` functions | Tests string trimming, padding, validation, case conversion, and pattern matching |
| `test-sh-globals-system-functions.sh` | Tests for system-level operations | `system_*` functions | Tests OS detection, environment handling, process management, and system utilities |

### Parameter Handler Tests

| Test File | Description | Primary Functions Tested | Test Summary |
|-----------|-------------|--------------------------|--------------|
| `test-param-handler.sh` | Core tests for parameter handler functionality | `param_*` functions | Tests parameter parsing, validation, type checking, and default value handling |
| `test-param-handler-edge.sh` | Edge case testing for parameter handling | `param_*` functions | Tests unusual inputs, boundary conditions, and error recovery in parameter handling |
| `test-param-handler-format.sh` | Tests for parameter format validation | `param_*` format functions | Tests format specification validation including regex patterns and type constraints |
| `test-param-required-params.sh` | Tests for required parameter enforcement | `param_required_*` functions | Tests mandatory parameter validation, missing parameter detection, and error reporting |
| `test-params-example.sh` | Example usage patterns for parameter handler | `param_*` functions | Demonstrates practical usage scenarios with example command-line parameter processing |

## Writing New Tests

To create a new test file:

1. Create a file named `test-<category>-functions.sh`
2. Start the file with a test group:

   ```bash
   test_group "Category Name"
   ```

3. Write test functions:

   ```bash
   test_some_function() {
     # Test code here
     assert_eq "$(some_function arg)" "expected_result"
     return 0
   }
   ```

4. Register the test:

   ```bash
   test "Description of the test" test_some_function
   ```

## Available Assertions

- `assert "condition"` - Assert that a condition is true
- `assert_eq "actual" "expected"` - Assert that two values are equal
- `assert_success "command"` - Assert that a command succeeds
- `assert_failure "command"` - Assert that a command fails

## Test Helpers

- `test_create_temp_dir` - Create temporary directory for tests
- `test_cleanup_temp_dir "dir"` - Clean up temporary directory
- `skip_test "description" "reason"` - Skip a test with reason
- `test_verbose "description" "function"` - Run test with output display

## Example

```bash
#!/usr/bin/env bash
# test-example.sh - Example test file

# Group for example functions
test_group "Example Functions"

# Setup for tests
setup_test() {
  # Create test data
  TEST_VAR="test value"
}

# Test function
test_example() {
  setup_test
  
  # Test some function
  assert_eq "$(echo "$TEST_VAR")" "test value"
  
  return 0
}
test "Example test" test_example
``` 
