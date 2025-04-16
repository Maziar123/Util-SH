#!/usr/bin/env bash
# Script to rename test files related to sh-globals.sh

set -e

# List of test files to rename
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

for file in "${files[@]}"; do
  # Get the base name without _spec.sh
  base_name="${file%_spec.sh}"
  
  # Create new filename with sh-global_ prefix
  new_file="sh-global_${base_name}.sh"
  
  echo "Renaming $file to $new_file"
  
  # Copy file (use cp instead of mv to keep originals as backup)
  cp "$file" "$new_file"
  
  # No need to update content as Include "sh-globals.sh" should remain the same
done

echo "Files renamed successfully. Please update any references in other files." 