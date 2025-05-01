#!/usr/bin/bash
# Example usage of param_handler.sh with simplified API

# Get the directory where this script is located
 SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source sh-globals.sh directly to set SH_GLOBALS_LOADED variablee606
GLOBALS_SCRIPT="${SCRIPT_DIR}/../sh-globals.sh"

if [[ -f "${GLOBALS_SCRIPT}" ]]; then
    # shellcheck disable=SC1090
    source "${GLOBALS_SCRIPT}"
else
    msg_error "Could not find sh-globals.sh at ${GLOBALS_SCRIPT}"
    exit 1
fi

# Check if globals were properly loaded
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    msg_error "Failed to load sh-globals.sh"
    exit 1
fi

# Source param_handler.sh relative to this script
PARAM_HANDLER_PATH="${SCRIPT_DIR}/../param_handler.sh"

if [[ -f "${PARAM_HANDLER_PATH}" ]]; then
    # shellcheck disable=SC1090
    source "${PARAM_HANDLER_PATH}"
else
    msg_error "param_handler.sh not found at ${PARAM_HANDLER_PATH}"
    exit 1
fi

# Define parameters in an ordered array using colon-separated format (internal_name:VAR_NAME:option_name:description)
declare -a PARAMS=(
    "graphic:VIRT_GRAPHIC:virt-graphic:Virtual graphics configuration"
    "video:VIRT_VIDEO:virt-video:Virtual video device settings"
    "render:RENDER:render:Rendering mode (software/virtual)"
    "gpu:GPU_VENDOR:gpu:GPU vendor (amd/nvidia/intel) or PCI address"
)

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
    
    # Display parameter order with numbers
    local param_order=""
    for i in "${!PARAMS[@]}"; do
        local param_item="${PARAMS[$i]}"
        local param_parts
        IFS=':' read -ra param_parts <<< "$param_item"
        param_order+="$(($i + 1)). ${param_parts[0]} (${param_parts[1]})  "
    done
    msg_info "Parameter order: ${param_order}"
    
    # Reset variables for this test
    VIRT_GRAPHIC="" VIRT_VIDEO="" RENDER="" GPU_VENDOR=""
    
    # Process all parameters in one step using the global PARAMS array
    param_handler::simple_handle PARAMS "${cmd_args[@]}"
    
    # Print the parameter values and how they were set
    msg_section "Parameter Values" 40
    param_handler::print_params_extended
    
    # Print summary counts
    msg_section "Parameter Counts" 40
    msg_info "Named parameters: $(param_handler::get_named_count)"
    msg_info "Positional parameters: $(param_handler::get_positional_count)"
    msg_info "Total parameters: $(($(param_handler::get_named_count) + $(param_handler::get_positional_count)))"
}

