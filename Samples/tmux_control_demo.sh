#!/usr/bin/env bash
# ===================================================================
# tmux_control_demo.sh - Demonstrating control pane capabilities
# ===================================================================
# DESCRIPTION:
#   This example shows how to use the control pane functionality to
#   monitor and manage multiple counter panes:
#     1. Control pane - Monitor all variables and control other panes
#     2. Green counter - Increments by 2 every second
#     3. Blue counter - Increments by 3 every 2 seconds
#     4. Yellow counter - Increments by 5 every 3 seconds
#
# USAGE:
#   ./tmux_control_demo.sh [--headless]
#   Options:
#     --headless    Create session without launching a terminal
#
#   While running:
#     - Press 1-3 to close corresponding panes
#     - Press 'q' to quit everything
#
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
COUNTER_VARS=("counter_green" "counter_blue" "counter_yellow")

# === PANE FUNCTIONS ===
# Function for the green counter pane
green() {
    local session="$1"
    while true; do
        local current_green=$(tmx_var_get "counter_green" "$session")
        local v=$((current_green + 2))
        tmx_var_set "counter_green" "$v" "$session"
        clear
        msg_bg_green "GREEN COUNTER (PANE 1)"
        msg_green "Value: ${v}"
        msg_green "Press '1' in control pane to close"
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
        msg_bg_blue "BLUE COUNTER (PANE 2)"
        msg_blue "Value: ${v}"
        msg_blue "Press '2' in control pane to close"
        sleep 2
    done
}

# Function for the yellow counter pane
yellow() {
    local session="$1"
    while true; do
        local current_yellow=$(tmx_var_get "counter_yellow" "$session")
        local v=$((current_yellow + 5))
        tmx_var_set "counter_yellow" "$v" "$session"
        clear
        msg_bg_yellow "YELLOW COUNTER (PANE 3)"
        msg_yellow "Value: ${v}"
        msg_yellow "Press '3' in control pane to close"
        sleep 3
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session with unique timestamp
    local session_name="control_demo_$(date +%s)"
    declare session_var=""
    
    # Create the session and initialize variables
    if ! tmx_create_session_with_vars session_var "${session_name}" "$HEADLESS" "COUNTER_VARS"; then
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi
    
    msg_info "Session created: ${session_var}"
    
    # Create the worker panes first
    msg_info "Creating counter panes..."
    p1=$(tmx_pane_function "${session_var}" green "v" "${session_var}")
    p2=$(tmx_pane_function "${session_var}" blue "h" "${session_var}")
    p3=$(tmx_pane_function "${session_var}" yellow "h" "${session_var}")
    
    # Store pane indices for the control pane
    PANES_TO_CONTROL="${p1} ${p2} ${p3}"
    
    # Create the control pane last in pane 0
    msg_info "Creating control pane..."
    msg_debug "Control panes: ${PANES_TO_CONTROL}"
    p0=$(tmx_control_pane "${session_var}" "counter_green counter_blue counter_yellow" "${PANES_TO_CONTROL}" "0" "1")
    
    # Keep parent process running
    echo "Running in: ${session_var} - Press Ctrl+C to exit"
    while true; do sleep 1; done
}

main 