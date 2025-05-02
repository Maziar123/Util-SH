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

  # Tests for text color functions
  Describe "msg_black()"
    It "prints black colored message to stdout"
      When call msg_black "Black message"
      The status should be success
      The output should include "Black message"
      The stderr should equal ""
    End
  End

  Describe "msg_red()"
    It "prints red colored message to stdout"
      When call msg_red "Red message"
      The status should be success
      The output should include "Red message"
      The stderr should equal ""
    End
  End

  Describe "msg_green()"
    It "prints green colored message to stdout"
      When call msg_green "Green message"
      The status should be success
      The output should include "Green message"
      The stderr should equal ""
    End
  End

  Describe "msg_yellow()"
    It "prints yellow colored message to stdout"
      When call msg_yellow "Yellow message"
      The status should be success
      The output should include "Yellow message"
      The stderr should equal ""
    End
  End

  Describe "msg_blue()"
    It "prints blue colored message to stdout"
      When call msg_blue "Blue message"
      The status should be success
      The output should include "Blue message"
      The stderr should equal ""
    End
  End

  Describe "msg_magenta()"
    It "prints magenta colored message to stdout"
      When call msg_magenta "Magenta message"
      The status should be success
      The output should include "Magenta message"
      The stderr should equal ""
    End
  End

  Describe "msg_cyan()"
    It "prints cyan colored message to stdout"
      When call msg_cyan "Cyan message"
      The status should be success
      The output should include "Cyan message"
      The stderr should equal ""
    End
  End

  Describe "msg_white()"
    It "prints white colored message to stdout"
      When call msg_white "White message"
      The status should be success
      The output should include "White message"
      The stderr should equal ""
    End
  End

  Describe "msg_gray()"
    It "prints gray colored message to stdout"
      When call msg_gray "Gray message"
      The status should be success
      The output should include "Gray message"
      The stderr should equal ""
    End
  End

  # Tests for background color functions
  Describe "msg_bg_black()"
    It "prints message with black background to stdout"
      When call msg_bg_black "Black background"
      The status should be success
      The output should include "Black background"
      The stderr should equal ""
    End
  End

  Describe "msg_bg_red()"
    It "prints message with red background to stdout"
      When call msg_bg_red "Red background"
      The status should be success
      The output should include "Red background"
      The stderr should equal ""
    End
  End

  Describe "msg_bg_green()"
    It "prints message with green background to stdout"
      When call msg_bg_green "Green background"
      The status should be success
      The output should include "Green background"
      The stderr should equal ""
    End
  End

  Describe "msg_bg_yellow()"
    It "prints message with yellow background to stdout"
      When call msg_bg_yellow "Yellow background"
      The status should be success
      The output should include "Yellow background"
      The stderr should equal ""
    End
  End

  Describe "msg_bg_blue()"
    It "prints message with blue background to stdout"
      When call msg_bg_blue "Blue background"
      The status should be success
      The output should include "Blue background"
      The stderr should equal ""
    End
  End

  Describe "msg_bg_magenta()"
    It "prints message with magenta background to stdout"
      When call msg_bg_magenta "Magenta background"
      The status should be success
      The output should include "Magenta background"
      The stderr should equal ""
    End
  End

  Describe "msg_bg_cyan()"
    It "prints message with cyan background to stdout"
      When call msg_bg_cyan "Cyan background"
      The status should be success
      The output should include "Cyan background"
      The stderr should equal ""
    End
  End

  Describe "msg_bg_white()"
    It "prints message with white background to stdout"
      When call msg_bg_white "White background"
      The status should be success
      The output should include "White background"
      The stderr should equal ""
    End
  End

  # Tests for text formatting functions
  Describe "msg_bold()"
    It "prints bold message to stdout"
      When call msg_bold "Bold message"
      The status should be success
      The output should include "Bold message"
      The stderr should equal ""
    End
  End

  Describe "msg_dim()"
    It "prints dim message to stdout"
      When call msg_dim "Dim message"
      The status should be success
      The output should include "Dim message"
      The stderr should equal ""
    End
  End

  Describe "msg_underline()"
    It "prints underlined message to stdout"
      When call msg_underline "Underlined message"
      The status should be success
      The output should include "Underlined message"
      The stderr should equal ""
    End
  End

  Describe "msg_blink()"
    It "prints blinking message to stdout"
      When call msg_blink "Blinking message"
      The status should be success
      The output should include "Blinking message"
      The stderr should equal ""
    End
  End

  Describe "msg_reverse()"
    It "prints reversed message to stdout"
      When call msg_reverse "Reversed message"
      The status should be success
      The output should include "Reversed message"
      The stderr should equal ""
    End
  End

  Describe "msg_hidden()"
    It "prints hidden message to stdout"
      When call msg_hidden "Hidden message"
      The status should be success
      The output should include "Hidden message"
      The stderr should equal ""
    End
  End

End 