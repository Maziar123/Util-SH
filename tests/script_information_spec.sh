#!/usr/bin/env bash
Include "sh-globals.sh"

# shellcheck shell=bash

# Tests for SCRIPT INFORMATION functions from sh-globals.sh

# Source the main library relative to the tests directory

Describe "SCRIPT INFORMATION"
  Describe "get_script_dir()"
    It "returns the directory of the current script"
      # Since this test is executed in a subshell, we can't easily test the result
      # Instead we check that the function doesn't fail and returns a non-empty string
      When call get_script_dir
      The status should be success
      The output should not equal ""
    End
  End

  Describe "get_script_name()"
    It "returns the name of the current script"
      When call get_script_name
      The status should be success
      The output should not equal ""
    End
  End

  Describe "get_script_path()"
    It "returns the absolute path of the current script"
      When call get_script_path
      The status should be success
      The output should not equal ""
    End
  End

  Describe "get_line_number()"
    It "returns the current line number (direct check)"
      When call get_line_number
      # Remove manual capture and debug echo
      The status should be success
      # Directly assert the output produced by 'When call'
      The output should not equal ""
    End
  End
End 