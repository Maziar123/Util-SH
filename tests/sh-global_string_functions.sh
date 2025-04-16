#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for STRING FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "STRING FUNCTIONS"
  Describe "str_contains()"
    It "returns true when string contains substring"
      When call str_contains "Hello World" "World"
      The status should be success
    End

    It "returns false when string does not contain substring"
      When call str_contains "Hello World" "Universe"
      The status should be failure
    End
  End

  Describe "str_starts_with()"
    It "returns true when string starts with prefix"
      When call str_starts_with "Hello World" "Hello"
      The status should be success
    End

    It "returns false when string does not start with prefix"
      When call str_starts_with "Hello World" "World"
      The status should be failure
    End
  End

  Describe "str_ends_with()"
    It "returns true when string ends with suffix"
      When call str_ends_with "Hello World" "World"
      The status should be success
    End

    It "returns false when string does not end with suffix"
      When call str_ends_with "Hello World" "Hello"
      The status should be failure
    End
  End

  Describe "str_trim()"
    It "trims whitespace from both ends of string"
      When call str_trim "  Hello World  "
      The status should be success
      The output should equal "Hello World"
    End

    It "trims tabs and newlines"
      When call str_trim $'\t Hello World \n'
      The status should be success
      The output should equal "Hello World"
    End
  End

  Describe "str_to_upper()"
    It "converts string to uppercase"
      When call str_to_upper "hello world"
      The status should be success
      The output should equal "HELLO WORLD"
    End
  End

  Describe "str_to_lower()"
    It "converts string to lowercase"
      When call str_to_lower "HELLO WORLD"
      The status should be success
      The output should equal "hello world"
    End
  End

  Describe "str_length()"
    It "returns the length of a string"
      When call str_length "Hello World"
      The status should be success
      The output should equal "11"
    End

    It "returns 0 for an empty string"
      When call str_length ""
      The status should be success
      The output should equal "0"
    End
  End

  Describe "str_replace()"
    It "replaces all occurrences of a substring"
      When call str_replace "Hello World World" "World" "Universe"
      The status should be success
      The output should equal "Hello Universe Universe"
    End

    It "returns the original string if substring is not found"
      When call str_replace "Hello World" "Universe" "Galaxy"
      The status should be success
      The output should equal "Hello World"
    End
  End
End 