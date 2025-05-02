#!/usr/bin/env bash
# run_param_handler_tests.sh - Script to run ShellSpec tests for param_handler.sh

# Set script to exit on error
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if shellspec is installed
if ! command -v shellspec &> /dev/null; then
  echo "Error: shellspec is not installed. Please install it first."
  echo "Visit: https://github.com/shellspec/shellspec#installation"
  exit 1
fi

# Change to the project root directory
cd "$PROJECT_ROOT"

# Run ShellSpec tests specifically for param_handler.sh
echo "Running ShellSpec tests for param_handler.sh..."
shellspec tests/param_handler_spec.sh "$@" 