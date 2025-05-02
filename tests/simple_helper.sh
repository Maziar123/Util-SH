#!/usr/bin/env bash
# simple_helper.sh - Basic helper functions for ShellSpec tests

# Mock for get_value function
get_value() {
  echo "test_default_value"
}

# Helper to clean up test environment
cleanup_test_vars() {
  # Clean global test variables
  unset TEST_NAME TEST_AGE TEST_CITY
}

# Mock log_error function
log_error() {
  echo "ERROR: $*" >&2
} 