#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for MESSAGE FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "MESSAGE FUNCTIONS"
  # These functions primarily deal with colored output to stdout/stderr.
  # Testing exact color codes can be brittle. We'll check for content and stream.

  Describe "msg()"
    It "prints message to stdout"
      When call msg "Plain message"
      The status should be success
      The output should equal "Plain message"
      The stderr should equal ""
    End
  End

  Describe "msg_info()"
    It "prints info message to stdout"
      When call msg_info "Info message"
      The status should be success
      The output should include "Info message" # Check content, ignore color codes
      The stderr should equal ""
    End
  End

  Describe "msg_success()"
    It "prints success message to stdout"
      When call msg_success "Success message"
      The status should be success
      The output should include "Success message"
      The stderr should equal ""
    End
  End

  Describe "msg_warning()"
    It "prints warning message to stderr"
      When call msg_warning "Warning message"
      The status should be success
      The output should equal ""
      The stderr should include "Warning message"
    End
  End

  Describe "msg_error()"
    It "prints error message to stderr"
      When call msg_error "Error message"
      The status should be success
      The output should equal ""
      The stderr should include "Error message"
    End
  End

  Describe "msg_highlight()"
    It "prints highlighted message to stdout"
      When call msg_highlight "Highlight message"
      The status should be success
      The output should include "Highlight message"
      The stderr should equal ""
    End
  End

  Describe "msg_header()"
    It "prints header message to stdout"
      When call msg_header "Header message"
      The status should be success
      The output should include "Header message"
      The stderr should equal ""
    End
  End

  Describe "msg_section()"
    It "prints section divider with text"
      When call msg_section "Section Text" 40 "-"
      The status should be success
      The output should include "Section Text"
      # Match pattern allowing for ANSI codes and padding
      The output should match pattern '*---* Section Text *---*'
    End
     It "prints section divider without text"
       When call msg_section "" 40 "="
       The status should be success
       # Match pattern allowing for ANSI codes
       The output should match pattern '*====*====*' # Looser check for '=' chars
       # Checking exact length with ANSI codes is hard, checking presence is better
       The output should include "========================================" # Check the core part
     End
  End

  Describe "msg_subtle()"
    It "prints subtle message to stdout"
      When call msg_subtle "Subtle message"
      The status should be success
      The output should include "Subtle message"
      The stderr should equal ""
    End
  End

  Describe "msg_color()"
    It "prints message with specified color (using RED)"
      # Using RED constant defined in sh-globals.sh
      When call msg_color "Red message" "$RED"
      The status should be success
      The output should include "Red message"
      # Check if it contains the basic escape code part
      The output should include $'\e['
    End
  End

  Describe "msg_step()"
    It "prints step message to stdout"
      When call msg_step 3 10 "Doing step 3"
      The status should be success
      The output should include "[3/10]"
      The output should include "Doing step 3"
      The stderr should equal ""
    End
  End

  Describe "msg_debug()"
    Context "when DEBUG is set"
      BeforeEach "export DEBUG=1"
      AfterEach "unset DEBUG"
      It "prints debug message to stderr"
        When call msg_debug "Debug message content"
        The status should be success
        The output should equal ""
        The stderr should include "[DEBUG]"
        The stderr should include "Debug message content"
      End
    End
    Context "when DEBUG is not set"
      BeforeEach "unset DEBUG"
      It "prints nothing"
        When call msg_debug "Should not see this"
        The status should be success
        The output should equal ""
        The stderr should equal ""
      End
    End
  End
End 