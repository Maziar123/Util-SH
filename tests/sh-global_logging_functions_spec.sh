#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for LOGGING FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "LOGGING FUNCTIONS"
  BeforeEach "export TEST_LOG_FILE=$(mktemp)"
  AfterEach "rm -f $TEST_LOG_FILE"

  Describe "log_info()"
    It "logs info message"
      log_init "$TEST_LOG_FILE"
      When call log_info "Test info message"
      The status should be success
      The stdout should include "[INFO]"
      The stdout should include "Test info message"
      The contents of file "$TEST_LOG_FILE" should include "INFO: Test info message"
    End
  End

  Describe "log_warn()"
    It "logs warning message"
      log_init "$TEST_LOG_FILE"
      When call log_warn "Test warning message"
      The status should be success
      The stderr should include "[WARN]"
      The stderr should include "Test warning message"
      The contents of file "$TEST_LOG_FILE" should include "WARN: Test warning message"
    End
  End

  Describe "log_error()"
    It "logs error message"
      log_init "$TEST_LOG_FILE"
      When call log_error "Test error message"
      The status should be success
      The stderr should include "[ERROR]"
      The stderr should include "Test error message"
      The contents of file "$TEST_LOG_FILE" should include "ERROR: Test error message"
    End
  End

  Describe "log_debug()"
    Context "when DEBUG is set to 1"
      BeforeEach "export DEBUG=1"
      AfterEach "unset DEBUG"
      
      It "logs debug message"
        log_init "$TEST_LOG_FILE"
        When call log_debug "Test debug message"
        The status should be success
        The stderr should include "[DEBUG]"
        The stderr should include "Test debug message"
        The contents of file "$TEST_LOG_FILE" should include "DEBUG: Test debug message"
      End
    End

    Context "when DEBUG is not set"
      BeforeEach "unset DEBUG"
      
      It "does not log debug message"
        log_init "$TEST_LOG_FILE"
        When call log_debug "Test debug message"
        The status should be success
        The stderr should equal ""
        # File should not contain the debug message
        The contents of file "$TEST_LOG_FILE" should not include "DEBUG: Test debug message"
      End
    End
  End

  Describe "log_success()"
    It "logs success message"
      log_init "$TEST_LOG_FILE"
      When call log_success "Test success message"
      The status should be success
      The stdout should include "[SUCCESS]"
      The stdout should include "Test success message"
      The contents of file "$TEST_LOG_FILE" should include "SUCCESS: Test success message"
    End
  End

  Describe "log_with_timestamp()"
    It "logs message with timestamp"
      log_init "$TEST_LOG_FILE"
      When call log_with_timestamp "INFO" "Test timestamp message"
      The status should be success
      The stdout should include "INFO: Test timestamp message"
      # Use a simpler pattern match for timestamp
      The stdout should include "[20"
      The contents of file "$TEST_LOG_FILE" should include "INFO: Test timestamp message"
    End
  End
End 