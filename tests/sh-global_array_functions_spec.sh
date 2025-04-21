#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for ARRAY FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "ARRAY FUNCTIONS"
  Describe "array_contains()"
    It "returns true when array contains element"
      When call array_contains "two" "one" "two" "three"
      The status should be success
    End

    It "returns false when array does not contain element"
      When call array_contains "four" "one" "two" "three"
      The status should be failure
    End
  End

  Describe "array_join()"
    It "joins array elements with delimiter"
      When call array_join "," "one" "two" "three"
      The status should be success
      The output should equal "one,two,three"
    End

    It "handles empty array"
      When call array_join ","
      The status should be success
      The output should equal ""
    End
  End

  Describe "array_length()"
    # This function requires passing array by reference
    # which is not easy to test in all shells. Using a simplified test.
    It "counts array elements"
      test_array_length() {
        local -a arr=("one" "two" "three")
        array_length arr
      }
      When call test_array_length
      The status should be success
      The output should equal "3"
    End
  End
End 