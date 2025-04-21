#!/usr/bin/env bash
# tmux_simple_counter.sh - Simple counter demo showing variable sharing between tmux panes

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    sh-globals_init "$@"
fi

# Simple configuration
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
SHARED_DIR="/tmp/tmux_counters_${TIMESTAMP}"
MAX_COUNT=60                # Target count for all counters

# Different delays for each counter
DELAY_GREEN=1               # 1 second delay
DELAY_BLUE=2                # 2 second delay
DELAY_MAGENTA=3             # 3 second delay

# Make sure shared directory exists
mkdir -p "${SHARED_DIR}"

# Monitor function - displays values from all counters
monitor() {
    # Get session name from tmux
    SESSION_NAME=$(tmux display-message -p '#S')
    
    # Setup display
    clear
    echo "===== TMUX COUNTER MONITOR - SESSION: ${SESSION_NAME} ====="
    echo "Shows shared variables across tmux panes"
    echo "Each counter has different increment and delay values"
    echo ""
    
    # Initialize counter files
    echo "0" > "${SHARED_DIR}/counter1.val"
    echo "0" > "${SHARED_DIR}/counter2.val"
    echo "0" > "${SHARED_DIR}/counter3.val"
    
    # Start time
    START_TIME=$(date +%s)
    
    # Main monitoring loop - keep it very simple
    while true; do
        # Read current values directly from files
        C1=$(cat "${SHARED_DIR}/counter1.val" 2>/dev/null || echo "0")
        C2=$(cat "${SHARED_DIR}/counter2.val" 2>/dev/null || echo "0")
        C3=$(cat "${SHARED_DIR}/counter3.val" 2>/dev/null || echo "0")
        
        # Get elapsed time
        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))
        
        # Clear and show current values
        clear
        echo "===== TMUX COUNTER MONITOR - SESSION: ${SESSION_NAME} ====="
        echo "Time: ${ELAPSED}s"
        echo ""
        echo "GREEN COUNTER:   ${C1}  (+3 every ${DELAY_GREEN}s)"
        echo "BLUE COUNTER:    ${C2}  (+5 every ${DELAY_BLUE}s)"
        echo "MAGENTA COUNTER: ${C3}  (random +1-4 every ${DELAY_MAGENTA}s)"
        echo ""
        echo "TOTAL COUNT: $((C1 + C2 + C3))"
        echo "TARGET: Each counter reaches at least ${MAX_COUNT}"
        echo ""
        
        # Check if all counters have reached maximum
        if [[ "$C1" -ge "$MAX_COUNT" && "$C2" -ge "$MAX_COUNT" && "$C3" -ge "$MAX_COUNT" ]]; then
            echo "All counters complete!"
            break
        fi
        
        # Brief pause
        sleep 1
    done
    
    # Final message
    echo ""
    END_TIME=$(date +%s)
    TOTAL_TIME=$((END_TIME - START_TIME))
    echo "Demo completed in ${TOTAL_TIME} seconds"
    echo ""
    echo "Press Enter to close monitor pane..."
    read -r
}

# Green counter increments by 3 each time
counter_green() {
    # Get unique variables
    local counter_file="${SHARED_DIR}/counter1.val"
    local count=0
    
    # Get session name from tmux
    SESSION_NAME=$(tmux display-message -p '#S')
    PANE_ID=$(tmux display-message -p '#P')
    
    clear
    
    # Main loop
    while [[ $count -lt $MAX_COUNT ]]; do
        # Increment by 3
        count=$((count + 3))
        if [[ $count -gt $MAX_COUNT ]]; then
            count=$MAX_COUNT  # Cap at max
        fi
        
        # Display colorized output
        clear
        msg_bg_green "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
        echo ""
        echo "GREEN COUNTER: ${count}/${MAX_COUNT} (Delay: ${DELAY_GREEN}s)"
        echo ""
        echo "This counter increments by +3 each time"
        echo "Current value: ${count}"
        echo "File: ${counter_file}"
        echo ""
        
        # Write value to file for sharing
        echo "${count}" > "${counter_file}"
        sync  # Ensure file is written
        
        # Wait
        sleep $DELAY_GREEN
    done
    
    # Final message
    clear
    msg_bg_green "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
    echo "GREEN COUNTER: ${count}/${MAX_COUNT}"
    echo "COMPLETED"
    echo ""
    echo "Press Enter to close pane..."
    read -r
}

