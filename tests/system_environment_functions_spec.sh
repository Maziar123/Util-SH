#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for SYSTEM & ENVIRONMENT FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "SYSTEM & ENVIRONMENT FUNCTIONS"
  Describe "env_or_default()"
    It "returns environment variable value if set"
      export TEST_VAR="test_value"
      When call env_or_default "TEST_VAR" "default_value"
      The status should be success
      The output should equal "test_value"
      unset TEST_VAR
    End

    It "returns default value if environment variable is not set"
      unset TEST_VAR
      When call env_or_default "TEST_VAR" "default_value"
      The status should be success
      The output should equal "default_value"
    End
  End

  Describe "is_root()"
    # This function depends on the current user, so it's hard to test both outcomes
    It "checks if user is root"
      When call is_root
      # We can check for one of two results using the helper
      The status should satisfy check_status_is_0_or_1
    End
  End

  Describe "get_current_user()"
    It "returns current username"
      When call get_current_user
      The status should be success
      The output should not equal ""
    End
  End

  Describe "get_hostname()"
    It "returns hostname"
      When call get_hostname
      The status should be success
      The output should not equal ""
    End
  End

  # Add test for parse_flags
  Describe "parse_flags()"
    It "sets global flags based on arguments"
      # Define some dummy flags for testing
      DEBUG=0; QUIET=0; VERBOSE=0; FORCE=0; HELP=0; VERSION=0;
      When call parse_flags --debug --verbose --force --help --version --unknown
      The status should be success
      The variable DEBUG should equal 1
      The variable QUIET should equal 0 # Not passed
      The variable VERBOSE should equal 1
      The variable FORCE should equal 1
      The variable HELP should equal 1
      The variable VERSION should equal 1
    End
  End
  
  # Add test for require_root (this will likely fail if not run as root)
  Describe "require_root()"
    Context "when run as non-root (expected)"
      # Use the helper function for the condition
      Skip if "cannot reliably test root check unless run as root" is_running_as_root
      It "exits with error 1"
         # Use run to capture exit status from subshell
         When run require_root
         The status should equal 1
         The stderr should include "This script must be run as root"
       End
    End
    # Context "when run as root"
    #   Skip unless "run as root" is_running_as_root # Updated commented section too
    #   It "does not exit"
    #      When call require_root
    #      The status should be success
    #   End
    # End
  End

End 