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
# NOTES:
#   - This script demonstrates the use of stable pane IDs (%ID format)
#     instead of indices which can change when panes are deleted
#   - The tmx_kill_pane_by_id function ensures proper pane targeting
#     regardless of other panes being added or removed
# ===================================================================

# === SETUP ===
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management

# Enable debug mode to help troubleshoot pane issues
# export DEBUG=1

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
    if ! tmx_create_session_with_vars "${session_name}" COUNTER_VARS 0 "${HEADLESS}"; then
        msg_error "Failed to create tmux session, exiting."
        return 1
    fi
    
    # The function now sets SESSION_NAME global variable, use that instead
    session_var="${SESSION_NAME}"
    
    msg_info "Session created: ${session_var}"
    
    # Create the worker panes first, now using pane IDs instead of indices
    msg_info "Creating counter panes..."
    local p1_id=$(tmx_pane_function "${session_var}" green "v" "" "${session_var}")
    local p2_id=$(tmx_pane_function "${session_var}" blue "h" "" "${session_var}")
    local p3_id=$(tmx_pane_function "${session_var}" yellow "h" "" "${session_var}")
    
    # For display purposes, get the numeric indices as well
    local p1_idx=$(tmux display-message -t "${p1_id}" -p "#{pane_index}")
    local p2_idx=$(tmux display-message -t "${p2_id}" -p "#{pane_index}")
    local p3_idx=$(tmux display-message -t "${p3_id}" -p "#{pane_index}")
    
    msg_debug "Created panes: #${p1_idx}(${p1_id}), #${p2_idx}(${p2_id}), #${p3_idx}(${p3_id})"
    
    # Store both IDs and indices for the control pane
    # Control pane still needs indices for keyboard input, but will use IDs for operations
    PANES_TO_CONTROL="${p1_idx} ${p2_idx} ${p3_idx}"
    PANE_IDS="${p1_id} ${p2_id} ${p3_id}"
    
    # Store the mapping in tmux variables for later use
    tmx_var_set "pane_id_1" "${p1_id}" "${session_var}"
    tmx_var_set "pane_id_2" "${p2_id}" "${session_var}"
    tmx_var_set "pane_id_3" "${p3_id}" "${session_var}"
    
    # Create the control pane last in pane 0
    msg_info "Creating control pane..."
    msg_debug "Control panes: ${PANES_TO_CONTROL} (IDs: ${PANE_IDS})"
    
    # Pass both control variables to the control pane
    local vars_to_export="SHELL ${session_var} PANE_IDS"
    # Explicitly use pane 0 for the control pane (last parameter)
    local p0_id=$(tmx_control_pane "${session_var}" "counter_green counter_blue counter_yellow pane_id_1 pane_id_2 pane_id_3" "${PANES_TO_CONTROL}" "1" "0")
    
    # Keep parent process running
    echo "Running in: ${session_var} - Press Ctrl+C to exit"
    echo "Pane IDs (stable identifiers):"
    echo "  Control: ${p0_id}"
    echo "  Green:   ${p1_id}" 
    echo "  Blue:    ${p2_id}"
    echo "  Yellow:  ${p3_id}"
    
    while true; do sleep 1; done
}

main 