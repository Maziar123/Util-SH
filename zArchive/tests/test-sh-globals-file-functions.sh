#!/usr/bin/env bash
# test-file-functions.sh - Tests for file and directory functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Group for file functions
test_group "File & Directory Functions"

# Setup for file tests
setup_file_tests() {
  # Create a temp directory for tests
  TEST_DIR=$(test_create_temp_dir)
  
  # Create some test files and directories
  mkdir -p "$TEST_DIR/test_dir"
  echo "test content" > "$TEST_DIR/test_file.txt"
  echo "another test" > "$TEST_DIR/test_dir/nested_file.txt"
  
  # Make executable
  chmod +x "$TEST_DIR/test_file.txt"
  
  # Return success
  return 0
}

# Cleanup for file tests
cleanup_file_tests() {
  # Clean up the test directory
  if [[ -d "$TEST_DIR" ]]; then
    test_cleanup_temp_dir "$TEST_DIR"
  fi
}

# Test command_exists
test_command_exists() {
  # Common command that should exist
  assert_eq "$(command_exists "ls" && echo "true" || echo "false")" "true"
  
  # Command that likely doesn't exist
  assert_eq "$(command_exists "non_existent_command_12345" && echo "true" || echo "false")" "false"
  
  return 0
}
test "command_exists function" test_command_exists

# Test safe_mkdir
test_safe_mkdir() {
  setup_file_tests
  
  # Create new directory
  local new_dir="$TEST_DIR/new_dir"
  safe_mkdir "$new_dir"
  assert "[ -d \"$new_dir\" ]" "Directory was not created"
  
  # Create existing directory (should not fail)
  safe_mkdir "$new_dir"
  assert "[ -d \"$new_dir\" ]" "Directory no longer exists"
  
  # Create nested directory
  local nested_dir="$TEST_DIR/nested/dirs/here"
  safe_mkdir "$nested_dir"
  assert "[ -d \"$nested_dir\" ]" "Nested directory was not created"
  
  cleanup_file_tests
  return 0
}
test "safe_mkdir function" test_safe_mkdir

# Test file_exists
test_file_exists() {
  setup_file_tests
  
  # File exists
  assert_eq "$(file_exists "$TEST_DIR/test_file.txt" && echo "true" || echo "false")" "true"
  
  # File doesn't exist
  assert_eq "$(file_exists "$TEST_DIR/non_existent_file.txt" && echo "true" || echo "false")" "false"
  
  # Directory (not a file)
  assert_eq "$(file_exists "$TEST_DIR/test_dir" && echo "true" || echo "false")" "false"
  
  cleanup_file_tests
  return 0
}
test "file_exists function" test_file_exists

# Test dir_exists
test_dir_exists() {
  setup_file_tests
  
  # Directory exists
  assert_eq "$(dir_exists "$TEST_DIR/test_dir" && echo "true" || echo "false")" "true"
  
  # Directory doesn't exist
  assert_eq "$(dir_exists "$TEST_DIR/non_existent_dir" && echo "true" || echo "false")" "false"
  
  # File (not a directory)
  assert_eq "$(dir_exists "$TEST_DIR/test_file.txt" && echo "true" || echo "false")" "false"
  
  cleanup_file_tests
  return 0
}
test "dir_exists function" test_dir_exists

# Test file_size
test_file_size() {
  setup_file_tests
  
  # Get size of test file (should be 12 bytes for "test content\n")
  local size
  size=$(file_size "$TEST_DIR/test_file.txt")
  assert "[ $size -eq 12 ]" "File size incorrect, expected 12 bytes, got $size"
  
  # Create empty file
  touch "$TEST_DIR/empty_file.txt"
  size=$(file_size "$TEST_DIR/empty_file.txt")
  assert "[ $size -eq 0 ]" "Empty file size incorrect, expected 0 bytes, got $size"
  
  # Non-existent file
  size=$(file_size "$TEST_DIR/non_existent_file.txt")
  assert "[ $size -eq 0 ]" "Non-existent file size incorrect, expected 0 bytes, got $size"
  
  cleanup_file_tests
  return 0
}
test "file_size function" test_file_size

