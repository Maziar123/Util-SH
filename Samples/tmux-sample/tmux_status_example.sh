#!/usr/bin/env bash
# ===================================================================
# tmux_status_example.sh - Demonstrating status bar pane
# ===================================================================
# DESCRIPTION:
#   This example shows how to use the status bar pane functionality to
#   display a compact status of variables:
#     1. Status bar pane - Shows all counter values in compact format
#     2. Green counter - Increments by 2 every second 
#     3. Blue counter - Increments by 3 every 2 seconds
#
# USAGE:
#   ./tmux_status_example.sh [--headless]
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

# Function to update session time
time_updater() {
    local session="$1"
    local start_time=$(date +%s)
    
    # Debug output to confirm we have the correct session parameter
    echo "Time updater started for session: ${session}"
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # Explicitly use session parameter to set variable
        if ! tmx_var_set "session_time" "${elapsed}s" "${session}"; then
            echo "Failed to set session_time in session ${session}"
        fi
        
        # Display updated time in the pane for debugging
        clear
        echo "SESSION TIME UPDATER"
        echo "Session: ${session}"
        echo "Elapsed: ${elapsed}s"
        
        sleep 1
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session with unique timestamp
    local session_name="status_demo_$(date +%s)"
    declare session_var=""
    
    # Create the session and initialize variables
    if ! tmx_create_session_with_vars session_var "${session_name}" "$HEADLESS" "COUNTER_VARS"; then
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi
    
    msg_info "Session created: ${session_var}"
    
    # Create the status bar pane in pane 0
    msg_info "Creating status bar pane..."
    p0=$(tmx_status_pane "${session_var}" "counter_green counter_blue session_time" "0" "1")
    
    # Create worker panes
    msg_info "Creating counter panes..."
    p1=$(tmx_pane_function "${session_var}" green "v" "${session_var}")
    p2=$(tmx_pane_function "${session_var}" blue "h" "${session_var}")
    
    # Start time updater in a separate pane
    p3=$(tmx_pane_function "${session_var}" time_updater "h" "${session_var}")
    
    # Make time updater pane small
    tmux resize-pane -t "${session_var}:0.${p3}" -y 3
    
    # Keep parent process running
    echo "Running in: ${session_var} - Press Ctrl+C to exit"
    while true; do sleep 1; done
}

main 