#!/usr/bin/env bash

echo "--- Testing get_timestamp length ---"

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

# Call the function
echo "Calling get_timestamp..."
timestamp=$(get_timestamp)

if [[ -z "$timestamp" ]]; then
  echo "ERROR: get_timestamp returned empty string" >&2
  exit 1
fi

echo "Timestamp returned: '$timestamp'"

# Get the length
length=${#timestamp}
echo "Length of timestamp: $length"

# Assert length >= 10
echo "Asserting length >= 10..."
if [[ $length -ge 10 ]]; then
  echo "ASSERTION PASSED: Length ($length) is >= 10."
  echo "---------------------------------------"
  exit 0
else
  echo "ASSERTION FAILED: Length ($length) is < 10."
  echo "---------------------------------------"
  exit 1
fi 