#!/usr/bin/env bash
# ===================================================================
# tmux_micro_mon_counter.sh - Minimal tmux variable monitoring demo
# ===================================================================
# DESCRIPTION:
#   Ultra-minimal example of variable monitoring using the new tmx_monitor_pane
#   function. Shows how to create a tmux session with three panes:
#     1. Monitor pane - Shows the value of all counters with auto-coloring
#     2. Green counter - Increments by 2 every second
#     3. Blue counter - Increments by 3 every 2 seconds
#
# USAGE:
#   ./tmux_micro_mon_counter.sh [--headless]
#   Options:
#     --headless    Create session without launching a terminal
#
#   For debugging scripts:
#     DEBUG=1 ./tmux_micro_mon_counter.sh
#
# NOTE: Uses tmux variables that are automatically cleaned up when session ends.
# ===================================================================

# === SETUP ===
# Source required utilities
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
COUNTER_VARS=("counter_green" "counter_blue" "counter_red")

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
    # Infinite loop to update counter
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

# Function for the red counter pane
red() {
    local session="$1"
    # Infinite loop to update counter
    while true; do
        local current_red=$(tmx_var_get "counter_red" "$session")
        local v=$((current_red + 5))
        tmx_var_set "counter_red" "$v" "$session"
        clear
        msg_bg_red "RED COUNTER"
        msg_red "Value: ${v}"
        sleep 3
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session with unique timestamp to avoid duplicates
    local session_name="micro_mon_$(date +%s)"
    
    # Explicitly declare the session variable before using it with nameref
    declare session_var=""
    
    # Create the session, show confirmation box, and initialize variables
    if ! tmx_create_session_with_vars session_var "${session_name}" "$HEADLESS" "COUNTER_VARS"; then
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi
    
    msg_info "Session created: ${session_var}"
    
    # Create panes for counters first
    msg_info "Creating counter panes..."
    p1=$(tmx_pane_function "${session_var}" green "v" "${session_var}")
    p2=$(tmx_pane_function "${session_var}" blue "h" "${session_var}")
    p3=$(tmx_pane_function "${session_var}" red "h" "${session_var}")
    
    # Create monitor pane in pane 0 (first pane) last
    # The monitor will auto-color variables based on their names
    msg_info "Creating monitor pane..."
    p0=$(tmx_monitor_pane "${session_var}" "counter_green counter_blue counter_red" "0" "1")
    
    # Keep parent process running
    echo "Running in: ${session_var} - Press Ctrl+C to exit"
    while true; do sleep 1; done
}

main 