# Blue counter increments by 5 each time
counter_blue() {
    # Get unique variables
    local counter_file="${SHARED_DIR}/counter2.val"
    local count=0
    
    # Get session name from tmux
    SESSION_NAME=$(tmux display-message -p '#S')
    PANE_ID=$(tmux display-message -p '#P')
    
    clear
    
    # Main loop
    while [[ $count -lt $MAX_COUNT ]]; do
        # Increment by 5
        count=$((count + 5))
        if [[ $count -gt $MAX_COUNT ]]; then
            count=$MAX_COUNT  # Cap at max
        fi
        
        # Display colorized output
        clear
        msg_bg_blue "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
        echo ""
        echo "BLUE COUNTER: ${count}/${MAX_COUNT} (Delay: ${DELAY_BLUE}s)"
        echo ""
        echo "This counter increments by +5 each time"
        echo "Current value: ${count}"
        echo "File: ${counter_file}"
        echo ""
        
        # Write value to file for sharing
        echo "${count}" > "${counter_file}"
        sync  # Ensure file is written
        
        # Wait
        sleep $DELAY_BLUE
    done
    
    # Final message
    clear
    msg_bg_blue "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
    echo "BLUE COUNTER: ${count}/${MAX_COUNT}"
    echo "COMPLETED"
    echo ""
    echo "Press Enter to close pane..."
    read -r
}

# Magenta counter increments by a random value
counter_magenta() {
    # Get unique variables
    local counter_file="${SHARED_DIR}/counter3.val"
    local count=0
    
    # Get session name from tmux
    SESSION_NAME=$(tmux display-message -p '#S')
    PANE_ID=$(tmux display-message -p '#P')
    
    clear
    
    # Main loop
    while [[ $count -lt $MAX_COUNT ]]; do
        # Random increment between 1-4
        local inc=$((RANDOM % 4 + 1))
        count=$((count + inc))
        if [[ $count -gt $MAX_COUNT ]]; then
            count=$MAX_COUNT  # Cap at max
        fi
        
        # Display colorized output
        clear
        msg_bg_magenta "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
        echo ""
        echo "MAGENTA COUNTER: ${count}/${MAX_COUNT} (Delay: ${DELAY_MAGENTA}s)"
        echo ""
        echo "This counter increments randomly (1-4) each time"
        echo "Current value: ${count}"
        echo "Last increment: +${inc}"
        echo "File: ${counter_file}"
        echo ""
        
        # Write value to file for sharing
        echo "${count}" > "${counter_file}"
        sync  # Ensure file is written
        
        # Wait
        sleep $DELAY_MAGENTA
    done
    
    # Final message
    clear
    msg_bg_magenta "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
    echo "MAGENTA COUNTER: ${count}/${MAX_COUNT}"
    echo "COMPLETED"
    echo ""
    echo "Press Enter to close pane..."
    read -r
}

# Main function
main() {
    clear
    echo "Starting Simple Tmux Counter Demo"
    echo "Demonstrates variable sharing between tmux panes"
    echo ""
    echo "GREEN COUNTER: Increments by +3 every ${DELAY_GREEN}s"
    echo "BLUE COUNTER: Increments by +5 every ${DELAY_BLUE}s" 
    echo "MAGENTA COUNTER: Increments randomly +1-4 every ${DELAY_MAGENTA}s"
    echo ""
    
    # Create shared directory
    mkdir -p "${SHARED_DIR}"
    
    # Create a new tmux session
    local session_name
    session_name=$(create_tmux_session "counter_demo")
    if [[ -z "${session_name}" ]]; then
        echo "Failed to create tmux session. Exiting."
        exit 1
    fi
    echo "Created tmux session: ${session_name}"
    sleep 1
    
    # Start the monitor in the first pane
    echo "Starting monitor in pane 0"
    execute_shell_function "${session_name}" 0 monitor "SH_GLOBALS_LOADED SHARED_DIR MAX_COUNT DELAY_GREEN DELAY_BLUE DELAY_MAGENTA START_TIME"
    sleep 1
    
    # Start green counter (pane 1)
    echo "Starting green counter"
    local pane1
    pane1=$(create_new_pane "${session_name}" "v")
    execute_shell_function "${session_name}" "${pane1}" counter_green "SH_GLOBALS_LOADED SHARED_DIR MAX_COUNT DELAY_GREEN"
    
    # Start blue counter (pane 2)
    echo "Starting blue counter"
    local pane2
    pane2=$(create_new_pane "${session_name}")
    execute_shell_function "${session_name}" "${pane2}" counter_blue "SH_GLOBALS_LOADED SHARED_DIR MAX_COUNT DELAY_BLUE"
    
    # Start magenta counter (pane 3)
    echo "Starting magenta counter"
    local pane3
    pane3=$(create_new_pane "${session_name}")
    execute_shell_function "${session_name}" "${pane3}" counter_magenta "SH_GLOBALS_LOADED SHARED_DIR MAX_COUNT DELAY_MAGENTA"
    
    echo ""
    echo "Demo started in tmux session: ${session_name}"
    echo "Monitor will show all counter values in real-time"
    echo ""
    echo "Press Ctrl+C to end demonstration"
    
    # Keep script running until killed
    trap 'echo "Demonstration ended by user"; exit 0' INT
    while true; do
        sleep 1
    done
}

# Run main function
main 