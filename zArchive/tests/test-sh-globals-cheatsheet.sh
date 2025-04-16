#!/usr/bin/env bash
# test-cheatsheet.sh - Concise examples of functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Output formatting
echo -e "\n\e[1m===== SH-GLOBALS.SH CHEAT SHEET =====\e[0m"
echo -e "Quick reference of functions with examples\n"

# Function to display cheatsheet item
cheat() {
  local func="$1"
  local example="$2"
  local output="$3"
  
  printf "\e[1m%-25s\e[0m %-45s → %s\n" "$func" "$example" "$output"
}

echo -e "\e[1m===== STRING FUNCTIONS =====\e[0m"
cheat "str_contains" "str_contains 'Hello' 'el'" "$(str_contains 'Hello' 'el' && echo 'true' || echo 'false')"
cheat "str_starts_with" "str_starts_with 'Hello' 'He'" "$(str_starts_with 'Hello' 'He' && echo 'true' || echo 'false')"
cheat "str_ends_with" "str_ends_with 'Hello' 'lo'" "$(str_ends_with 'Hello' 'lo' && echo 'true' || echo 'false')"
cheat "str_trim" "str_trim '  Hello  '" "'$(str_trim '  Hello  ')'"
cheat "str_to_upper" "str_to_upper 'Hello'" "'$(str_to_upper 'Hello')'"
cheat "str_to_lower" "str_to_lower 'Hello'" "'$(str_to_lower 'Hello')'"
cheat "str_length" "str_length 'Hello'" "$(str_length 'Hello')"
cheat "str_replace" "str_replace 'Hello' 'el' 'ip'" "'$(str_replace 'Hello' 'el' 'ip')'"
echo

echo -e "\e[1m===== ARRAY FUNCTIONS =====\e[0m"
cheat "array_contains" "array_contains 'b' ('a' 'b' 'c')" "true (returns 0/1)"
cheat "array_join" "array_join ',' ('a' 'b' 'c')" "'$(array_join ',' 'a' 'b' 'c')'"
cheat "array_length" "declare -a arr=('a' 'b' 'c'); array_length arr" "3"
echo

echo -e "\e[1m===== FILE FUNCTIONS =====\e[0m"
cheat "command_exists" "command_exists 'ls'" "$(command_exists 'ls' && echo 'true' || echo 'false')"
cheat "safe_mkdir" "safe_mkdir '/path/dir'" "Creates directory if not exists"
cheat "file_exists" "file_exists '/etc/hosts'" "$(file_exists '/etc/hosts' && echo 'true' || echo 'false')"
cheat "dir_exists" "dir_exists '/etc'" "$(dir_exists '/etc' && echo 'true' || echo 'false')"
cheat "file_size" "file_size '/etc/hosts'" "$(file_size '/etc/hosts') bytes"
cheat "get_file_extension" "get_file_extension 'file.txt'" "'$(get_file_extension 'file.txt')'"
cheat "get_file_basename" "get_file_basename 'file.txt'" "'$(get_file_basename 'file.txt')'"
cheat "wait_for_file" "wait_for_file '/path/file' 5 1" "Waits 5s, checks every 1s"
cheat "create_temp_file" "create_temp_file [template]" "Creates auto-cleaned temp file"
cheat "create_temp_dir" "create_temp_dir [template]" "Creates auto-cleaned temp dir"
cheat "safe_copy" "safe_copy '/src/file' '/dst/file'" "Copies with verification"
echo

echo -e "\e[1m===== NUMBER FORMATTING =====\e[0m"
cheat "format_si_number" "format_si_number 1500" "'$(format_si_number 1500)'"
cheat "format_si_number" "format_si_number 1500000" "'$(format_si_number 1500000)'"
cheat "format_si_number" "format_si_number 0.001" "'$(format_si_number 0.001)'"
cheat "format_bytes" "format_bytes 1024" "'$(format_bytes 1024)'"
cheat "format_bytes" "format_bytes 1048576" "'$(format_bytes 1048576)'"
echo

echo -e "\e[1m===== DATE & TIME FUNCTIONS =====\e[0m"
cheat "get_timestamp" "get_timestamp" "$(get_timestamp)"
cheat "format_date" "format_date '%Y-%m-%d'" "$(format_date '%Y-%m-%d')"
cheat "time_diff_human" "time_diff_human 0 3665" "'$(time_diff_human 0 3665)'"
echo

