#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for PATH NAVIGATION FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "PATH NAVIGATION FUNCTIONS"
  # Setup/Teardown using helpers defined in spec_helper.sh
  BeforeAll "path_setup"
  AfterAll "path_teardown"

  Describe "get_parent_dir()"
    It "returns the parent directory"
      When call get_parent_dir "$TEST_BASE_DIR/level1/level2"
      The status should be success
      The output should equal "$TEST_BASE_DIR/level1"
    End
     It "handles root directory"
       When call get_parent_dir "/"
       The status should be success
       The output should equal "/"
     End
     It "handles current directory if no arg"
       # Need to run in a subshell to control pwd
       test_pwd() {
         cd "$TEST_BASE_DIR/level1"
         get_parent_dir
       }
       When call test_pwd
       The status should be success
       The output should equal "$TEST_BASE_DIR"
     End
  End

  Describe "get_parent_dir_n()"
    It "returns parent N levels up"
      When call get_parent_dir_n "$TEST_BASE_DIR/level1/level2/level3" 2
      The status should be success
      The output should equal "$TEST_BASE_DIR/level1"
    End
    It "returns correct path for N=1"
      When call get_parent_dir_n "$TEST_BASE_DIR/level1/level2/level3" 1
      The status should be success
      The output should equal "$TEST_BASE_DIR/level1/level2"
    End
     It "handles going up from root"
       When call get_parent_dir_n "/" 3
       The status should be success
       The output should equal "/"
     End
  End

  Describe "path_relative_to_script()"
    It "returns absolute path relative to mocked script dir"
      # Mock get_script_dir is active from BeforeAll
      When call path_relative_to_script "../file1.txt"
      The status should be success
      The output should equal "$TEST_BASE_DIR/level1/file1.txt"
    End
     It "handles path in the same directory"
       When call path_relative_to_script "mock_script.sh"
       The status should be success
       The output should equal "$SCRIPT_LOC"
     End
  End

  Describe "to_absolute_path()"
    It "converts relative path to absolute using pwd"
       # Need to run in a subshell to control pwd
       test_abs() {
         cd "$TEST_BASE_DIR/level1"
         to_absolute_path "./level2/level3"
       }
       When call test_abs
       The status should be success
       The output should equal "$TEST_BASE_DIR/level1/level2/level3"
    End
     It "converts relative path using specified base dir"
       When call to_absolute_path "../file1.txt" "$TEST_BASE_DIR/level1/level2"
       The status should be success
       The output should equal "$TEST_BASE_DIR/level1/file1.txt"
     End
     It "returns absolute path unchanged"
       When call to_absolute_path "/etc/hosts" # Assuming /etc/hosts exists
       The status should be success
       The output should equal "/etc/hosts"
     End
  End

  Describe "source_relative()"
     # Requires mocking 'source' or creating actual files to source
     Skip "Complex to test 'source' reliably within ShellSpec"
     It "sources a file relative to the script"
       # Mock get_script_dir is active
       # Create a dummy file to source
       SOURCE_TARGET="$TEST_BASE_DIR/level1/level2/lib.sh"
       echo ' sourced_var="sourced_value" ' > "$SOURCE_TARGET"
       # How to test source? Check side effects (variables) in the current shell.
       # Shellspec runs 'When call' in subshell by default, making variable checks hard.
       # Maybe use 'run source' but that also has isolation.
       # This needs a different approach, maybe checking if the source command runs without error.
       When call source_relative "lib.sh"
       The status should be success # At least check it finds and attempts to source
       # Cleanup
       rm -f "$SOURCE_TARGET"
     End
     It "fails if file not found"
       When call source_relative "nonexistent_lib.sh"
       The status should be failure
       The stderr should include "Cannot source file, not found"
     End
     Todo "Improve source_relative test if possible"
  End

  Describe "source_with_fallbacks()"
     Skip "Complex to test 'source' reliably within ShellSpec"
     # Similar issues as source_relative with testing side effects of 'source'.
     BeforeEach '
       rm -f "$TEST_BASE_DIR/utils.sh" "$TEST_BASE_DIR/level1/utils.sh" /tmp/global_utils.sh
     '
     It "sources file relative to script first"
       # Mock get_script_dir points to level1/level2
       echo ' sourced_marker="script_dir" ' > "$TEST_BASE_DIR/level1/level2/utils.sh"
       When call source_with_fallbacks "utils.sh" "../utils.sh" "/tmp/global_utils.sh"
       The status should be success
       # Check side effect if possible
       rm -f "$TEST_BASE_DIR/level1/level2/utils.sh"
     End
     It "sources file from fallback path relative to script"
        echo ' sourced_marker="fallback_relative" ' > "$TEST_BASE_DIR/level1/utils.sh" # Fallback relative path
        When call source_with_fallbacks "utils.sh" "../utils.sh" "/tmp/global_utils.sh"
        The status should be success
        rm -f "$TEST_BASE_DIR/level1/utils.sh"
     End
     It "sources file from absolute fallback path"
        echo ' sourced_marker="fallback_absolute" ' > "/tmp/global_utils.sh" # Absolute fallback
        When call source_with_fallbacks "utils.sh" "../utils.sh" "/tmp/global_utils.sh"
        The status should be success
        rm -f "/tmp/global_utils.sh"
     End
     It "fails if no file is found"
        When call source_with_fallbacks "utils.sh" "../utils.sh" "/tmp/global_utils.sh"
        The status should be failure
        The stderr should include "Cannot find file to source: utils.sh"
     End
     Todo "Improve source_with_fallbacks test if possible"
  End

  Describe "parent_path()"
    It "generates ../ string N times"
      When call parent_path 3
      The status should be success
      The output should equal "../../../" # Corrected expectation
    End
     It "generates single ../ for N=1"
       When call parent_path 1
       The status should be success
       The output should equal "../"
     End
     It "generates empty string for N=0"
       When call parent_path 0
       The status should be success
       The output should equal ""
     End
     It "defaults to N=1 if no argument"
       When call parent_path
       The status should be success
       The output should equal "../"
     End
  End
End 