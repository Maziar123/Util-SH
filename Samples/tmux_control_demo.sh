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
export DEBUG="${DEBUG:-1}"

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
    if ! tmx_create_session_with_vars "${session_name}" COUNTER_VARS 0 "${HEADLESS}"; then
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi
    
    # Get the actual session name (may be different if duplicate handling occurred)
    local session_var="${SESSION_NAME}"
    msg_success "Session created: ${session_var}"
    
    # === Create worker panes ===
    msg_info "Creating counter panes..."
    
    # Create panes and run counter functions in them
    # Each returns the stable pane ID in %ID format
    local p1_id=$(tmx_pane_function "${session_var}" green "v" "" "${session_var}")
    local p2_id=$(tmx_pane_function "${session_var}" blue "h" "" "${session_var}")
    
    local p3_id=$(tmx_pane_function "${session_var}" yellow "h" "" "${session_var}")
    
    # === Get information about all panes in the session ===
    # This populates PANE_COUNT, PANE_IDS, PANE_INDICES, PANE_ID_1, etc.
    tmx_list_session_panes "${session_var}" "PANE"
    
    # Use direct pane IDs that we know are correct
    PANE_ID_1="${p1_id}"
    PANE_ID_2="${p2_id}"
    PANE_ID_3="${p3_id}"
    msg_debug "Direct pane IDs: Green=${p1_id}, Blue=${p2_id}, Yellow=${p3_id}"
    
    # Use pane indices for control functions (needed for keyboard input)
    PANES_TO_CONTROL="1 2 3"  # Use explicit indices to match the counter panes
    
    # === Create the control pane ===
    msg_info "Creating control pane..."
    msg_debug "Control panes: ${PANES_TO_CONTROL} (IDs: ${PANE_IDS})"
    
    # Use pane 0 (the first pane) as the control pane using the new simplified function
    local p0_id=$(tmx_create_monitoring_control "${session_var}" COUNTER_VARS "PANE" "1" "0")
    
    # === Display session information using the modular function ===
    # Format pane data with labels
    local pane_data="${p1_id}:Green ${p2_id}:Blue ${p3_id}:Yellow"
    tmx_display_session_info "${session_var}" "${p0_id}" "${pane_data}" 60
    
    # === Monitor the session until it terminates using the modular function ===
    tmx_monitor_session "${session_var}" 0.5
    
    return 0
}

# Run the main function and exit with its status
main
exit $? 