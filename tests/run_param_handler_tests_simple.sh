#!/usr/bin/env bash
# Simple script to run shellspec tests

echo "Starting test run"
cd "$(dirname "$0")/.."
echo "Current directory: $(pwd)"
echo "Running: shellspec tests/param_handler_spec.sh -f d"
shellspec tests/param_handler_spec.sh -f d 