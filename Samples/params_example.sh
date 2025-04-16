#!/usr/bin/bash
# Super minimal example of param_handler.sh usage with the simplified API

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source sh-globals.sh directly to get access to path utilities
GLOBALS_SCRIPT="${SCRIPT_DIR}/../sh-globals.sh"

if [[ -f "${GLOBALS_SCRIPT}" ]]; then
    # shellcheck disable=SC1090
    source "${GLOBALS_SCRIPT}"
else
    echo "Error: Could not find sh-globals.sh at ${GLOBALS_SCRIPT}" >&2
    exit 1
fi

# Check if globals were properly loaded
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    echo "Error: Failed to load sh-globals.sh" >&2
    exit 1
fi

# Source param_handler.sh relative to this script
PARAM_HANDLER_PATH="${SCRIPT_DIR}/../param_handler.sh"

if [[ -f "${PARAM_HANDLER_PATH}" ]]; then
    # shellcheck disable=SC1090
    source "${PARAM_HANDLER_PATH}"
else
    log_error "param_handler.sh not found at ${PARAM_HANDLER_PATH}"
    exit 1
fi

# First parameter set
declare -A PARAMS1=(
    ["name:NAME1"]="First name parameter"
    ["age:AGE1"]="First age parameter"
    ["place:PLACE1"]="First place parameter"
)
param_handler::simple_handle PARAMS1 "$@"

# Clear any conflicting variables before second parameter set
unset NAME2 AGE2 PLACE2

# Second parameter set
declare -A PARAMS2=(
    ["name:NAME2"]="Second name parameter"
    ["age:AGE2"]="Second age parameter"
    ["place:PLACE2"]="Second place parameter"
)
param_handler::simple_handle PARAMS2 "$@"

# ===== 1. Direct Variable Access =====
echo "--------------------------------"
echo "Direct Variable Access:"
echo "--------------------------------"
echo "Name: ${NAME1:-not set}"
echo "Age: ${AGE1:-not set}"
echo "Place: ${PLACE1:-not set}"
echo "Name: ${NAME2:-not set}"
echo "Age: ${AGE2:-not set}"
echo "Place: ${PLACE2:-not set}"

# ===== 2. Check How Parameters Were Set =====
echo -e "\n--------------------------------"
echo "Parameter Source Check:"
echo "--------------------------------"
if param_handler::was_set_by_name "name"; then
    echo "Name1 was set via --name option"
elif param_handler::was_set_by_position "name"; then
    echo "Name1 was set as a positional parameter"
else
    echo "Name1 was not set"
fi

if param_handler::was_set_by_name "name"; then
    echo "Name2 was set via --name option"
elif param_handler::was_set_by_position "name"; then
    echo "Name2 was set as a positional parameter"
else
    echo "Name2 was not set"
fi

# ===== 3. Get Parameter Values Programmatically =====
echo -e "\n--------------------------------"
echo "Programmatic Access:"
echo "--------------------------------"
name_value1=$(param_handler::get_param "name" 2>/dev/null || echo "")
echo "Name1 (via get_param): $name_value1"

name_value2=$(param_handler::get_param "name" 2>/dev/null || echo "")
echo "Name2 (via get_param): $name_value2"

# ===== 4. Print All Parameters =====
echo -e "\n--------------------------------"
echo "All Parameters:"
echo "--------------------------------"
param_handler::print_params_extended

# ===== 5. Export Parameters =====
echo -e "\n--------------------------------"
echo "Exporting parameters:"
echo "--------------------------------"
param_handler::export_params --prefix "USER_"
echo "Exported as: USER_NAME1=${USER_NAME1}"
echo "Exported as: USER_NAME2=${USER_NAME2}"

# ===== 6. JSON Export =====
echo -e "\n--------------------------------"
echo "JSON format:"
echo "--------------------------------"
param_handler::export_params --format json

echo "--------------------------------"
echo "Parameters:"
echo "--------------------------------"
param_handler::print_params

echo "--------------------------------"
echo "Summary:"
echo "--------------------------------"
param_handler::print_summary

echo "--------------------------------"
echo "Extended:"
echo "--------------------------------"
param_handler::print_params_extended

echo "--------------------------------"
echo "Help:"
echo "--------------------------------"
param_handler::print_help       

# echo "--------------------------------"
# echo "Usage:"
# echo "--------------------------------"
# param_handler::usage

echo "--------------------------------"
echo "finish"
echo "--------------------------------"

exit 0 