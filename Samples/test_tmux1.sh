#!/usr/bin/env bash
# test_tmux1.sh - Basic demonstration of tmux utilities and variable sharing

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/sh-globals.sh"
# shellcheck source=../tmux_utils1.sh
source "${SCRIPT_DIR}/tmux_utils1.sh"
# Source script functions and examples
# shellcheck source=./tmux_script_functions.sh
source "${SCRIPT_DIR}/Samples/tmux_script_functions.sh"
# shellcheck source=./tmux_embedded_scripts.sh
source "${SCRIPT_DIR}/Samples/tmux_embedded_scripts.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    # Enable debug logging
    export DEBUG=1
    sh-globals_init "$@"
fi

# Global variable for session name
SESSION_NAME=""

# Define shared variables that will be passed to tmux sessions
APP_NAME="Tmux Utils Demo"
APP_VERSION="1.0.0"
HOSTNAME=$(hostname)
USER_NAME=$(whoami)
CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
SHARED_COUNT=0
SHARED_DIR="/tmp/tmux_test_$(date +%s)"

# Create shared directory for variable exchange
mkdir -p "${SHARED_DIR}"
echo "${SHARED_COUNT}" > "${SHARED_DIR}/counter.txt"

# Helper function to create a temp script file from embedded script
create_temp_script_file() {
    local content="$1"
    local script_file="/tmp/tmux_script_$$.sh"
    echo "$content" > "${script_file}"
    echo "${script_file}"
}

# Function to update the shared counter from any pane
update_shared_counter() {
    local increment="${1:-1}"
    
    # Read current value
    local current_count
    current_count=$(cat "${SHARED_DIR}/counter.txt" 2>/dev/null || echo "0")
    
    # Increment value
    local new_count=$((current_count + increment))
    
    # Write back
    echo "${new_count}" > "${SHARED_DIR}/counter.txt"
    sync
    
    echo "${new_count}"
}

# First demo pane - shows basic session info and increments counter
session_info_demo() {
    # Get the session name directly from tmux
    local this_session=$(tmux display-message -p '#S')
    local pane_id=$(tmux display-message -p '#P')
    
    clear
    msg_header "${APP_NAME} v${APP_VERSION}"
    msg_bg_blue "SESSION: ${this_session} - PANE: ${pane_id}"
    msg_info "This pane demonstrates session info and shared variables"
    echo ""
    
    # Display shared variables from parent shell
    echo "Variables shared from parent shell:"
    echo "- Hostname: ${HOSTNAME}"
    echo "- Username: ${USER_NAME}"
    echo "- Current date: ${CURRENT_DATE}"
    echo ""
    
    # Show and update the shared counter
    for i in {1..5}; do
        local current=$(cat "${SHARED_DIR}/counter.txt" 2>/dev/null || echo "0")
        local new_count=$(update_shared_counter 2)
        
        echo "Shared counter: ${current} -> ${new_count} (+2)"
        sleep 2
    done
    
    msg_success "Demo complete! Press any key to continue..."
    read -n 1
}

# Second demo pane - shows file monitoring and updates counter
file_monitor_demo() {
    # Get the session name directly from tmux
    local this_session=$(tmux display-message -p '#S')
    local pane_id=$(tmux display-message -p '#P')
    
    clear
    msg_header "${APP_NAME} v${APP_VERSION}"
    msg_bg_green "SESSION: ${this_session} - PANE: ${pane_id}"
    msg_info "This pane demonstrates file monitoring and shared counter updates"
    echo ""
    
    # Monitor the shared counter file
    echo "Monitoring shared counter file: ${SHARED_DIR}/counter.txt"
    echo ""
    
    local last_value=""
    for i in {1..10}; do
        local current=$(cat "${SHARED_DIR}/counter.txt" 2>/dev/null || echo "0")
        
        if [[ "${current}" != "${last_value}" ]]; then
            msg_yellow "Counter changed: ${last_value:-N/A} -> ${current}"
            last_value="${current}"
        else
            echo "Counter unchanged: ${current}"
        fi
        
        if [[ $((i % 3)) -eq 0 ]]; then
            local new_value=$(update_shared_counter 5)
            msg_green "Updated counter: ${current} -> ${new_value} (+5)"
        fi
        
        sleep 1
    done
    
    msg_success "Monitoring complete! Press any key to continue..."
    read -n 1
}

