#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for USER INTERACTION FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

# Skipping USER INTERACTION FUNCTIONS due to freezing issues with mocking 'read'
Describe "USER INTERACTION FUNCTIONS"
  Skip "Freezing issue with mocking read"
  
  Describe "confirm()"
    # Setup a mock 'read' function that always returns 'y'
    BeforeEach 'CONFIRM_RESPONSE="y"; function read() { REPLY="$CONFIRM_RESPONSE"; return 0; }'
    
    It "returns true when user confirms"
      When call confirm "Are you sure?"
      The stderr should include "Are you sure?"
      The status should be success
    End

    # Add a test for default 'n'
    It "returns false when user defaults to n"
      BeforeEach 'CONFIRM_RESPONSE=""; function read() { REPLY="$CONFIRM_RESPONSE"; return 0; }' # Empty response
      When call confirm "Proceed?" "n" # Default is 'n'
      The stderr should include "Proceed?"
      The status should be failure
    End

    # Add a test for default 'y'
    It "returns true when user defaults to y"
      BeforeEach 'CONFIRM_RESPONSE=""; function read() { REPLY="$CONFIRM_RESPONSE"; return 0; }' # Empty response
      When call confirm "Really proceed?" "y" # Default is 'y'
      The stderr should include "Really proceed?"
      The status should be success
    End

  End

  # Placeholder for prompt_input tests
  Describe "prompt_input()"
    # Skip "Input tests require mocking 'read'"
    # Test with default
    # Test without default
  End

  # Placeholder for prompt_password tests
  Describe "prompt_password()"
    # Skip "Password tests require mocking 'read -s'"
    # Test basic functionality
  End

End 