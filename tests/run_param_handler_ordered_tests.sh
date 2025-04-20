#!/usr/bin/bash
# Run ShellSpec tests for the ordered parameter handler

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

# Change to the project root directory
cd "${PROJECT_ROOT}" || exit 1

# Run the ShellSpec tests
shellspec -f d tests/param_handler_ordered_spec.sh

exit 0 