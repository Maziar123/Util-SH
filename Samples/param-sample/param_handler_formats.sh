#!/usr/bin/bash
# Example of different format options for param_handler.sh using ordered arrays

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source sh-globals.sh directly
GLOBALS_SCRIPT="${SCRIPT_DIR}/../sh-globals.sh"
if [[ -f "${GLOBALS_SCRIPT}" ]]; then
    # shellcheck disable=SC1090
    source "${GLOBALS_SCRIPT}"
else
    echo "Could not find sh-globals.sh at ${GLOBALS_SCRIPT}"
    exit 1
fi

# Source param_handler.sh relative to this script
PARAM_HANDLER_PATH="${SCRIPT_DIR}/../param_handler.sh"
if [[ -f "${PARAM_HANDLER_PATH}" ]]; then
    # shellcheck disable=SC1090
    source "${PARAM_HANDLER_PATH}"
else
    echo "param_handler.sh not found at ${PARAM_HANDLER_PATH}"
    exit 1
fi

# Function to show format examples
show_format_examples() {
    # Reset variables for this section
    NAME="" AGE="" COLOR="" CITY="" ROLE="" LEVEL=""
    
    msg_section "Format Example: $1" 60
    shift
    
    # Define the array with the given parameters
    declare -a PARAMS=("$@")
    
    # Print the raw array definition
    msg_info "Array definition:"
    for item in "${PARAMS[@]}"; do
        echo "  \"$item\""
    done
    echo ""
    
    # Process parameters with test values
    local test_args=("John" "25" "blue" "New York" "developer" "senior")
    param_handler::simple_handle PARAMS "${test_args[@]}"
    
    # Print the parameter values
    msg_section "Parameter Values" 40
    param_handler::print_params_extended
    
    echo ""
}

# Run various format examples
msg_header "Demonstrating different parameter format options"

# Example 1: Minimal format (internal_name:VAR_NAME)
show_format_examples "Minimal Format" \
    "name:NAME" \
    "age:AGE" \
    "color:COLOR" \
    "city:CITY" \
    "role:ROLE" \
    "level:LEVEL"

# Example 2: With option names (internal_name:VAR_NAME:option_name)
show_format_examples "With Option Names" \
    "name:NAME:fullname" \
    "age:AGE:years" \
    "color:COLOR:preferred-color" \
    "city:CITY:location" \
    "role:ROLE:job-role" \
    "level:LEVEL:experience"

# Example 3: Full format (internal_name:VAR_NAME:option_name:description)
show_format_examples "With Descriptions" \
    "name:NAME:fullname:Person's full name" \
    "age:AGE:years:Person's age in years" \
    "color:COLOR:preferred-color:Favorite color" \
    "city:CITY:location:City of residence" \
    "role:ROLE:job-role:Current job role" \
    "level:LEVEL:experience:Experience level"

# Example 4: With required flag (internal_name:VAR_NAME:option_name:description:REQUIRE)
show_format_examples "With Required Flag" \
    "name:NAME:fullname:Person's full name:REQUIRE" \
    "age:AGE:years:Person's age in years:REQUIRE" \
    "color:COLOR:preferred-color:Favorite color" \
    "city:CITY:location:City of residence" \
    "role:ROLE:job-role:Current job role" \
    "level:LEVEL:experience:Experience level"

# Example 5: Mixed formats in same array
show_format_examples "Mixed Formats" \
    "name:NAME:fullname:Person's full name:REQUIRE" \
    "age:AGE:years:Person's age in years" \
    "color:COLOR:preferred-color" \
    "city:CITY" \
    "role:ROLE:job-role:Current job role" \
    "level:LEVEL"

exit 0 