#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for LOGGING INITIALIZATION functions from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "LOGGING INITIALIZATION"
  # Create a temporary log file for testing
  BeforeEach "export TEST_LOG_FILE=$(mktemp)"
  AfterEach "rm -f $TEST_LOG_FILE"

  Describe "log_init()"
    It "initializes logging to a file"
      # Expect stdout output with log message
      When call log_init "$TEST_LOG_FILE"
      The stdout should include "Logging initialized to"
      The status should be success
      The variable _LOG_FILE should equal "$TEST_LOG_FILE"
      The variable _LOG_INITIALIZED should equal 1
      The variable _LOG_TO_FILE should equal 1
    End

    It "initializes console-only logging when save_to_file is 0"
      # Expect stdout output with log message
      When call log_init "$TEST_LOG_FILE" 0
      The stdout should include "Logging initialized"
      The status should be success
      The variable _LOG_INITIALIZED should equal 1
      The variable _LOG_TO_FILE should equal 0
    End
  End

  Describe "_log_to_file()"
    It "writes log message to file"
      log_init "$TEST_LOG_FILE"
      When call _log_to_file "INFO" "Test message"
      The status should be success
      # Check if file contains the log message
      The path "$TEST_LOG_FILE" should be file
      The contents of file "$TEST_LOG_FILE" should include "INFO: Test message"
    End
  End
End 