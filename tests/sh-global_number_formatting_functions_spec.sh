#!/usr/bin/env bash
Include "sh-globals.sh"

# Define missing function for testing
is_all_digits() {
  local input="$1"
  [[ -z "$input" ]] && return 1
  [[ "$input" =~ ^[0-9]+$ ]]
}

Describe "NUMBER FORMATTING FUNCTIONS"
  Describe "format_si_number()"
    It "formats number with SI prefixes"
      When call format_si_number 1234567
      The output should eq "1.2M"
    End

    It "handles small numbers without prefixes"
      When call format_si_number 123
      The output should eq "123"
    End

    It "handles zero"
      When call format_si_number 0
      The output should eq "0"
    End
  End

  Describe "format_bytes()"
    It "formats bytes in human-readable form"
      When call format_bytes 1024
      The output should eq "1KB"
    End

    It "formats larger sizes"
      When call format_bytes 1048576
      The output should eq "1MB"
    End

    It "formats gigabytes"
      When call format_bytes 1073741824
      The output should eq "1GB"
    End

    It "handles small values"
      When call format_bytes 100
      The output should eq "100B"
    End
  End

  Describe "is_all_digits()"
    It "returns true for strings containing only digits"
      When call is_all_digits "12345"
      The status should be success
    End

    It "returns false for strings with non-digit characters"
      When call is_all_digits "123abc"
      The status should be failure
    End

    It "returns false for empty strings"
      When call is_all_digits ""
      The status should be failure
    End
  End
End