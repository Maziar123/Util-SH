#!/usr/bin/env bash
# Script to remove old test files that have been renamed

set -e

# List of test files that were renamed
files=(
  "array_functions_spec.sh"
  "basename_fix_spec.sh"
  "date_time_functions_spec.sh"
  "dependency_checks_spec.sh"
  "error_handling_spec.sh"
  "file_directory_functions_spec.sh"
  "file_extension_spec.sh"
  "get_value_functions_spec.sh"
  "initialization_spec.sh"
  "logging_functions_spec.sh"
  "logging_initialization_spec.sh"
  "message_functions_spec.sh"
  "networking_functions_spec.sh"
  "number_formatting_functions_spec.sh"
  "os_detection_spec.sh"
  "path_navigation_functions_spec.sh"
  "script_information_spec.sh"
  "script_lock_functions_spec.sh"
  "string_functions_spec.sh"
  "system_environment_functions_spec.sh"
  "trap_handlers_spec.sh"
  "user_interaction_functions_spec.sh"
)

echo "The following files will be removed:"
printf "%s\n" "${files[@]}"
echo

read -r -p "Are you sure you want to remove these files? (y/N): " confirm
if [[ "$confirm" != [yY]* ]]; then
  echo "Operation canceled."
  exit 0
fi

for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "Removing $file"
    rm "$file"
  else
    echo "File not found: $file"
  fi
done

echo "Cleanup complete." 