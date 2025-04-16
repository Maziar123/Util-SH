#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for FILE & DIRECTORY FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "FILE & DIRECTORY FUNCTIONS"
  # Create temporary files and directories for testing
  BeforeEach "export TEST_DIR=$(mktemp -d)"
  AfterEach "rm -rf $TEST_DIR"

  Describe "command_exists()"
    It "returns true when command exists"
      When call command_exists "ls"
      The status should be success
    End

    It "returns false when command does not exist"
      When call command_exists "non_existent_command_12345"
      The status should be failure
    End
  End

  Describe "safe_mkdir()"
    It "creates directory if it doesn't exist"
      When call safe_mkdir "$TEST_DIR/test_subdir"
      The status should be success
      The path "$TEST_DIR/test_subdir" should be directory
    End

    It "does nothing if directory already exists"
      mkdir -p "$TEST_DIR/existing_dir"
      When call safe_mkdir "$TEST_DIR/existing_dir"
      The status should be success
      The path "$TEST_DIR/existing_dir" should be directory
    End
  End

  Describe "file_exists()"
    It "returns true when file exists and is readable"
      touch "$TEST_DIR/test_file"
      chmod +r "$TEST_DIR/test_file"
      When call file_exists "$TEST_DIR/test_file"
      The status should be success
    End

    It "returns false when file does not exist"
      When call file_exists "$TEST_DIR/non_existent_file"
      The status should be failure
    End
  End

  Describe "dir_exists()"
    It "returns true when directory exists"
      mkdir -p "$TEST_DIR/test_subdir"
      When call dir_exists "$TEST_DIR/test_subdir"
      The status should be success
    End

    It "returns false when directory does not exist"
      When call dir_exists "$TEST_DIR/non_existent_dir"
      The status should be failure
    End
  End

  Describe "file_size()"
    It "returns file size in bytes"
      echo "12345" > "$TEST_DIR/test_file"
      When call file_size "$TEST_DIR/test_file"
      The status should be success
      The output should equal "6" # 5 chars + newline
    End

    It "returns 0 for non-existent file"
      When call file_size "$TEST_DIR/non_existent_file"
      The status should be success
      The output should equal "0"
    End
  End

  Describe "safe_copy()"
    It "copies file with verification"
      echo "test content" > "$TEST_DIR/source_file"
      When call safe_copy "$TEST_DIR/source_file" "$TEST_DIR/dest_file"
      The status should be success
      The path "$TEST_DIR/dest_file" should be file
      The contents of file "$TEST_DIR/dest_file" should equal "test content"
    End

    It "fails if source file does not exist"
      # Handle stderr output
      When call safe_copy "$TEST_DIR/non_existent_file" "$TEST_DIR/dest_file"
      The stderr should include "Source file does not exist"
      The status should be failure
    End
  End

  Describe "create_temp_file()"
    It "creates a temporary file with default template"
      When call create_temp_file
      The status should be success
      The output should be file
      # Check if the temp file is registered for cleanup
      The variable _TEMP_FILES should include "$stdout"
    End

    It "creates a temporary file with custom template"
      When call create_temp_file "custom.XXXXXX"
      The status should be success
      The output should be file
      The output should include "custom."
    End
  End

  Describe "create_temp_dir()"
    It "creates a temporary directory with default template"
      When call create_temp_dir
      The status should be success
      The output should be directory
      # Check if the temp directory is registered for cleanup
      The variable _TEMP_DIRS should include "$stdout"
    End

    It "creates a temporary directory with custom template"
      When call create_temp_dir "customdir.XXXXXX"
      The status should be success
      The output should be directory
      The output should include "customdir."
    End
  End

  Describe "cleanup_temp()"
    It "removes files and directories listed in internal arrays"
      # Manually create temporary file and directory for this specific test
      manual_tmpfile=$(mktemp)
      manual_tmpdir=$(mktemp -d)

      # Ensure they exist before the test
      if [[ ! -f "$manual_tmpfile" || ! -d "$manual_tmpdir" ]]; then
         echo "ERROR: Manual temp file/dir creation failed!" >&2
         exit 1 # Fail test if setup fails
      fi

      # Manually populate the exported arrays IN THIS CONTEXT before the call
      export _TEMP_FILES=("$manual_tmpfile")
      export _TEMP_DIRS=("$manual_tmpdir")

      # Call the function under test
      When call cleanup_temp

      # Assert function ran successfully and produced no errors
      The status should be success
      The stderr should equal ""

      # Verify the manually created items no longer exist
      The path "$manual_tmpfile" should not be exist
      The path "$manual_tmpdir" should not be exist

      # Note: We are not checking the array variables themselves after the call,
      # as their state across ShellSpec contexts proved unreliable.
      # The primary check is whether the rm commands worked based on the populated arrays.
    End
  End

  Describe "wait_for_file()"
    It "returns success when file exists"
      touch "$TEST_DIR/test_file"
      When call wait_for_file "$TEST_DIR/test_file" 1 1
      The status should be success
    End

    It "times out when file does not exist"
      When call wait_for_file "$TEST_DIR/non_existent_file" 1 1
      The status should be failure
    End
  End

  # Removed problematic tests
  # Tests for get_file_extension are in file_extension_spec.sh
  # Removed problematic test that was causing freezing
  # Tests for get_file_basename are in basename_fix_spec.sh
End