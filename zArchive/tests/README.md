# Shell Test Framework

A lightweight test framework for shell scripts.

## Overview

This framework provides a simple way to test shell scripts and libraries with minimal setup. It offers:

- Easy test organization with groups
- Support for both command-based and function-based tests
- Interactive and non-interactive test modes
- Basic assertion utilities
- Colorized output for better readability

## Installation

1. Clone or download this repository
2. Add the framework files to your project
3. Make the scripts executable:
   ```bash
   chmod +x test-framework.sh test-runner.sh
   ```

## Test Examples

### Automatic Tests

```bash
#!/usr/bin/env bash
# test-automatic-examples.sh

# Source the test framework
source "./test-framework.sh"

# Source the library under test
source_library "../my-library.sh"

# Example of automatic tests
test_group "Automatic Tests"

# Function-based automatic test
test "validate string length function" test_string_length

test_string_length() {
  local result=$(get_string_length "hello")
  assert_eq "$result" "5" "String length should be 5"
}

# Command-based automatic test
run_test "check file permissions" "[ -x '../my-script.sh' ]"

# Multiple assertions in one test
test "math operations" test_math_operations

test_math_operations() {
  assert_eq "$((2 + 2))" "4" "2 + 2 should equal 4"
  assert "[ 10 -gt 5 ]" "10 should be greater than 5"
  assert_success "echo 'success'" "Echo command should succeed"
}
```

### Interactive Manual Tests

```bash
#!/usr/bin/env bash
# test-interactive-examples.sh

# Source the test framework
source "./test-framework.sh"

# Source the library under test
source_library "../my-interactive-lib.sh"

# Example of interactive tests
test_group "Interactive Manual Tests"

# Simple interactive test with user input
run_interactive_test "validate user confirmation" "
echo 'Please confirm this feature works (y/n):'
read response
if [[ \$response == 'y' ]]; then
  exit 0
else
  exit 1
fi
"

# Interactive test with visual verification
run_interactive_test "check UI rendering" "
generate_test_ui
echo 'Does the UI display correctly with all elements visible? (y/n):'
read response
if [[ \$response == 'y' ]]; then
  exit 0
else
  exit 1
fi
"

# Interactive test that runs automatically in non-interactive mode
# Will be skipped when TEST_NON_INTERACTIVE=1
run_interactive_test "manual timing verification" "
echo 'Performing operation...'
sleep 2
echo 'Was the operation quick enough? (y/n):'
read response
if [[ \$response == 'y' ]]; then
  exit 0
else
  exit 1
fi
"
```

## Usage

### Basic Structure

1. Create a test file for your shell script/library
2. Source the test framework
3. Define and run your tests
4. View the test summary

### Example Test File

```bash
#!/usr/bin/env bash
# test-sh-globals-example.sh

# Source the test framework
source "./test-framework.sh"

# Source the library under test
source_library "../sh-globals.sh"

# Define a test group
test_group "String Functions"

# Simple test
test "should trim whitespace" test_trim_function

test_trim_function() {
  local result=$(trim "  hello world  ")
  assert_eq "$result" "hello world"
}

# Verbose test with output
test_verbose "should convert to uppercase" test_uppercase

test_uppercase() {
  echo $(to_upper "hello")
}

# Command-based test
run_test "file existence check" "[ -f '../sh-globals.sh' ]"

# Skip a test
skip_test "not implemented yet" "Coming soon"

# Interactive test (skipped in non-interactive mode)
run_interactive_test "manual verification" "echo 'Does this look right? (y/n)'; read response"
```

### Running Tests

Execute all tests by running the test-runner.sh script:

```bash
./test-runner.sh
```

## Available Functions

### Test Organization

- `source_library <path>`: Source the shell script/library to test
- `test_group <name>`: Create a named group of tests
- `run_test_suite <file1> [<file2> ...]`: Run multiple test files

### Test Execution

- `test <description> <function>`: Run a test function with description
- `test_verbose <description> <function>`: Run a test with output displayed
- `run_test <description> <command>`: Run a command-based test
- `run_interactive_test <description> <command>`: Run an interactive test
- `skip_test <description> [<reason>]`: Skip a test with optional reason

### Assertions

- `assert <condition> [<message>]`: Assert that a condition is true
- `assert_eq <actual> <expected> [<message>]`: Assert that two values are equal
- `assert_success <command> [<message>]`: Assert that a command succeeds
- `assert_failure <command> [<message>]`: Assert that a command fails

### Utilities

- `test_create_temp_dir`: Create a temporary test directory
- `test_cleanup_temp_dir <dir>`: Clean up a temporary test directory
- `test_summary`: Print test results summary and exit with appropriate code

## Environment Variables

- `TEST_VERBOSE=1`: Enable verbose output
- `TEST_NON_INTERACTIVE=1`: Skip interactive tests

## Advanced Usage

### Testing File Operations

```bash
test "should create and write to file" test_file_operations

test_file_operations() {
  # Create temp directory
  local test_dir=$(test_create_temp_dir)
  
  # Run test
  local test_file="$test_dir/test.txt"
  echo "test content" > "$test_file"
  
  assert "[ -f '$test_file' ]" "File should exist"
  assert_eq "$(cat "$test_file")" "test content" "File content should match"
  
  # Cleanup
  test_cleanup_temp_dir "$test_dir"
}
```

### Custom Test Runner

```bash
#!/usr/bin/env bash
# custom-test-runner.sh

source "./test-framework.sh"

# Run with non-interactive mode
export TEST_NON_INTERACTIVE=1

# Only run specific test files
run_test_suite "./tests/test-core-functions.sh" "./tests/test-advanced-functions.sh"
```

## Troubleshooting

### Common Issues

1. **Tests hang or timeout**
   - Check for infinite loops in your test code
   - Ensure interactive prompts aren't blocking in non-interactive mode

2. **Test framework not found**
   - Verify paths in your test scripts
   - Check that source commands use the correct relative paths

3. **Colors not displaying**
   - Some terminals may not support ANSI color codes
   - Set `TEST_NO_COLOR=1` to disable colors

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/awesome-feature`)
3. Commit your changes (`git commit -m 'Add awesome feature'`)
4. Push to the branch (`git push origin feature/awesome-feature`)
5. Open a Pull Request

## License

[MIT License](LICENSE) 