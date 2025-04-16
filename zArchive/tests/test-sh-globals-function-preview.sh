#!/usr/bin/env bash
# test-function-preview.sh - Preview actual outputs of functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Set up output formatting
echo -e "\n\e[1m===== SH-GLOBALS.SH FUNCTION PREVIEW =====\e[0m"
echo -e "This file demonstrates the actual outputs of functions\n"

preview_function() {
  local func_name="$1"
  local func_call="$2"
  local description="$3"
  
  echo -e "\e[1m== $func_name ==\e[0m"
  echo -e "\e[90m$description\e[0m"
  echo -e "\e[96mCommand:\e[0m $func_call"
  echo -ne "\e[96mOutput:\e[0m "
  
  # Capture and display output
  eval "$func_call"
  
  echo -e "\n"
}

# COLOR PREVIEWS
echo -e "\e[1m===== COLOR VARIABLES PREVIEW =====\e[0m"
echo -e "Color variables available in sh-globals.sh\n"

echo -e "${RED}RED text${NC}"
echo -e "${GREEN}GREEN text${NC}"
echo -e "${YELLOW}YELLOW text${NC}"
echo -e "${BLUE}BLUE text${NC}"
echo -e "${MAGENTA}MAGENTA text${NC}"
echo -e "${CYAN}CYAN text${NC}"
echo -e "${WHITE}WHITE text${NC}"
echo -e "${GRAY}GRAY text${NC}"
echo -e "${BOLD}BOLD text${NC}"
echo -e "${UNDERLINE}UNDERLINED text${NC}"
echo -e "\n"

# STRING FUNCTIONS
echo -e "\e[1m===== STRING FUNCTIONS =====\e[0m\n"

preview_function "str_contains" \
  "str_contains 'Hello World' 'World' && echo 'true' || echo 'false'" \
  "Check if string contains substring"

preview_function "str_starts_with" \
  "str_starts_with 'Hello World' 'Hello' && echo 'true' || echo 'false'" \
  "Check if string starts with prefix"

preview_function "str_ends_with" \
  "str_ends_with 'Hello World' 'World' && echo 'true' || echo 'false'" \
  "Check if string ends with suffix" 

preview_function "str_trim" \
  "str_trim '  Hello World  '" \
  "Trim whitespace from string"

preview_function "str_to_upper" \
  "str_to_upper 'Hello World'" \
  "Convert string to uppercase"

preview_function "str_to_lower" \
  "str_to_lower 'Hello World'" \
  "Convert string to lowercase"

preview_function "str_length" \
  "str_length 'Hello World'" \
  "Get string length"

preview_function "str_replace" \
  "str_replace 'Hello World' 'World' 'Universe'" \
  "Replace substring in string"

# ARRAY FUNCTIONS
echo -e "\e[1m===== ARRAY FUNCTIONS =====\e[0m\n"

preview_function "array_contains" \
  "fruits=('apple' 'banana' 'orange'); array_contains 'banana' \"\${fruits[@]}\" && echo 'true' || echo 'false'" \
  "Check if array contains element"

preview_function "array_join" \
  "fruits=('apple' 'banana' 'orange'); array_join ', ' \"\${fruits[@]}\"" \
  "Join array elements with delimiter"

preview_function "array_length" \
  "declare -a arr=('one' 'two' 'three'); array_length arr" \
  "Get array length"

# FILE FUNCTIONS
echo -e "\e[1m===== FILE & DIRECTORY FUNCTIONS =====\e[0m\n"

preview_function "command_exists" \
  "command_exists 'ls' && echo 'true' || echo 'false'" \
  "Check if command exists"

preview_function "file_exists" \
  "file_exists '$(get_script_path)' && echo 'true' || echo 'false'" \
  "Check if file exists"

preview_function "dir_exists" \
  "dir_exists '$(dirname $(get_script_path))' && echo 'true' || echo 'false'" \
  "Check if directory exists"

preview_function "file_size" \
  "file_size '$(get_script_path)'" \
  "Get file size in bytes"

preview_function "get_file_extension" \
  "get_file_extension 'document.pdf'" \
  "Get file extension"

preview_function "get_file_basename" \
  "get_file_basename 'document.pdf'" \
  "Get filename without extension"