echo -e "\e[1m===== SCRIPT INFORMATION =====\e[0m"
cheat "get_script_dir" "get_script_dir" "Directory of current script"
cheat "get_script_name" "get_script_name" "$(get_script_name)"
cheat "get_script_path" "get_script_path" "Full path of current script"
cheat "get_line_number" "get_line_number" "Current line number (${LINENO})"
echo

echo -e "\e[1m===== SYSTEM FUNCTIONS =====\e[0m"
cheat "env_or_default" "env_or_default 'PATH' '/bin'" "Env var or default value"
cheat "is_root" "is_root" "$(is_root && echo 'true' || echo 'false')"
cheat "get_current_user" "get_current_user" "'$(get_current_user)'"
cheat "get_hostname" "get_hostname" "'$(get_hostname)'"
cheat "get_os" "get_os" "'$(get_os)'"
cheat "get_arch" "get_arch" "'$(get_arch)'"
cheat "is_in_container" "is_in_container" "true/false container detection"
cheat "parse_flags" "parse_flags '--debug'" "Sets DEBUG=1 from arg"
echo

echo -e "\e[1m===== LOGGING FUNCTIONS =====\e[0m"
cheat "log_init" "log_init [file] [save_to_file]" "Initialize logging"
cheat "log_info" "log_info 'Info message'" "Log info to console & file"
cheat "log_warn" "log_warn 'Warning message'" "Log warning to console & file"
cheat "log_error" "log_error 'Error message'" "Log error to console & file"
cheat "log_success" "log_success 'Success message'" "Log success to console & file"
cheat "log_debug" "log_debug 'Debug message'" "Log debug if DEBUG=1"
echo

echo -e "\e[1m===== LOCK FUNCTIONS =====\e[0m"
cheat "create_lock" "create_lock '/tmp/script.lock'" "Create exclusive lock file"
cheat "release_lock" "release_lock" "Release the lock file"
echo

echo -e "\e[1m===== ERROR HANDLING =====\e[0m"
cheat "print_stack_trace" "print_stack_trace" "Show current call stack"
cheat "error_handler" "error_handler \$? \$LINENO" "Handle script errors"
cheat "setup_traps" "setup_traps" "Set up signal trap handlers"
cheat "check_dependencies" "check_dependencies curl jq" "Check required commands"
echo

echo -e "\e[1m===== NETWORKING FUNCTIONS =====\e[0m"
cheat "is_url_reachable" "is_url_reachable 'https://example.com' 3" "Check URL reachability"
cheat "get_external_ip" "get_external_ip" "Get public IP address"
cheat "is_port_open" "is_port_open 'localhost' 22 2" "Check if port is open"
echo

echo -e "\e[1m===== MESSAGE FUNCTIONS =====\e[0m"
cheat "msg" "msg 'Message'" "Plain message"
cheat "msg_info" "msg_info 'Info'" "Blue info message"
cheat "msg_success" "msg_success 'Success'" "Green success message"
cheat "msg_warning" "msg_warning 'Warning'" "Yellow warning message"
cheat "msg_error" "msg_error 'Error'" "Red error message"
cheat "msg_header" "msg_header 'Header'" "Bold magenta header"
cheat "msg_section" "msg_section 'Section' 30 '='" "Section divider"
cheat "msg_step" "msg_step 2 5 'Step Two'" "Step indicator"
cheat "msg_color" "msg_color 'Message' \"\$GREEN\"" "Custom colored message"
cheat "msg_subtle" "msg_subtle 'Subtle message'" "Gray/dim message"
echo

echo -e "\e[1m===== USER INTERACTION =====\e[0m"
cheat "confirm" "confirm 'Continue?' 'y'" "Prompts user y/n"
cheat "prompt_input" "prompt_input 'Name?' 'default'" "Input with default"
cheat "prompt_password" "prompt_password 'Password?'" "Hidden input"
echo

echo -e "\e[1m===== GET VALUE FUNCTIONS =====\e[0m"
cheat "get_number" "get_number 'Number?' '10' '1' '100'" "Number with validation"
cheat "get_string" "get_string 'String?' '' '[a-z]+'" "String with validation"
cheat "get_path" "get_path 'Path?' '/tmp' 'file' '1'" "Path with validation"
cheat "get_value" "get_value 'Email?' '' is_valid_email" "Custom validation"
echo

echo -e "\n\e[1m===== END OF CHEAT SHEET =====\e[0m"
echo -e "For full documentation, see sh-globals.md\n" 