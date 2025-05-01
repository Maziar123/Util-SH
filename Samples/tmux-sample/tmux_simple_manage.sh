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
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management
sh-globals_init "$@"

# Check if the first argument is --headless
HEADLESS='' # Default to not headless
if [[ "$1" = "--headless" ]]; then
    HEADLESS=$1
fi

# === SHARED VARIABLES : Define the variables to be initialized
COUNTER_VARS=("counter_green" "counter_blue" "session_time")

# === PANE FUNCTIONS ===
# Function for the green counter pane
green() {
    local session="$1"
    
    while true; do
        local current_green=$(tmx_var_get "counter_green" "$session")
        local v=$((current_green + 2))
        tmx_var_set "counter_green" "$v" "$session"
        clear
        msg_bg_green "GREEN COUNTER"
        msg_green "Value: ${v}"
        sleep 1
    done
}

# Function for the blue counter pane
blue() {
    local session="$1"
    
    while true; do
        local current_blue=$(tmx_var_get "counter_blue" "$session")
        local v=$((current_blue + 3))
        tmx_var_set "counter_blue" "$v" "$session"
        clear
        msg_bg_blue "BLUE COUNTER"
        msg_blue "Value: ${v}"
        sleep 2
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session with unique timestamp
    local session_name="manage_demo_$(date +%s)"
    declare session_var=""
    
    # Create the session and initialize variables
    if ! tmx_create_session_with_vars session_var "${session_name}" "$HEADLESS" "COUNTER_VARS"; then
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi
    
    msg_info "Session created: ${session_var}"
    
    # Create worker panes first
    msg_info "Creating counter panes..."
    p1=$(tmx_pane_function "${session_var}" green "v" "${session_var}")
    p2=$(tmx_pane_function "${session_var}" blue "h" "${session_var}")
    
    # Create the management pane last in pane 0 (will handle time tracking internally)
    msg_info "Creating management pane..."
    p0=$(tmx_manage_pane "${session_var}" "counter_green counter_blue session_time" "0" "1")
    
    # Keep parent process running
    echo "Running in: ${session_var} - Press Ctrl+C to exit"
    while true; do sleep 1; done
}

main 