# Test safe_copy
test_safe_copy() {
  setup_file_tests
  
  # Copy file
  local src="$TEST_DIR/test_file.txt"
  local dst="$TEST_DIR/copied_file.txt"
  assert_eq "$(safe_copy "$src" "$dst" && echo "true" || echo "false")" "true"
  assert "[ -f \"$dst\" ]" "Destination file was not created"
  
  # Verify content
  local content
  content=$(cat "$dst")
  assert_eq "$content" "test content" "File content doesn't match"
  
  # Copy to non-existent directory (should fail)
  dst="$TEST_DIR/non_existent_dir/file.txt"
  assert_eq "$(safe_copy "$src" "$dst" 2>/dev/null && echo "true" || echo "false")" "false"
  
  # Copy non-existent file (should fail)
  src="$TEST_DIR/non_existent_file.txt"
  dst="$TEST_DIR/should_not_exist.txt"
  assert_eq "$(safe_copy "$src" "$dst" 2>/dev/null && echo "true" || echo "false")" "false"
  assert "[ ! -f \"$dst\" ]" "Destination file should not exist"
  
  cleanup_file_tests
  return 0
}
test "safe_copy function" test_safe_copy

# Test create_temp_file and cleanup
test_create_temp_file() {
  # Create a temp file
  local temp_file
  temp_file=$(create_temp_file "test-globals-XXXXXX")
  
  # Check that the file exists
  assert "[ -f \"$temp_file\" ]" "Temp file was not created"
  
  # Write to the file
  echo "test content" > "$temp_file"
  
  # Read from the file
  local content
  content=$(cat "$temp_file")
  assert_eq "$content" "test content" "Temp file content doesn't match"
  
  # File should be cleaned up automatically when script exits
  return 0
}
test "create_temp_file function" test_create_temp_file

# Test create_temp_dir and cleanup
test_create_temp_dir() {
  # Create a temp directory
  local temp_dir
  temp_dir=$(create_temp_dir "test-globals-XXXXXX")
  
  # Check that the directory exists
  assert "[ -d \"$temp_dir\" ]" "Temp directory was not created"
  
  # Create a file in the directory
  echo "test content" > "$temp_dir/test.txt"
  
  # Check that the file exists
  assert "[ -f \"$temp_dir/test.txt\" ]" "Unable to create file in temp directory"
  
  # Directory should be cleaned up automatically when script exits
  return 0
}
test "create_temp_dir function" test_create_temp_dir

# Test get_file_extension
test_get_file_extension() {
  # Standard extension
  assert_eq "$(get_file_extension "file.txt")" "txt"
  
  # Multiple extensions
  assert_eq "$(get_file_extension "file.tar.gz")" "gz"
  
  # No extension
  assert_eq "$(get_file_extension "file")" ""
  
  # Hidden file with extension
  assert_eq "$(get_file_extension ".hidden.txt")" "txt"
  
  # Hidden file without extension
  assert_eq "$(get_file_extension ".hidden")" ""
  
  # Path with extension
  assert_eq "$(get_file_extension "/path/to/file.txt")" "txt"
  
  return 0
}
test "get_file_extension function" test_get_file_extension

# Test get_file_basename
test_get_file_basename() {
  # Standard filename
  assert_eq "$(get_file_basename "file.txt")" "file"
  
  # Multiple extensions
  assert_eq "$(get_file_basename "file.tar.gz")" "file.tar"
  
  # No extension
  assert_eq "$(get_file_basename "file")" "file"
  
  # Hidden file with extension
  assert_eq "$(get_file_basename ".hidden.txt")" ".hidden"
  
  # Hidden file without extension
  assert_eq "$(get_file_basename ".hidden")" ".hidden"
  
  # Path with extension
  assert_eq "$(get_file_basename "/path/to/file.txt")" "file"
  
  return 0
}
test "get_file_basename function" test_get_file_basename 