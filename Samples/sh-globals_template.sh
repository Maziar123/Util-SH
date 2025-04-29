#!/usr/bin/bash
# Script Template - Starting point for new scripts
# Shows the standardized way to load dependencies

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source sh-globals.sh directly to get access to all utilities
GLOBALS_SCRIPT="${SCRIPT_DIR}/../sh-globals.sh"

# Check if globals file exists and can be properly loaded
if [[ ! -f "${GLOBALS_SCRIPT}" ]]; then
    echo "Error: Could not find sh-globals.sh at ${GLOBALS_SCRIPT}" >&2
    exit 1
else
    # shellcheck disable=SC1090
    source "${GLOBALS_SCRIPT}"
    if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
        echo "Error: Failed to load sh-globals.sh" >&2
        exit 1
    fi
fi

# ------------------------------------------------------------------------
# Now you can use any function from sh-globals.sh
# ------------------------------------------------------------------------

# Initialize logging (optional)
log_init "$(get_script_name).log"

# Example of using functions from sh-globals.sh
log_info "Script started: $(get_script_name)"
log_info "Script directory: $(get_script_dir)"

# Parse command-line arguments
parse_flags "$@"

if [[ "${DEBUG:-0}" -eq 1 ]]; then
    log_debug "Debug mode enabled"
fi

# Example of using path functions
ANOTHER_SCRIPT="$(path_relative_to_script "../some_other_script.sh")"
log_info "Another script would be at: ${ANOTHER_SCRIPT}"

# Clean up on exit
trap 'log_info "Script finished"; cleanup_temp' EXIT

# Main script logic would go here
msg_header "Script Template Example"
msg_info "This is a template for creating new scripts"
msg_success "You can use any function from sh-globals.sh"

exit 0 