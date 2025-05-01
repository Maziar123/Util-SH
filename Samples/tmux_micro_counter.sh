#!/usr/bin/env bash
# ===================================================================
# tmux_micro_counter.sh - Minimal tmux variable sharing demonstration
# ===================================================================
# DESCRIPTION:
#   Ultra-minimal example of variable sharing between tmux panes.
#   Shows how to create a tmux session with three panes:
#     1. Monitor pane - Shows the value of both counters
#     2. Green counter - Increments by 2 every second
#     3. Blue counter - Increments by 3 every 2 seconds
#
# USAGE:
#   ./tmux_micro_counter.sh [--headless]
#   Options:
#     --headless    Create session without launching a terminal
#
# NOTE: Uses tmux variables for sharing values between panes.
# ===================================================================
# shellcheck disable=SC1091,SC2317,SC2155,SC2034,SC2250,SC2162,SC2312
# === SETUP ===
# Source required utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management

# Initialize messaging system
sh-globals_init "$@"

# === Process arguments ===
HEADLESS=''  # Default to empty string (launch terminal)
if [[ "$1" == "--headless" ]]; then
    HEADLESS="$1"  # Pass actual "--headless" parameter 
    msg_info "Running in headless mode"
fi

# === Counter variables ===
# Define which variables to initialize and track
COUNTER_VARS=("counter_green" "counter_blue")

# === PANE FUNCTIONS ===
# Function for the monitor pane - displays both counters
monitor() {
    local session="$1"
    
    # Infinite loop to continuously update display
    while true; do
        clear
        echo "=== MONITOR ==="
        echo "GREEN: $(tmx_var_get "counter_green" "$session")"
        echo "BLUE: $(tmx_var_get "counter_blue" "$session")"
        sleep 1  # Update every second
    done
}

# Function for the green counter pane
green() {
    local session="$1"
    
    # Infinite loop to update counter
    while true; do
        local current=$(tmx_var_get "counter_green" "$session")
        local v=$((current + 2))
        tmx_var_set "counter_green" "$v" "$session"
        
        clear
        msg_bg_green "GREEN: ${v}"
        sleep 1
    done
}

# Function for the blue counter pane
blue() {
    local session="$1"
    
    # Infinite loop to update counter
    while true; do
        local current=$(tmx_var_get "counter_blue" "$session")
        local v=$((current + 3))
        tmx_var_set "counter_blue" "$v" "$session"
        
        clear
        msg_bg_blue "BLUE: ${v}"
        sleep 2
    done
}

# === MAIN FUNCTION ===
main() {
    # Create unique session name with timestamp
    local session_name="micro_$(date +%s)"
    
    # Create session and initialize counter variables to 0
    msg_info "Creating tmux session: ${session_name}"
    if tmx_create_session_with_vars "${session_name}" COUNTER_VARS 0 "${HEADLESS}"; then
        msg_success "Session created: ${TMX_SESSION_NAME}"
    else
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi
    
    # Create panes and run counter functions in them
    msg_info "Creating counter panes..."
    
    # Start monitor in pane 0 (first pane)
    tmx_first_pane_function "${TMX_SESSION_NAME}" monitor "${TMX_SESSION_NAME}"
    
    # Create panes using tmx_create_pane_func with proper labels
    local p1_id=$(tmx_create_pane_func "${TMX_SESSION_NAME}" "Green" green "v" "" "PANE" "${TMX_SESSION_NAME}")
    local p2_id=$(tmx_create_pane_func "${TMX_SESSION_NAME}" "Blue" blue "h" "" "PANE" "${TMX_SESSION_NAME}")
    
    # Enable pane titles for better visibility
    tmx_enable_pane_titles "${TMX_SESSION_NAME}"
    
    # Monitor the session until it terminates
    tmx_monitor_session "${TMX_SESSION_NAME}" 0.5
    
    return 0
}

# Run the main function and exit with its status
main
exit $? 