#!/usr/bin/env bash
# ===================================================================
# tmux_tmux_var_counter.sh - Minimal tmux variable sharing demonstration
# ===================================================================
# DESCRIPTION:
#   Ultra-minimal example of variable sharing between tmux panes
#   using tmux's built-in environment variables.
#   Shows how to create a tmux session with three panes:
#     1. Monitor pane - Shows the value of both counters
#     2. Green counter - Increments by 2 every second
#     3. Blue counter - Increments by 3 every 2 seconds
#
# USAGE:
#   ./tmux_tmux_var_counter.sh
#
# NOTE: Uses tmux environment variables for sharing data between panes.
# ===================================================================

# === SETUP ===
# Source required utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management
sh-globals_init "$@"

# === PANE FUNCTIONS ===
# Function for the monitor pane - displays both counters
monitor() {
    # Initialize variables if not set
    tmx_var_set COUNT_GREEN 0
    tmx_var_set COUNT_BLUE 0
    
    # Infinite loop to continuously update display
    while true; do
        clear
        echo "=== MONITOR ==="
        
        # Read green counter from tmux environment
        green_value=$(tmx_var_get COUNT_GREEN)
        echo "GREEN: ${green_value}"
        
        # Read blue counter from tmux environment
        blue_value=$(tmx_var_get COUNT_BLUE)
        echo "BLUE: ${blue_value}"
        
        sleep 1  # Update every second
    done
}

# Function for the green counter pane
green() {
    # Infinite loop to update counter
    while true; do
        # Get current value from tmux environment
        current=$(tmx_var_get COUNT_GREEN)
        
        # Increment by 2
        v=$((current + 2))
        
        # Update tmux environment variable
        tmx_var_set COUNT_GREEN ${v}
        
        clear
        msg_bg_green "GREEN: ${v}"  # Display with green background
        sleep 1                     # Wait 1 second
    done
}

# Function for the blue counter pane
blue() {
    # Infinite loop to update counter
    while true; do
        # Get current value from tmux environment
        current=$(tmx_var_get COUNT_BLUE)
        
        # Increment by 3
        v=$((current + 3))
        
        # Update tmux environment variable
        tmx_var_set COUNT_BLUE ${v}
        
        clear
        msg_bg_blue "BLUE: ${v}"  # Display with blue background
        sleep 2                   # Wait 2 seconds
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session with unique timestamp to avoid duplicates
    s=$(tmx_create_session "tmux_var_$(date +%s)")
    
    # Initialize tmux environment variables
    tmx_var_set COUNT_GREEN 0
    tmx_var_set COUNT_BLUE 0
    
    # Start monitor in pane 0 (first pane)
    p0=$(tmx_pane_function "${s}" monitor "0" "")
    
    # Create pane 1 with vertical split and run green counter
    p1=$(tmx_pane_function "${s}" green "v" "")
    
    # Create pane 2 with horizontal split and run blue counter
    p2=$(tmx_pane_function "${s}" blue "h" "")
    
    # Keep parent process running
    echo "Running in: ${s} - Press Ctrl+C to exit"
    while true; do sleep 1; done
}

# === RUN MAIN ===
main 