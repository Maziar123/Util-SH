#!/usr/bin/bash
# Example showing backwards compatibility of param_handler::ordered_handle with original format

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source sh-globals.sh directly to set SH_GLOBALS_LOADED variable
GLOBALS_SCRIPT="${SCRIPT_DIR}/../sh-globals.sh"

if [[ -f "${GLOBALS_SCRIPT}" ]]; then
    # shellcheck disable=SC1090
    source "${GLOBALS_SCRIPT}"
else
    echo "Could not find sh-globals.sh at ${GLOBALS_SCRIPT}"
    exit 1
fi

# Check if globals were properly loaded
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    echo "Failed to load sh-globals.sh"
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

# Run multiple test cases
msg_header "Testing ordered_handle using original format strings"

# Define a function to run a test case with the given parameters
run_test() {
    # Store all arguments in an array
    local all_args=("$@")
    
    # Extract the first two arguments explicitly
    local test_num="${all_args[0]}"
    local description="${all_args[1]}"
    
    # Create cmd_args array with remaining arguments (starting from index 2)
    local cmd_args=()
    for ((i=2; i<${#all_args[@]}; i++)); do
        cmd_args+=("${all_args[$i]}")
    done
    
    msg_section "TEST ${test_num}: ${description}" 60
    msg_info "Command: $0 ${cmd_args[*]}"
    
    # Reset variables for this test
    VIRT_GRAPHIC="" VIRT_VIDEO="" RENDER="" GPU_VENDOR=""
    
    # Define parameters in an ordered array but using the original format
    # with ["key"]="value" strings
    declare -a COMPAT_PARAMS=(
        '["graphic:VIRT_GRAPHIC:virt-graphic"]="Virtual graphics configuration"'
        '["video:VIRT_VIDEO:virt-video"]="Virtual video device settings"'
        '["render:RENDER"]="Rendering mode (software/virtual)"'
        '["gpu:GPU_VENDOR"]="GPU vendor (amd/nvidia/intel) or PCI address"'
    )
    
    # Process all parameters with ordered_handle (using compatibility mode)
    param_handler::ordered_handle COMPAT_PARAMS "${cmd_args[@]}"
    
    # Print the parameter values and how they were set
    msg_section "Parameter Values" 40
    param_handler::print_params_extended
    
    # Print summary counts
    msg_section "Parameter Counts" 40
    msg_info "Named parameters: $(param_handler::get_named_count)"
    msg_info "Positional parameters: $(param_handler::get_positional_count)"
    msg_info "Total parameters: $(($(param_handler::get_named_count) + $(param_handler::get_positional_count)))"
}

# Tests with positional parameters
run_test 1 "1 Positional parameter" "spice"
run_test 2 "2 Positional parameters" "spice" "qxl"
run_test 3 "3 Positional parameters" "spice" "qxl" "software" 
run_test 4 "4 Positional parameters" "spice" "qxl" "software" "nvidia"

# Mixed parameter tests
run_test 5 "Mixed parameters" --virt-graphic "spice" "qxl" --gpu "nvidia"

exit 0 