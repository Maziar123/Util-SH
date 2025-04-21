#!/usr/bin/bash
# Example of param_handler.sh usage with required parameters
# Shows how to use the REQUIRE flag and validator functions

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

# Now we can use the path functions

# Source param_handler.sh relative to this script
PARAM_HANDLER_PATH="${SCRIPT_DIR}/../param_handler.sh"

if [[ -f "${PARAM_HANDLER_PATH}" ]]; then
    # shellcheck disable=SC1090
    source "${PARAM_HANDLER_PATH}"
else
    log_error "param_handler.sh not found at ${PARAM_HANDLER_PATH}"
    exit 1
fi

# Enable debug mode for param_handler
# Set to 1 to see detailed debug messages during parameter processing
#DEBUG_MSG=1

# Define validator functions
# These functions should return 0 for valid input, non-zero for invalid

# Validate age (must be a number between 1-120)
validate_age() {
    local value="$1"
    
    # Check if it's a number
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "Age must be a number" >&2
        return 1
    fi
    
    # Check range
    if (( value < 1 || value > 120 )); then
        echo "Age must be between 1 and 120" >&2
        return 1
    fi
    
    return 0
}

# Validate email format
validate_email() {
    local value="$1"
    
    # Simple email validation
    if ! [[ "$value" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid email format" >&2
        return 1
    fi
    
    return 0
}

# Define parameters in a single array
# Format: "internal_name:VARIABLE_NAME:option_name:REQUIRE:validator_func"
declare -a PARAMS=(
    # Optional parameter (standard)
    "name:NAME::Person's name"
    
    # Required parameter with validator (using param name as option name)
    "age:AGE:age:REQUIRE:validate_age:Person's age (required, 1-120)"
    
    # Required parameter with custom option name and validator
    "email:EMAIL:email-address:REQUIRE:validate_email:Email address (required)"
    
    # Optional parameter (with custom option name)
    "location:LOCATION:place:Person's location"
)

# Process all parameters in one step
# If validation fails for required parameters, the user will be prompted
if ! param_handler::simple_handle PARAMS "$@"; then
    # This means either help was shown or a required parameter is missing
    # Change exit code for help display to 0
    if [[ -n "$help" ]]; then
        exit 0  # Help displayed successfully
    else
        exit 1  # Required parameters missing
    fi
fi

# ===== Display Information =====
msg_header "Required Parameters Example"

msg_info "Parameter Values:"
msg_section "Values" 40 "-"
echo "Name: ${NAME:-not set}"
echo "Age: ${AGE} (required)"
echo "Email: ${EMAIL} (required)"
echo "Location: ${LOCATION:-not set}"

msg_info "Parameter Sources:"
msg_section "Sources" 40 "-"
if param_handler::was_set_by_name "age"; then
    msg_success "Age was provided via --age option"
elif param_handler::was_set_by_position "age"; then
    msg_highlight "Age was provided as a positional parameter"
else
    msg_warning "Age was provided via prompt (required parameter)"
fi

if param_handler::was_set_by_name "email"; then
    msg_success "Email was provided via --email-address option"
elif param_handler::was_set_by_position "email"; then
    msg_highlight "Email was provided as a positional parameter"
else
    msg_warning "Email was provided via prompt (required parameter)"
fi

msg_info "Parameter Details:"
msg_section "Details" 40 "-"
param_handler::print_params_extended

exit 0 