#!/usr/bin/env bash

echo "--- Testing date formatting ---"

timestamp=1678886400 # 2023-03-15 12:00:00 UTC
format="%H:%M:%S"
expected="12:00:00"

echo "Timestamp: $timestamp"
echo "Format:    $format"
echo "Expected:  $expected"

echo "Running command: TZ=UTC date -d \"@$timestamp\" -Iseconds --utc +\"$format\""
actual=$(TZ=UTC date -d "@$timestamp" -Iseconds --utc +"$format")

echo "Actual output: '$actual'"

echo "Asserting actual == expected..."
if [[ "$actual" == "$expected" ]]; then
  echo "ASSERTION PASSED: Output matches expected."
  echo "---------------------------------------"
  exit 0
else
  echo "ASSERTION FAILED: Output '$actual' does not match expected '$expected'."
  echo "---------------------------------------"
  exit 1
fi
