#!/usr/bin/env bash
# shellcheck shell=bash

# Tests specifically for get_file_extension function from sh-globals.sh
# Isolated to avoid the freezing issue

# Source the main library
Include "sh-globals.sh"

Describe "get_file_extension (fixed)" 
  # For debugging
  echo "Testing get_file_extension function"
  
  It "returns file extension"
    When call get_file_extension "path/to/file.txt"
    The status should be success
    The output should equal "txt"
    The stderr should equal ""
  End

  It "returns empty string for file without extension"
    When call get_file_extension "path/to/file"
    The status should be success
    The output should equal ""
    The stderr should equal ""
  End
  
  It "handles empty string"
    When call get_file_extension ""
    The status should be success
    The output should equal ""
    The stderr should equal ""
  End
  
  It "handles dot files correctly"
    When call get_file_extension ".gitignore"
    The status should be success
    The output should equal ""
    The stderr should equal ""
  End
  
  It "handles path with multiple dots"
    When call get_file_extension "file.name.with.dots.txt"
    The status should be success
    The output should equal "txt"
    The stderr should equal ""
  End
  
  It "handles files with just an extension"
    When call get_file_extension ".txt"
    The status should be success
    The output should equal "txt"
    The stderr should equal ""
  End
End
