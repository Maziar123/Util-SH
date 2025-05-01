#!/usr/bin/env bash
# ===================================================================
# tmux_micro_counter.sh - Minimal tmux variable sharing demonstration
# ===================================================================
# Shows how to create a tmux session with three panes that share variables:
# 1. Monitor - Shows both counter values
# 2. Green counter - Increments by 2 every second
# 3. Blue counter - Increments by 3 every 2 seconds
#
# USAGE: ./tmux_micro_counter.sh [--headless]
# shellcheck disable=SC1091,SC2317,SC2155,SC2034,SC2250,SC2162,SC2312

# --- Setup ---
SCRIPT_DIR="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"    # Colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"   # Tmux utilities
sh-globals_init "$@"

# Process --headless argument
HEADLESS=''
[[ "$1" == "--headless" ]] && HEADLESS="$1" && msg_info "Running in headless mode"

# --- Shared variables ---
# Define which variables to initialize and track
COUNTER_VARS=("counter_green" "counter_blue")

# --- Pane Functions ---
# Monitor pane - displays both counters
monitor() {
    # Get session from parameter or fallback to tmux environment variable
    local session="$1"
    
    # If session is empty, try to get it from tmux environment
    if [[ -z "$session" ]]; then
        session=$(tmux show-environment -g TMX_SESSION_NAME 2>/dev/null | cut -d= -f2)
        echo "Retrieved session from env: $session"
    fi
    
    # If still empty, use current tmux session
    if [[ -z "$session" ]]; then
        session=$(tmux display-message -p "#{session_name}" 2>/dev/null)
        echo "Using current session: $session"
    fi
    
    echo "Starting monitor with session: $session"
    sleep 1 # Allow environment to settle
    
    while true; do
        clear
        echo "=== MONITOR === (Session: $session)"
        # Try multiple methods to get variables
        local green_val=$(tmx_var_get "counter_green" "$session" 2>/dev/null || echo "N/A")
        local blue_val=$(tmx_var_get "counter_blue" "$session" 2>/dev/null || echo "N/A")
        
        echo "GREEN: ${green_val}"
        echo "BLUE: ${blue_val}"
        sleep 1
    done
}

# Green counter - increments by 2 every second
green() {
    local session="$1"
    sleep 1 # Allow environment to settle
    
    while true; do
        local current_green=$(tmx_var_get "counter_green" "$session")
        local v=$((current_green + 2))
        tmx_var_set "counter_green" "$v" "$session"
        
        # Update display
        clear
        msg_bg_green "GREEN COUNTER"
        msg_green "Value: ${v}"
        sleep 1
    done
}

# Blue counter - increments by 3 every 2 seconds
blue() {
    local session="$1"
    sleep 1 # Allow environment to settle
    
    while true; do
        local current_blue=$(tmx_var_get "counter_blue" "$session")
        local v=$((current_blue + 3))
        tmx_var_set "counter_blue" "$v" "$session"
        
        # Update display
        clear
        msg_bg_blue "BLUE COUNTER"
        msg_blue "Value: ${v}"
        sleep 2
    done
}

# --- Main Function ---
main() {
    # Create unique session name with timestamp
    local session_name="micro_$(date +%s)"
    msg_info "Creating tmux session: ${session_name}"
    
    # Create session and initialize counter variables to 0
    if tmx_create_session_with_vars "${session_name}" COUNTER_VARS 0 "${HEADLESS}"; then
        msg_success "Session created: ${TMX_SESSION_NAME}"
    else
        msg_error "Failed to create tmux session"
        return 1
    fi
    
    # Verify variables were initialized
    local green_test=$(tmx_var_get "counter_green" "${TMX_SESSION_NAME}")
    local blue_test=$(tmx_var_get "counter_blue" "${TMX_SESSION_NAME}")
    msg_debug "Initial values - Green: ${green_test}, Blue: ${blue_test}"
    
    # Create panes and run counter functions in them
    msg_info "Creating counter panes..."
    # Set global variable for TMX_SESSION_NAME in all panes
    tmx_var_set "TMX_SESSION_NAME" "${TMX_SESSION_NAME}" "${TMX_SESSION_NAME}"
    # Use session name explicitly
    tmx_first_pane_function "${TMX_SESSION_NAME}" monitor "${TMX_SESSION_NAME}"
    local p1_id=$(tmx_create_pane_func "${TMX_SESSION_NAME}" "Green" green "v" "" "PANE" "${TMX_SESSION_NAME}")
    local p2_id=$(tmx_create_pane_func "${TMX_SESSION_NAME}" "Blue" blue "h" "" "PANE" "${TMX_SESSION_NAME}")
    
    # Enable titles and monitor until terminated
    tmx_enable_pane_titles "${TMX_SESSION_NAME}"
    tmx_monitor_session "${TMX_SESSION_NAME}" 0.5
    
    return 0
}

# Run main
main
exit $?