# If arguments are provided, run the script with those arguments
if [[ $# -gt 0 ]]; then
    # Process all parameters in one step using the global PARAMS array
    if ! param_handler::simple_handle PARAMS "$@"; then
        exit 0  # Help was shown, exit successfully
    fi
    
    # Print the parameter values and how they were set
    msg_section "Parameter Values" 40
    param_handler::print_params
    
    # Example of getting individual parameter values
    msg_section "Using Individual Parameter Values" 40
    msg_info "VIRT_GRAPHIC value: $(param_handler::get_param "graphic")"
    
    # Example of checking how parameters were set
    msg_section "Checking Parameter Sources" 40
    if param_handler::was_set_by_name "graphic"; then
        msg_success "Graphic was set by name"
    else
        msg_warning "Graphic was not set by name"
    fi
    
    if param_handler::was_set_by_position "video"; then
        msg_success "Video was set by position"
    else
        msg_warning "Video was not set by position"
    fi
    
    # Example of typical application logic
    msg_section "Application Logic" 40
    if [[ -n "$GPU_VENDOR" ]]; then
        msg_info "Processing GPU configuration: $GPU_VENDOR"
    else
        msg_info "No GPU specified, using software rendering"
    fi
    
    # Example of exporting parameters
    msg_section "Exporting Parameters" 40
    param_handler::export_params --prefix "EXPORTED_"
    msg_info "Exported VIRT_GRAPHIC as: EXPORTED_VIRT_GRAPHIC=${EXPORTED_VIRT_GRAPHIC}"
    
    # Example of JSON export
    msg_section "JSON Format" 40
    param_handler::export_params --format json
    
    # Print summary counts
    msg_section "Parameter Counts" 40
    msg_info "Named parameters: $(param_handler::get_named_count)"
    msg_info "Positional parameters: $(param_handler::get_positional_count)"
    msg_info "Total parameters: $(($(param_handler::get_named_count) + $(param_handler::get_positional_count)))"
    
    exit 0
fi

# Run multiple test cases
msg_header "Running multiple test cases for param_handler.sh (with ordered arrays)"

# Tests with no parameters
run_test 1 "No parameters" 

# Tests with named parameters
run_test 2 "1 Named parameter" --virt-graphic "spice"
run_test 3 "2 Named parameters" --virt-graphic "spice" --virt-video "qxl"
run_test 4 "3 Named parameters" --virt-graphic "spice" --virt-video "qxl" --render "software"
run_test 5 "4 Named parameters" --virt-graphic "spice" --virt-video "qxl" --render "software" --gpu "nvidia"

# Tests with positional parameters
run_test 6 "1 Positional parameter" "spice"
run_test 7 "2 Positional parameters" "spice" "qxl"
run_test 8 "3 Positional parameters" "spice" "qxl" "software"
run_test 9 "4 Positional parameters" "spice" "qxl" "software" "nvidia"

# Mixed parameter tests
run_test 10 "Mixed parameters" --virt-graphic "spice" "qxl" --gpu "nvidia"
run_test 11 "First parameter positional, rest named" "spice" --virt-video "qxl" --render "software" --gpu "nvidia"
run_test 12 "Mixed parameter order 1" "spice" --virt-video "qxl" "software" --gpu "nvidia"
run_test 13 "Mixed parameter order 2" --virt-graphic "spice" "qxl" "software" --gpu "nvidia"

msg_header "Testing with different parameter counts"

# Test with a single parameter
run_test_single() {
    local test_num="$1"
    local description="$2"
    shift 2
    local cmd_args=("$@")
    
    msg_section "TEST ${test_num}: ${description}" 60
    msg_info "Command: $0 ${cmd_args[*]}"
    
    # Reset variables
    SINGLE_PARAM=""
    
    # Define 1 parameter in the array
    declare -a SINGLE_PARAMS=(
        "param:SINGLE_PARAM:single-param:Single parameter test"
    )
    
    # Display parameter order
    local param_order=""
    for i in "${!SINGLE_PARAMS[@]}"; do
        local param_item="${SINGLE_PARAMS[$i]}"
        local param_parts
        IFS=':' read -ra param_parts <<< "$param_item"
        param_order+="$(($i + 1)). ${param_parts[0]} (${param_parts[1]})  "
    done
    msg_info "Parameter order: ${param_order}"
    
    # Process parameters
    param_handler::simple_handle SINGLE_PARAMS "${cmd_args[@]}"
    
    msg_section "Parameter Values" 40
    param_handler::print_params_extended
    
    msg_section "Parameter Counts" 40
    msg_info "Named parameters: $(param_handler::get_named_count)"
    msg_info "Positional parameters: $(param_handler::get_positional_count)"
    msg_info "Total parameters: $(($(param_handler::get_named_count) + $(param_handler::get_positional_count)))"
}

# Test with two parameters
run_test_two() {
    local test_num="$1"
    local description="$2"
    shift 2
    local cmd_args=("$@")
    
    msg_section "TEST ${test_num}: ${description}" 60
    msg_info "Command: $0 ${cmd_args[*]}"
    
    # Reset variables
    FIRST_PARAM="" SECOND_PARAM=""
    
    # Define 2 parameters in the array
    declare -a TWO_PARAMS=(
        "first:FIRST_PARAM:param1:First parameter"
        "second:SECOND_PARAM:param2:Second parameter"
    )
    
    # Display parameter order
    local param_order=""
    for i in "${!TWO_PARAMS[@]}"; do
        local param_item="${TWO_PARAMS[$i]}"
        local param_parts
        IFS=':' read -ra param_parts <<< "$param_item"
        param_order+="$(($i + 1)). ${param_parts[0]} (${param_parts[1]})  "
    done
    msg_info "Parameter order: ${param_order}"
    
    # Process parameters
    param_handler::simple_handle TWO_PARAMS "${cmd_args[@]}"
    
    msg_section "Parameter Values" 40
    param_handler::print_params_extended
    
    msg_section "Parameter Counts" 40
    msg_info "Named parameters: $(param_handler::get_named_count)"
    msg_info "Positional parameters: $(param_handler::get_positional_count)"
    msg_info "Total parameters: $(($(param_handler::get_named_count) + $(param_handler::get_positional_count)))"
}

# Test with 8 parameters
run_test_many() {
    local test_num="$1"
    local description="$2"
    shift 2
    local cmd_args=("$@")
    
    msg_section "TEST ${test_num}: ${description}" 60
    msg_info "Command: $0 ${cmd_args[*]}"
    
    # Reset variables
    PARAM1="" PARAM2="" PARAM3="" PARAM4="" PARAM5="" PARAM6="" PARAM7="" PARAM8=""
    
    # Define 8 parameters in the array
    declare -a MANY_PARAMS=(
        "one:PARAM1:param1:First parameter"
        "two:PARAM2:param2:Second parameter"
        "three:PARAM3:param3:Third parameter"
        "four:PARAM4:param4:Fourth parameter"
        "five:PARAM5:param5:Fifth parameter"
        "six:PARAM6:param6:Sixth parameter"
        "seven:PARAM7:param7:Seventh parameter"
        "eight:PARAM8:param8:Eighth parameter"
    )
    
    # Display parameter order
    local param_order=""
    for i in "${!MANY_PARAMS[@]}"; do
        local param_item="${MANY_PARAMS[$i]}"
        local param_parts
        IFS=':' read -ra param_parts <<< "$param_item"
        param_order+="$(($i + 1)). ${param_parts[0]} (${param_parts[1]})  "
    done
    msg_info "Parameter order: ${param_order}"
    
    # Process parameters
    param_handler::simple_handle MANY_PARAMS "${cmd_args[@]}"
    
    msg_section "Parameter Values" 40
    param_handler::print_params_extended
    
    msg_section "Parameter Counts" 40
    msg_info "Named parameters: $(param_handler::get_named_count)"
    msg_info "Positional parameters: $(param_handler::get_positional_count)"
    msg_info "Total parameters: $(($(param_handler::get_named_count) + $(param_handler::get_positional_count)))"
}

# Run the tests with different parameter counts
run_test_single 14 "Single parameter" --single-param "value1"
run_test_single 15 "Single parameter (positional)" "positional_value"

run_test_two 16 "Two parameters" --param1 "first_value" --param2 "second_value"
run_test_two 17 "Two parameters (positional)" "first_positional" "second_positional"
run_test_two 18 "Two parameters (mixed)" --param1 "named_value" "positional_value"

run_test_many 19 "Eight parameters (all named)" --param1 "v1" --param2 "v2" --param3 "v3" --param4 "v4" --param5 "v5" --param6 "v6" --param7 "v7" --param8 "v8"
run_test_many 20 "Eight parameters (all positional)" "p1" "p2" "p3" "p4" "p5" "p6" "p7" "p8"
run_test_many 21 "Eight parameters (mixed)" --param1 "v1" "p2" --param3 "v3" "p4" --param5 "v5" "p6" --param7 "v7" "p8"

exit 0