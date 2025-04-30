#!/usr/bin/env bash
# tmux_control_demo.sh - Tmux control pane demo
# Demonstrates monitor/management of multiple counter panes:
# - Control pane: Monitors variables and controls other panes
# - Green counter: +2 every 1s
# - Blue counter: +3 every 2s
# - Yellow counter: +5 every 3s
#
# USAGE: ./tmux_control_demo.sh [--headless]
#   --headless: Create session without terminal
#
# Controls: 1-3: close panes, q: quit, r: restart mode
#
# Uses stable pane IDs (%ID format) instead of indices
# shellcheck disable=SC1091,SC2317,SC2155,SC2034,SC2250,SC2162,SC2312
# === Initialize environment ===
set -o pipefail          # Better error handling for pipes
SCRIPT_DIR="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../")"

# Load utilities
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management

# Initialize messaging system
sh-globals_init "$@"

# Set debug mode
#export DEBUG="${DEBUG:-1}"

# === Process arguments ===
HEADLESS=''  # Default to empty string (launch terminal)
if [[ "$1" == "--headless" ]]; then
    HEADLESS="$1"  # Pass actual "--headless" parameter 
    msg_info "Running in headless mode"
fi

# === Counter pane functions ===
# Green counter: Increments by 2 every second
green() {
    local session="$1"
    while true; do
        local current_green=$(tmx_var_get "counter_green" "$session")
        local v=$((current_green + 2))
        tmx_var_set "counter_green" "$v" "$session"
        
        # Update display
        clear
        msg_bg_green "GREEN COUNTER (PANE 1)"
        msg_green "Value: ${v}"
        msg_green "Press '1' in control pane to close"
        
        sleep 1
    done
}

# Blue counter: Increments by 3 every 2 seconds
blue() {
    local session="$1"
    while true; do
        local current_blue=$(tmx_var_get "counter_blue" "$session")
        local v=$((current_blue + 3))
        tmx_var_set "counter_blue" "$v" "$session"
        
        # Update display
        clear
        msg_bg_blue "BLUE COUNTER (PANE 2)"
        msg_blue "Value: ${v}"
        msg_blue "Press '2' in control pane to close"
        
        sleep 2
    done
}

# Yellow counter: Increments by 5 every 3 seconds
yellow() {
    local session="$1"
    while true; do
        local current_yellow=$(tmx_var_get "counter_yellow" "$session")
        local v=$((current_yellow + 5))
        tmx_var_set "counter_yellow" "$v" "$session"
        
        # Update display
        clear
        msg_bg_yellow "YELLOW COUNTER (PANE 3)"
        msg_yellow "Value: ${v}"
        msg_yellow "Press '3' in control pane to close"
        
        sleep 3
    done
}

# === Shared variables ===
# Define which variables to initialize and track
COUNTER_VARS=("counter_green" "counter_blue" "counter_yellow")

# === Main function ===
main() {
    # Create unique session name with timestamp
    local session_name="control_demo_$(date +%s)"
    
    # Create session and initialize counter variables to 0
    msg_info "Creating tmux session: ${session_name}"
    if tmx_create_session_with_vars "${session_name}" COUNTER_VARS 0 "${HEADLESS}"; then
        msg_success "Session created: ${TMX_SESSION_NAME}"
    else
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi

    # Create panes and run counter functions in them with auto-registration
    msg_info "Creating counter panes..."
    local p1_id=$(tmx_create_pane_func "${TMX_SESSION_NAME}" "Green" green "v" "" "PANE" "${TMX_SESSION_NAME}")
    local p2_id=$(tmx_create_pane_func "${TMX_SESSION_NAME}" "Blue" blue "h" "" "PANE" "${TMX_SESSION_NAME}")
    local p3_id=$(tmx_create_pane_func "${TMX_SESSION_NAME}" "Yellow" yellow "h" "" "PANE" "${TMX_SESSION_NAME}")
    
    # Use pane 0 (the first pane) as the control pane using the simplified function
    local p0_id=$(tmx_create_monitoring_control "${TMX_SESSION_NAME}" COUNTER_VARS "PANE" "1" "0")
    
    # Ensure pane titles are visible - do this after all panes are created
    tmx_enable_pane_titles "${TMX_SESSION_NAME}"

    # Display comprehensive session information (auto-detects all panes)
    tmx_display_info "${TMX_SESSION_NAME}"
    
    # Monitor the session until it terminates using the modular function
    tmx_monitor_session "${TMX_SESSION_NAME}" 0.5
    
    return 0
}

# Run the main function and exit with its status
main
exit $? 