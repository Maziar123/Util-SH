#!/usr/bin/env bash
# test-sh-globals-interactive-demo.sh - Interactive examples of get_value functions in sh-globals.sh

# Source the library
source "$(dirname "$0")/../sh-globals.sh"

# Output formatting
echo -e "\n\e[1m===== SH-GLOBALS.SH INTERACTIVE DEMO =====\e[0m"
echo -e "This script demonstrates functions that require user input\n"

# Function to display section header
section() {
  echo -e "\n\e[1m===== $1 =====\e[0m"
  echo -e "$2\n"
}

# Function to demonstrate with explanation
demo() {
  local func_name="$1"
  local cmd="$2"
  local description="$3"
  
  echo -e "\e[1m== $func_name ==\e[0m"
  echo -e "\e[90m$description\e[0m"
  echo -e "\e[96mCommand:\e[0m $cmd"
  echo -ne "\e[96mYour input:\e[0m "
  
  # Run the command and capture result
  local result
  result=$(eval "$cmd")
  
  echo -e "\e[96mResult:\e[0m '$result'"
  echo
}

# Confirm if user wants to proceed with interactive examples
echo -e "This script will demonstrate interactive functions from sh-globals.sh."
echo -e "You will need to provide input for each example."
echo
if ! confirm "Would you like to proceed?" "y"; then
  echo "Exiting interactive demo."
  exit 0
fi

# USER INTERACTION EXAMPLES
section "CONFIRMATION FUNCTIONS" "These functions ask for yes/no confirmation"

echo -e "== confirm =="
echo -e "\e[90mAsk for yes/no confirmation with default\e[0m"
echo -e "\e[96mCommand:\e[0m confirm \"Do you like shell scripting?\" \"y\""
if confirm "Do you like shell scripting?" "y"; then
  echo -e "\e[96mResult:\e[0m You answered YES"
else
  echo -e "\e[96mResult:\e[0m You answered NO"
fi
echo

# BASIC INPUT EXAMPLES
section "BASIC INPUT FUNCTIONS" "These functions get basic input with optional defaults"

echo -e "== prompt_input =="
echo -e "\e[90mGet text input with default value\e[0m"
echo -e "\e[96mCommand:\e[0m name=\$(prompt_input \"What is your name?\" \"Guest\")"
name=$(prompt_input "What is your name?" "Guest")
echo -e "\e[96mResult:\e[0m 'Hello, $name!'"
echo

echo -e "== prompt_password =="
echo -e "\e[90mGet password input (hidden as you type)\e[0m"
echo -e "\e[96mCommand:\e[0m password=\$(prompt_password \"Enter a sample password:\")"
password=$(prompt_password "Enter a sample password:")
echo -e "\e[96mResult:\e[0m Password length: ${#password} characters"
echo

# GET_VALUE FUNCTIONS
section "GET_VALUE FUNCTIONS" "These functions validate input as you type"

# Get number with validation
echo -e "== get_number =="
echo -e "\e[90mGet numeric input with range validation\e[0m"
echo -e "\e[96mCommand:\e[0m number=\$(get_number \"Enter a number between 1-10:\" \"5\" \"1\" \"10\")"
number=$(get_number "Enter a number between 1-10:" "5" "1" "10")
echo -e "\e[96mResult:\e[0m You entered: $number"
echo

# Get string with pattern validation
echo -e "== get_string =="
echo -e "\e[90mGet string input with pattern validation\e[0m"
echo -e "\e[96mCommand:\e[0m username=\$(get_string \"Enter username (letters and numbers only):\" \"\" \"^[a-zA-Z0-9]+$\" \"Username must contain only letters and numbers\")"
username=$(get_string "Enter username (letters and numbers only):" "" "^[a-zA-Z0-9]+$" "Username must contain only letters and numbers")
echo -e "\e[96mResult:\e[0m Username: $username"
echo

# Get path with validation
echo -e "== get_path =="
echo -e "\e[90mGet path with optional validation\e[0m"
echo -e "\e[96mCommand:\e[0m path=\$(get_path \"Enter a directory path:\" \"/tmp\" \"dir\" \"1\")"
path=$(get_path "Enter a directory path:" "/tmp" "dir" "1")
echo -e "\e[96mResult:\e[0m Path: $path"
echo

# Custom validation
section "CUSTOM VALIDATION" "This demonstrates custom validation with get_value"

# Define a custom validator function
is_valid_email() {
  local email="$1"
  [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

echo -e "== get_value with custom validator =="
echo -e "\e[90mGet input with custom validation function\e[0m"
echo -e "\e[96mCommand:\e[0m email=\$(get_value \"Enter email address:\" \"user@example.com\" is_valid_email \"Please enter a valid email\")"
email=$(get_value "Enter email address:" "user@example.com" is_valid_email "Please enter a valid email")
echo -e "\e[96mResult:\e[0m Email: $email"
echo

# ADVANCED EXAMPLE
section "ADVANCED EXAMPLE" "Combining multiple get_value functions"

echo -e "This example combines multiple input functions to create a simple user profile.\n"

# Get user profile information
name=$(get_string "Enter your full name:" "")
age=$(get_number "Enter your age:" "" "1" "120")
country=$(get_string "Enter your country:" "")
email=$(get_value "Enter your email:" "" is_valid_email "Invalid email format")

# Display collected information
echo -e "\n\e[1mYour Profile:\e[0m"
echo -e "Name: $name"
echo -e "Age: $age"
echo -e "Country: $country"
echo -e "Email: $email"

echo -e "\n\e[1m===== END OF INTERACTIVE DEMO =====\e[0m"
echo -e "Run again with: ./test-sh-globals-interactive-demo.sh\n" 