preview_function "wait_for_file" \
  "# wait_for_file '/tmp/test.txt' 5 1 (waits for 5 seconds, checks every 1s)" \
  "Wait for a file to exist (example only, not executed)"

# NUMBER FORMATTING
echo -e "\e[1m===== NUMBER FORMATTING FUNCTIONS =====\e[0m\n"

preview_function "format_si_number" \
  "format_si_number 1500" \
  "Format number with SI prefix (K)"

preview_function "format_si_number" \
  "format_si_number 1500000" \
  "Format number with SI prefix (M)"

preview_function "format_si_number" \
  "format_si_number 0.001" \
  "Format number with SI prefix (m)"

preview_function "format_si_number" \
  "format_si_number 1234567 2" \
  "Format number with SI prefix and custom precision"

preview_function "format_bytes" \
  "format_bytes 1024" \
  "Format bytes (KB)"

preview_function "format_bytes" \
  "format_bytes 1048576" \
  "Format bytes (MB)"

preview_function "format_bytes" \
  "format_bytes 1234567 2" \
  "Format bytes with custom precision"

# DATE & TIME FUNCTIONS
echo -e "\e[1m===== DATE & TIME FUNCTIONS =====\e[0m\n"

preview_function "get_timestamp" \
  "get_timestamp" \
  "Get current Unix timestamp"

preview_function "format_date" \
  "format_date '%Y-%m-%d %H:%M:%S'" \
  "Format current date"

preview_function "format_date" \
  "format_date '%Y-%m-%d' 1672574400" \
  "Format specific timestamp (2023-01-01)"

preview_function "time_diff_human" \
  "time_diff_human 1000 4830" \
  "Human-readable time difference (1h 3m 50s)"

# SYSTEM & ENVIRONMENT FUNCTIONS
echo -e "\e[1m===== SYSTEM & ENVIRONMENT FUNCTIONS =====\e[0m\n"

preview_function "env_or_default" \
  "env_or_default 'PATH' 'not found'" \
  "Get environment variable with default (PATH exists)"

preview_function "env_or_default" \
  "env_or_default 'NONEXISTENT_VAR' 'default value'" \
  "Get environment variable with default (non-existent)"

preview_function "get_current_user" \
  "get_current_user" \
  "Get current username"

preview_function "get_hostname" \
  "get_hostname" \
  "Get hostname"

preview_function "get_os" \
  "get_os" \
  "Get operating system type"

preview_function "get_arch" \
  "get_arch" \
  "Get processor architecture"

preview_function "is_root" \
  "is_root && echo 'Running as root' || echo 'Not running as root'" \
  "Check if script is running as root"

preview_function "is_in_container" \
  "is_in_container && echo 'In container' || echo 'Not in container'" \
  "Check if running in a container"

# LOG FUNCTIONS
echo -e "\e[1m===== LOGGING FUNCTIONS =====\e[0m\n"

echo -e "Log function examples:"
echo -e "${GRAY}# log_init creates a log file in the current directory or uses specified file${NC}"
echo -e "${GRAY}# log_init [log_file] [save_to_file]${NC}"
echo -e "${GRAY}# Following log calls would normally append to the log file when initialized${NC}"
echo -e "${BLUE}log_info \"Information message\"${NC}"
echo -e "${YELLOW}log_warn \"Warning message\"${NC}"
echo -e "${RED}log_error \"Error message\"${NC}"
echo -e "${GREEN}log_success \"Success message\"${NC}"
echo -e "${GRAY}# log_debug only displays if DEBUG=1${NC}"
echo -e "${CYAN}DEBUG=1; log_debug \"Debug message\"${NC}"
echo -e ""

# SCRIPT LOCK FUNCTIONS
echo -e "\e[1m===== SCRIPT LOCK FUNCTIONS =====\e[0m\n"

echo -e "Lock function examples (not executed):"
echo -e "${GRAY}# create_lock acquires exclusive lock to prevent multiple instances${NC}"
echo -e "${GRAY}if create_lock \"/tmp/script.lock\"; then${NC}"
echo -e "${GRAY}  echo \"Lock acquired, running exclusively\"${NC}"
echo -e "${GRAY}  # Do work...${NC}"
echo -e "${GRAY}  release_lock  # Optional, auto-released on exit${NC}"
echo -e "${GRAY}else${NC}"
echo -e "${GRAY}  echo \"Another instance is already running\"${NC}"
echo -e "${GRAY}fi${NC}"
echo -e ""

