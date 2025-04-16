#!/usr/bin/env bash
# shellcheck shell=bash

# Defining variables and functions here will affect all specfiles.
# Change shell options inside a function may cause different behavior,
# so it is better to set them here.
# set -eu

# This callback function will be invoked only once before loading specfiles.
spec_helper_precheck() {
  # Available functions: info, warn, error, abort, setenv, unsetenv
  # Available variables: VERSION, SHELL_TYPE, SHELL_VERSION
  : minimum_version "0.28.1"
}

# This callback function will be invoked after a specfile has been loaded.
spec_helper_loaded() {
  :
}

# This callback function will be invoked after core modules has been loaded.
spec_helper_configure() {
  # Available functions: import, before_each, after_each, before_all, after_all
  : import 'support/custom_matcher'
}

# Common helper functions for sh-globals tests

# Helper for creating a temporary test file
create_test_file() {
  local file="$1"
  local content="$2"
  echo "$content" > "$file"
}

# Helper to check if a string is a number (integer)
is_number() {
  [[ "$1" =~ ^[+-]?[0-9]+$ ]]
}

# Helper function to check if status is 0 or 1
check_status_is_0_or_1() {
  # $1 is the status code passed by satisfy
  [[ "$1" -eq 0 || "$1" -eq 1 ]]
  return $?
}

# Helper function to check if the current user is root
is_running_as_root() {
  test "$(id -u)" -eq 0
  return $?
}

# Helper function for get_os test
is_valid_os() {
  [[ "$1" == "linux" || "$1" == "mac" || "$1" == "windows" ]]
}

# Helper function for timestamp test
is_valid_timestamp() {
  [[ "$1" =~ ^[0-9]{10,}$ ]]
}

# Path setup/teardown functions might also be needed here if tests depend on them globally
# Define helper function for PATH NAVIGATION setup 
path_setup() {
  TEST_BASE_DIR=$(mktemp -d)
  mkdir -p "$TEST_BASE_DIR/level1/level2/level3"
  touch "$TEST_BASE_DIR/level1/file1.txt"
  SCRIPT_LOC="$TEST_BASE_DIR/level1/level2/mock_script.sh"
  echo "#!/bin/bash" > "$SCRIPT_LOC"
  # Mock get_script_dir to return a fixed path for these tests
  get_script_dir() { echo "$TEST_BASE_DIR/level1/level2"; }
  # Mock realpath for consistent behavior (using readlink -f)
  realpath() { readlink -f "$1"; }
  # Make mocks available to subshells
  export -f get_script_dir realpath
  export TEST_BASE_DIR SCRIPT_LOC
}
# Cleanup function for PATH NAVIGATION
path_teardown() {
  if [[ -n "$TEST_BASE_DIR" && -d "$TEST_BASE_DIR" ]]; then
     rm -rf "$TEST_BASE_DIR"
  fi
  # Unset mocks
  unset -f get_script_dir realpath
  unset TEST_BASE_DIR SCRIPT_LOC
}
