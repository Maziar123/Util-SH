#!/usr/bin/env bash
Include "sh-globals.sh"

# shellcheck disable=SC1091

# Tests for OS DETECTION functions from sh-globals.sh

# Source the main library relative to the tests directory

Describe "OS DETECTION"
  Describe "get_os()"
    It "returns a known OS type"
      When call get_os
      The status should be success
      The stderr should be blank
      The output should eq "linux"
    End
  End

  Describe "get_linux_distro()"
    It "returns Linux distribution name"
      When call get_linux_distro
      The status should be success
      The output should not equal "" # Exact output depends on distro
    End
  End

  Describe "get_arch()"
    It "returns processor architecture"
      When call get_arch
      The status should be success
      The output should not equal "" # e.g., amd64, arm64, arm
    End
  End

  Describe "is_in_container()"
    # This is hard to test definitively without controlling the environment
    It "returns success or failure depending on environment"
      When call is_in_container
      The status should satisfy check_status_is_0_or_1 # Returns 0 if in container, 1 otherwise
    End
  End
End 