# USER INTERACTION FUNCTIONS
echo -e "\e[1m===== USER INTERACTION FUNCTIONS =====\e[0m\n"

echo -e "User interaction examples (not executed as they require input):"
echo -e "${GRAY}# confirm \"Continue?\" [default]${NC}"
echo -e "${GRAY}# Returns true (0) if user confirms, false (1) otherwise${NC}"
echo -e ""
echo -e "${GRAY}# prompt_input \"Enter value:\" [default]${NC}"
echo -e "${GRAY}# Returns user input or default if empty${NC}"
echo -e ""
echo -e "${GRAY}# prompt_password \"Enter password:\"${NC}"
echo -e "${GRAY}# Returns password (hidden input)${NC}"
echo -e ""

# GET VALUE FUNCTIONS
echo -e "\e[1m===== GET VALUE FUNCTIONS =====\e[0m\n"

echo -e "Get value function examples (not executed as they require input):"
echo -e "${GRAY}# get_number \"Enter number:\" [default] [min] [max]${NC}"
echo -e "${GRAY}# Validates numeric input with optional range${NC}"
echo -e ""
echo -e "${GRAY}# get_string \"Enter string:\" [default] [pattern] [error_msg]${NC}"
echo -e "${GRAY}# Validates string input with optional regex pattern${NC}"
echo -e ""
echo -e "${GRAY}# get_path \"Enter path:\" [default] [type] [must_exist]${NC}"
echo -e "${GRAY}# type: \"file\", \"dir\", or empty; must_exist: 0 or 1${NC}"
echo -e ""
echo -e "${GRAY}# get_value \"Enter value:\" [default] [validator_func] [error_msg]${NC}"
echo -e "${GRAY}# Uses custom validation function${NC}"
echo -e "${GRAY}# Example validator:${NC}"
echo -e "${GRAY}# is_valid_email() { [[ \"\$1\" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$ ]]; }${NC}"
echo -e ""

# ERROR HANDLING FUNCTIONS
echo -e "\e[1m===== ERROR HANDLING FUNCTIONS =====\e[0m\n"

echo -e "Error handling examples (not executed):"
echo -e "${GRAY}# print_stack_trace${NC}"
echo -e "${GRAY}# Prints current call stack with line numbers${NC}"
echo -e ""
echo -e "${GRAY}# error_handler is called automatically on script errors${NC}"
echo -e "${GRAY}# when setup_traps is used (called by init)${NC}"
echo -e ""
echo -e "${GRAY}# setup_traps${NC}"
echo -e "${GRAY}# Sets up trap handlers for script signals${NC}"
echo -e ""

# DEPENDENCY MANAGEMENT
echo -e "\e[1m===== DEPENDENCY MANAGEMENT =====\e[0m\n"

preview_function "check_dependencies" \
  "check_dependencies bash ls && echo 'All dependencies available' || echo 'Missing dependencies'" \
  "Check if required commands exist"

# NETWORKING FUNCTIONS
echo -e "\e[1m===== NETWORKING FUNCTIONS =====\e[0m\n"

echo -e "Networking function examples (not executed for safety):"
echo -e "${GRAY}# is_url_reachable \"https://example.com\" [timeout]${NC}"
echo -e "${GRAY}# Checks if URL is reachable within timeout seconds${NC}"
echo -e ""
echo -e "${GRAY}# get_external_ip${NC}"
echo -e "${GRAY}# Gets the external IP address${NC}"
echo -e ""
echo -e "${GRAY}# is_port_open \"host\" port [timeout]${NC}"
echo -e "${GRAY}# Checks if port on host is open within timeout seconds${NC}"
echo -e ""

# MESSAGE FUNCTIONS
echo -e "\e[1m===== MESSAGE FUNCTIONS =====\e[0m\n"

echo -e "Message styling examples:"
msg_info "This is an info message"
msg_success "This is a success message"
msg_warning "This is a warning message"
msg_error "This is an error message"
msg_highlight "This is a highlighted message"
msg_header "This is a header message"
msg_section "This is a section divider"
msg_subtle "This is a subtle message"
msg_step 2 5 "This is step 2 of 5"

echo -e "\n\e[1m===== END OF PREVIEW =====\e[0m"
echo -e "Run with: ./test-function-preview.sh\n" 