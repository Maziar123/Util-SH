#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for DEPENDENCY CHECKS functions from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "DEPENDENCY CHECKS"
   Describe "check_dependencies()"
     It "returns success if all dependencies exist"
       # Assuming 'ls' and 'echo' exist on the system
       When call check_dependencies "ls" "echo"
       The status should be success
       The stderr should equal ""
     End

     It "returns failure and lists missing dependencies"
       # Assuming 'non_existent_cmd_123' and 'another_missing_cmd_456' do not exist
       When call check_dependencies "ls" "non_existent_cmd_123" "echo" "another_missing_cmd_456"
       The status should be failure
       The stderr should include "Missing required dependencies:"
       The stderr should include "non_existent_cmd_123"
       The stderr should include "another_missing_cmd_456"
     End

     It "returns success if no dependencies are passed"
       When call check_dependencies
       The status should be success
       The stderr should equal ""
     End
   End
End 