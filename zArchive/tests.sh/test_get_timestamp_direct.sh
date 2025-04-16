#!/usr/bin/env bash

echo "--- Testing get_timestamp directly ---"

# Determine script directory to source sh-globals.sh correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SH_GLOBALS_PATH="${SCRIPT_DIR}/sh-globals.sh"

if [[ ! -f "$SH_GLOBALS_PATH" ]]; then
  echo "ERROR: sh-globals.sh not found at $SH_GLOBALS_PATH" >&2
  exit 1
fi

# Source the library
echo "Sourcing $SH_GLOBALS_PATH..."
source "$SH_GLOBALS_PATH"

# Prepare to capture output
tmp_stderr=$(mktemp)

# Call the function, capture stdout, stderr, and exit status
echo "Calling get_timestamp (capturing stdout, stderr, status)..."
timestamp_out=$(get_timestamp 2> "$tmp_stderr")
exit_status=$?
stderr_out=$(cat "$tmp_stderr")
rm "$tmp_stderr"

# Analyze results
echo "Exit Status: $exit_status"
echo "Stderr:      '$stderr_out'"
echo "Stdout:      '$timestamp_out'"

# Assertions
passed=true

echo "Asserting Exit Status == 0..."
if [[ $exit_status -ne 0 ]]; then
  echo "  FAILED: Exit status was $exit_status"
  passed=false
else
  echo "  PASSED."
fi

echo "Asserting Stderr is empty..."
if [[ -n "$stderr_out" ]]; then
  echo "  FAILED: Stderr was '$stderr_out'"
  passed=false
else
  echo "  PASSED."
fi

echo "Asserting Stdout is not empty..."
if [[ -z "$timestamp_out" ]]; then
  echo "  FAILED: Stdout was empty"
  passed=false
else
  echo "  PASSED."
fi

if [[ -n "$timestamp_out" ]]; then
  echo "Asserting Stdout matches pattern ^[0-9]+$..."
  if [[ "$timestamp_out" =~ ^[0-9]+$ ]]; then
    echo "  PASSED."
    length=${#timestamp_out}
    echo "Asserting Length ($length) >= 10..."
    if [[ $length -ge 10 ]]; then
      echo "  PASSED."
    else
      echo "  FAILED: Length is $length"
      passed=false
    fi
  else
    echo "  FAILED: Stdout '$timestamp_out' does not match pattern."
    passed=false
  fi
fi

echo "---------------------------------------"
if $passed; then
  echo "OVERALL RESULT: PASSED"
  exit 0
else
  echo "OVERALL RESULT: FAILED"
  exit 1
fi 