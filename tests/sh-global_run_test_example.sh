#!/usr/bin/env bash
# Example of how to run the new sh-global tests

cd "$(dirname "$0")/.." || exit 1

# Run a specific test
shellspec "tests/sh-global_array_functions.sh"

# To run all sh-globals tests:
# shellspec -p "sh-global_*.sh" 