# Third demo pane - shows heredoc script execution
embedded_script_demo() {
    # Get the session name directly from tmux
    local this_session=$(tmux display-message -p '#S')
    local pane_id=$(tmux display-message -p '#P')
    
    clear
    msg_header "${APP_NAME} v${APP_VERSION}"
    msg_bg_magenta "SESSION: ${this_session} - PANE: ${pane_id}"
    msg_info "This pane demonstrates embedded script with heredoc"
    echo ""
    
    # Show current counter value
    local current=$(cat "${SHARED_DIR}/counter.txt" 2>/dev/null || echo "0")
    echo "Initial shared counter value: ${current}"
    echo ""
    
    # Run a menu-driven counter increment demo
    msg_cyan "Select a counter operation:"
    select op in "Add 1" "Add 10" "Double" "Reset" "Exit"; do
        case $op in
            "Add 1")
                local new_value=$(update_shared_counter 1)
                msg_green "Counter: ${current} -> ${new_value} (+1)"
                current="${new_value}"
                ;;
            "Add 10")
                local new_value=$(update_shared_counter 10)
                msg_green "Counter: ${current} -> ${new_value} (+10)"
                current="${new_value}"
                ;;
            "Double")
                local new_value=$((current * 2))
                echo "${new_value}" > "${SHARED_DIR}/counter.txt"
                sync
                msg_green "Counter: ${current} -> ${new_value} (doubled)"
                current="${new_value}"
                ;;
            "Reset")
                echo "0" > "${SHARED_DIR}/counter.txt"
                sync
                msg_yellow "Counter reset to 0"
                current="0"
                ;;
            "Exit")
                break
                ;;
            *)
                msg_error "Invalid option"
                ;;
        esac
        echo ""
        echo "Select another operation or Exit:"
    done
    
    msg_success "Script demo complete! Press any key to continue..."
    read -n 1
}

main() {
    log_debug "Start main"
    
    # Create a new tmux session
    SESSION_NAME=$(create_tmux_session)
    if [[ -z "${SESSION_NAME}" ]]; then
        msg_error "Failed to create session. Exiting."
        exit 1
    fi
    msg_success "Created new tmux session: ${SESSION_NAME}"
    sleep 2  # Give time for session to initialize

    # Run the first demo in pane 0
    msg_info "Starting session info demo in pane 0"
    execute_shell_function "${SESSION_NAME}" 0 session_info_demo "APP_NAME APP_VERSION HOSTNAME USER_NAME CURRENT_DATE SHARED_DIR"
    sleep 1

    # Create a new pane and capture its index
    local pane_idx
    pane_idx=$(create_new_pane "${SESSION_NAME}" "v")
    if [[ -n "${pane_idx}" ]]; then
        msg_success "Created new pane with index: ${pane_idx}"
        
        # Run the file monitor demo in pane 1
        msg_info "Starting file monitor demo in pane ${pane_idx}"
        execute_shell_function "${SESSION_NAME}" "${pane_idx}" file_monitor_demo "APP_NAME APP_VERSION SHARED_DIR"
        sleep 1
    else
        log_error "Failed to create pane"
    fi

    # Create a third pane with horizontal split
    local pane_idx2
    pane_idx2=$(create_new_pane "${SESSION_NAME}")
    if [[ -n "${pane_idx2}" ]]; then
        msg_success "Created pane with index: ${pane_idx2}"
        
        # Run the embedded script demo in pane 2
        msg_info "Starting embedded script demo in pane ${pane_idx2}"
        execute_shell_function "${SESSION_NAME}" "${pane_idx2}" embedded_script_demo "APP_NAME APP_VERSION SHARED_DIR"
    fi

    msg_info "All panes initialized - watch the shared counter updates across panes"
    msg_info "Shared directory: ${SHARED_DIR}"
    
    # Optional: Wait for session to end
    echo "The script will continue running to maintain the parent process."
    echo "Press Ctrl+C to exit when done observing the demo."
    
    # Keep script running until killed
    trap 'echo -e "\nDemonstration ended by user"; exit 0' INT
    while true; do
        sleep 1
    done
}

log_debug "Script start"
main
log_debug "Script end"