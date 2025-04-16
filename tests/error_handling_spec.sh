#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for ERROR HANDLING functions from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "ERROR HANDLING"
  Describe "print_stack_trace()"
    # Testing stack trace output precisely is complex
    It "prints a stack trace format"
      # Define a nested function scenario
      func_c() { print_stack_trace; }
      func_b() { func_c; }
      func_a() { func_b; }
      When call func_a
      The status should be success
      The output should include "Stack trace:"
      The output should include "func_c"
      The output should include "func_b"
      The output should include "func_a"
    End
  End

  Describe "error_handler()"
     Skip "Difficult to test directly due to 'exit' call and trap interaction"
     # To test this properly, one would need to run a script with 'set -e'
     # and 'setup_traps' enabled, cause an error, and capture the output/exit code.
     # Example concept (not runnable directly in ShellSpec 'It' block):
     # test_script() {
     #   source sh-globals.sh
     #   setup_traps
     #   echo "Causing error..."
     #   command_that_fails
     #   echo "Should not reach here"
     # }
     # Run test_script and check stderr/status code.
     Todo "Implement more robust test for error_handler if needed"
  End
End 