#!/usr/bin/env bash
# ===================================================================
# tmux_simple_manage.sh - Simple tmux manager demonstration
# ===================================================================
# DESCRIPTION:
#   This example shows how to use the simplified management pane to
#   monitor variables and provide basic controls in a single interface.
#   It creates a tmux session with three panes:
#     1. Management pane - Shows variables and provides controls (includes time tracking)
#     2. Green counter - Increments by 2 every second
#     3. Blue counter - Increments by 3 every 2 seconds
#
# USAGE:
#   ./tmux_simple_manage.sh [--headless]
#   Options:
#     --headless    Create session without launching a terminal
# ===================================================================

# === SETUP ===
SCRIPT_DIR="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../..")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management
sh-globals_init "$@"

# Process --headless argument
HEADLESS=''
[[ "$1" == "--headless" ]] && HEADLESS="$1" && msg_info "Running in headless mode"

# === SHARED VARIABLES : Define the variables to be initialized
COUNTER_VARS=("counter_green" "counter_blue" "session_time")

# === PANE FUNCTIONS ===
# Function for the green counter pane
Green() {
    local session="$1"
    
    while true; do
        local current_green=$(tmx_var_get "counter_green" "$session")
        local v=$((current_green + 2))
        tmx_var_set "counter_green" "$v" "$session"
        clear
        msg_bg_green "GREEN COUNTER"
        msg_green "Value: ${v}"
        msg_green "Press '1' in control pane to close"
        sleep 1
    done
}

# Function for the blue counter pane
Blue() {
    local session="$1"
    
    while true; do
        local current_blue=$(tmx_var_get "counter_blue" "$session")
        local v=$((current_blue + 3))
        tmx_var_set "counter_blue" "$v" "$session"
        clear
        msg_bg_blue "BLUE COUNTER"
        msg_blue "Value: ${v}"
        msg_blue "Press '2' in control pane to close"
        sleep 2
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session with unique timestamp
    local session_name="manage_demo_$(date +%s)"
    
    # Create the session and initialize variables
    msg_info "Creating tmux session: ${session_name}"
    if tmx_create_session_with_vars "${session_name}" COUNTER_VARS 0 "${HEADLESS}"; then
        msg_success "Session created: ${TMX_SESSION_NAME}"
    else
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi
    
    # Create worker panes first
    msg_info "Creating counter panes..."
    # Use tmx_new_pane_func for creating the counter panes
    local p1_id=$(tmx_new_pane_func Green)
    local p2_id=$(tmx_new_pane_func Blue)
    
    # Create the management pane in pane 0
    msg_info "Creating management pane..."
    local p0_id=$(tmx_create_monitoring_control "${TMX_SESSION_NAME}" COUNTER_VARS "PANE" "1" "0")
    
    # Ensure pane titles are visible
    tmx_enable_pane_titles "${TMX_SESSION_NAME}"
    
    # Display comprehensive session information
    tmx_display_info "${TMX_SESSION_NAME}"
    
    # Monitor the session until it terminates
    tmx_monitor_session "${TMX_SESSION_NAME}" 0.5
    
    return 0
}

# Run the main function and exit with its status
main
exit $? 