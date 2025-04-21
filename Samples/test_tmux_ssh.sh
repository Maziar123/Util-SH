#!/usr/bin/env bash

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
echo "SCRIPT_DIR: ${SCRIPT_DIR}"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/sh-globals.sh"
# shellcheck source=../tmux_utils1.sh
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals only if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    # Enable debug logging
    export DEBUG=1
    sh-globals_init "$@"
fi

# Global variable for session name
SESSION_NAME=""

main() {
    log_debug "Start main"
    
    if ! create_tmux_session; then
        msg_error "Failed to create session. Exiting."
        exit 1
    fi
    log_debug "Session created: ${SESSION_NAME}"
    sleep 1

    if ! execute_in_pane "${SESSION_NAME}" 0 "echo 'Connecting to ip1...'; ssh ip1"; then
        log_debug "Failed: ip1 command"
    fi
    
    if create_new_pane "${SESSION_NAME}"; then
        if ! execute_in_pane "${SESSION_NAME}" 1 "echo 'Connecting to ip2...'; ssh ip2"; then
            log_debug "Failed: ip2 command"
        fi
    else
        log_debug "Failed: create pane"
    fi

    log_debug "Main completed"
}

log_debug "Script start"
main
log_debug "Script end"