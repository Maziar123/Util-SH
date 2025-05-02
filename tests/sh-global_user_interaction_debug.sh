#!/usr/bin/env bash
# shellcheck shell=bash

# Debug file for user interaction functions
echo "DEBUG file for testing user interaction functions"

# Source the main library
Include "sh-globals.sh"

# Create a debug mock read function
debug_read() {
  echo "DEBUG: Mock read called with args: $*" >&2
  return 0
}

# Test read command to see if it's freezing
test_read_command() {
  echo "Testing read command..."
  # Try to read with timeout
  if read -t 1 -r -p "This should timeout after 1 second: " response; then
    echo "Read completed: $response"
  else
    echo "Read timed out as expected"
  fi
}

# Test the get_number function with debugging
test_get_number() {
  echo "Testing get_number function..."
  
  # Override read function locally for this test
  read() {
    echo "Mock read function called" >&2
    # Just return a fixed value
    REPLY="42"
    return 0
  }
  
  # Try calling get_number
  result=$(get_number "Enter a number: ")
  echo "Result from get_number: $result"
}

# Run the tests
echo "Starting tests..."

echo "1. Testing read command"
test_read_command

echo "2. Testing get_number function"
test_get_number

echo "Tests completed." 