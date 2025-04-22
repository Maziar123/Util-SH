#!/usr/bin/env bash
# ===================================================================
# tmux_headless_counter.sh - Headless tmux session demonstration
# ===================================================================
# DESCRIPTION:
#   Demonstrates creating a tmux session without launching a terminal.
#   Uses tmux environment variables for sharing data between panes.
#   Creates a "headless" tmux session useful for:
#     - Background processing
#     - Automated testing
#     - Scripted tmux operations
#
# USAGE:
#   ./tmux_headless_counter.sh
#
# NOTE: This creates a session but doesn't open a terminal automatically.
#       Use the displayed command to connect to the session.
# ===================================================================

# === SETUP ===
# Source required utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management
sh-globals_init "$@"

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session without launching terminal (false as second parameter)
    s=$(create_tmux_session "headless_$(date +%s)" false)
    
    # Initialize tmux environment variables
    tmux set-environment -t ${s} -g COUNTER 0
    
    # Set up a counter in the first pane
    execute_script "${s}" 0 <<EOF
# Infinite loop to update counter
while true; do
    # Get current value from tmux environment
    current=\$(tmux show-environment -g COUNTER | cut -d= -f2)
    
    # Increment value
    v=\$((current + 1))
    
    # Update tmux environment variable
    tmux set-environment -g COUNTER \${v}
    
    # Display value (will be visible when you attach)
    echo "Counter: \${v}"
    sleep 1
done
EOF
    
    # Display how to connect
    echo "========================================================"
    echo "Headless tmux session '${s}' created and running!"
    echo "To connect to this session, run:"
    msg_info "tmux attach-session -t ${s}"
    echo "========================================================"
    
    # Keep parent process running
    echo "Session will continue running in background."
    echo "Press Ctrl+C to exit (session will remain active)"
    while true; do 
        echo -n "."
        sleep 5
        # Show current counter value
        counter=$(tmux show-environment -t ${s} -g COUNTER 2>/dev/null | cut -d= -f2)
        echo -n " Current count: ${counter:-N/A} "
    done
}

# === RUN MAIN ===
main 