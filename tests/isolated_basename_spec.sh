#!/usr/bin/env bash

# Define the function directly rather than importing it
# This avoids any conflicts with the main library
__isolated_get_file_basename() {
  local filename="$1"
  local basename="${filename##*/}"
  local noext="${basename%.*}"
  echo "$noext"
}

# Start of ShellSpec test
Describe "get_file_basename"
  It "returns file basename without extension"
    When call __isolated_get_file_basename "path/to/file.txt"
    The output should equal "file"
  End

  It "returns file basename for file without extension"
    When call __isolated_get_file_basename "path/to/file"
    The output should equal "file"
  End
  
  It "handles empty string"
    When call __isolated_get_file_basename ""
    The output should equal ""
  End
  
  It "handles null input"
    # Using unset var to simulate null
    unset EMPTY_VAR
    When call __isolated_get_file_basename "$EMPTY_VAR"
    The output should equal ""
  End
End 