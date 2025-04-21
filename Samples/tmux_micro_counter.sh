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
#   ./tmux_micro_counter.sh
#
# NOTE: Creates temporary files that are cleaned up on exit (Ctrl+C).
# ===================================================================

# === SETUP ===
# Source required utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management
sh-globals_init "$@"

# === SHARED VARIABLES ===
# Create separate files to hold counter values
# Using $$ (PID) to make filenames unique
COUNT_GREEN="/tmp/counter_green_$$.txt"
COUNT_BLUE="/tmp/counter_blue_$$.txt"
echo "0" > "${COUNT_GREEN}"  # Initialize to zero
echo "0" > "${COUNT_BLUE}"   # Initialize to zero

# === PANE FUNCTIONS ===
# Function for the monitor pane - displays both counters
monitor() {
    # Infinite loop to continuously update display
    while true; do
        clear
        echo "=== MONITOR ==="
        echo "GREEN: $(cat ${COUNT_GREEN})"  # Read green counter
        echo "BLUE: $(cat ${COUNT_BLUE})"    # Read blue counter
        sleep 1  # Update every second
    done
}

# Function for the green counter pane
green() {
    # Infinite loop to update counter
    while true; do
        v=$(($(cat ${COUNT_GREEN}) + 2))  # Read current value and add 2
        echo ${v} > ${COUNT_GREEN}        # Write back to file for sharing
        clear
        msg_bg_green "GREEN: ${v}"        # Display with green background
        sleep 1                           # Wait 1 second
    done
}

# Function for the blue counter pane
blue() {
    # Infinite loop to update counter
    while true; do
        v=$(($(cat ${COUNT_BLUE}) + 3))  # Read current value and add 3
        echo ${v} > ${COUNT_BLUE}        # Write back to file for sharing
        clear
        msg_bg_blue "BLUE: ${v}"         # Display with blue background
        sleep 2                          # Wait 2 seconds
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session with unique timestamp to avoid duplicates
    s=$(create_tmux_session "micro_$(date +%s)")
    
    # Start monitor in pane 0 (first pane)
    execute_shell_function "${s}" 0 monitor "COUNT_GREEN COUNT_BLUE"
    
    # Create pane 1 with vertical split and run green counter
    p1=$(create_new_pane "${s}" "v")
    execute_shell_function "${s}" "${p1}" green "COUNT_GREEN"
    
    # Create pane 2 with horizontal split and run blue counter
    p2=$(create_new_pane "${s}")
    execute_shell_function "${s}" "${p2}" blue "COUNT_BLUE"
    
    # Set up cleanup on exit
    trap 'rm -f "${COUNT_GREEN}" "${COUNT_BLUE}"; exit 0' INT
    
    # Keep parent process running
    echo "Running in: ${s} - Press Ctrl+C to exit"
    while true; do sleep 1; done
}

# === RUN MAIN ===
main 