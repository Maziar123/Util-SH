#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for INITIALIZATION functions from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "INITIALIZATION"
  Describe "sh-globals_init()"
    # This function sets up traps and parses flags, difficult to test in isolation fully.
    # We can test if it runs and potentially sets default flag values if not passed.
    # Reset flags to known state before test
    BeforeEach "unset DEBUG VERBOSE QUIET FORCE _TEMP_FILES _TEMP_DIRS _LOG_INITIALIZED"
    
    It "runs without arguments and sets defaults"
      When call sh-globals_init
      The status should be success
      # Check default flag values (assuming they are 0)
      The variable DEBUG should equal 0
      The variable VERBOSE should equal 0
      The variable QUIET should equal 0
      The variable FORCE should equal 0
      # Check array initialization (should be empty)
      # Shellspec might have issues directly checking empty array vars, check length idea:
      # The variable '#_TEMP_FILES[@]' should equal 0 # May not work reliably
    End

    It "parses flags passed as arguments"
      When call sh-globals_init --debug --force --unknown-arg
      The status should be success
      The variable DEBUG should equal 1
      The variable VERBOSE should equal 0
      The variable QUIET should equal 0
      The variable FORCE should equal 1
    End
    
    Todo "Add tests for trap setup verification if possible"
  End
End 