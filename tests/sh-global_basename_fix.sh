#!/usr/bin/env bash
# shellcheck shell=bash

# Tests specifically for get_file_basename function from sh-globals.sh
# Isolated to avoid the freezing issue

# Source the main library
Include "sh-globals.sh"

Describe "get_file_basename (fixed)" 
  # For debugging
  echo "Testing get_file_basename function"
  
  It "returns file basename without extension"
    When call get_file_basename "path/to/file.txt"
    The status should be success
    The output should equal "file"
    The stderr should equal ""
  End

  It "returns file basename for file without extension"
    When call get_file_basename "path/to/file"
    The status should be success
    The output should equal "file"
    The stderr should equal ""
  End
  
  It "handles empty string"
    When call get_file_basename ""
    The status should be success
    The output should equal ""
    The stderr should equal ""
  End
  
  It "handles dot files correctly"
    When call get_file_basename ".gitignore"
    The status should be success
    The output should equal ".gitignore"
    The stderr should equal ""
  End
  
  It "handles path with multiple dots"
    When call get_file_basename "file.name.with.dots.txt"
    The status should be success
    The output should equal "file.name.with.dots"
    The stderr should equal ""
  End
End 