#!/usr/bin/env bash
# ===================================================================
# tmux_micro_var_counter.sh - Minimal tmux variable sharing demonstration
# ===================================================================
# DESCRIPTION:
#   Ultra-minimal example of variable sharing between tmux panes using
#   tmux variables instead of files. Shows how to create a tmux session
#   with three panes:
#     1. Monitor pane - Shows the value of both counters
#     2. Green counter - Increments by 2 every second
#     3. Blue counter - Increments by 3 every 2 seconds
#
# USAGE:
#   ./tmux_micro_var_counter.sh [--headless]
#   Options:
#     --headless    Create session without launching a terminal
#
# NOTE: Uses tmux variables that are automatically cleaned up when session ends.
# ===================================================================

# === SETUP ===
# Source required utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management
sh-globals_init "$@"

# Parse command line arguments
HEADLESS=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --headless)
            HEADLESS=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# === SHARED VARIABLES ===
# Initialize tmux variables for counters
init_tmux_vars() {
    local session="$1"
    tmux set-environment -t "$session" "counter_green" "0"
    tmux set-environment -t "$session" "counter_blue" "0"
}

# === PANE FUNCTIONS ===
# Function for the monitor pane - displays both counters
monitor() {
    local session="$1"
    # Infinite loop to continuously update display
    while true; do
        clear
        echo "=== MONITOR ==="
        echo "GREEN: $(tmux show-environment -t "$session" counter_green | cut -d= -f2)"
        echo "BLUE: $(tmux show-environment -t "$session" counter_blue | cut -d= -f2)"
        sleep 1  # Update every second
    done
}

# Function for the green counter pane
green() {
    local session="$1"
    # Infinite loop to update counter
    while true; do
        local v=$(($(tmux show-environment -t "$session" counter_green | cut -d= -f2) + 2))
        tmux set-environment -t "$session" "counter_green" "$v"
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
        local v=$(($(tmux show-environment -t "$session" counter_blue | cut -d= -f2) + 3))
        tmux set-environment -t "$session" "counter_blue" "$v"
        clear
        msg_bg_blue "BLUE: ${v}"
        sleep 2
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session with unique timestamp to avoid duplicates
    local session_name="micro_var_$(date +%s)"
    s=$(create_tmux_session "${session_name}" "$([ "$HEADLESS" = "false" ] && echo true || echo false)")
    
    # Initialize tmux variables
    init_tmux_vars "$s"
    
    # If we're in headless mode, show connection instructions
    if [[ "$HEADLESS" == "true" ]]; then
        echo "========================================================"
        echo "Headless tmux session '${s}' created and running!"
        echo "To connect to this session, run:"
        msg_info "tmux attach-session -t ${s}"
        echo "========================================================"
    fi
    
    # Start monitor in pane 0 (first pane)
    execute_shell_function "${s}" 0 monitor "$s"
    
    # Create pane 1 with vertical split and run green counter
    p1=$(create_new_pane "${s}" "v")
    execute_shell_function "${s}" "${p1}" green "$s"
    
    # Create pane 2 with horizontal split and run blue counter
    p2=$(create_new_pane "${s}")
    execute_shell_function "${s}" "${p2}" blue "$s"
    
    # Keep parent process running
    echo "Running in: ${s} - Press Ctrl+C to exit"
    while true; do sleep 1; done
}

# Show usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --headless    Create session without launching a terminal"
}

# === RUN MAIN ===
main 