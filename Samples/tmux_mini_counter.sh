#!/usr/bin/env bash
# tmux_mini_counter.sh - Minimal demonstration of variable sharing between tmux panes

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    sh-globals_init "$@"
fi

# Very simple configuration
TIMESTAMP=$(date "+%s")
SHARED_FILE="/tmp/tmux_mini_count_${TIMESTAMP}.txt"
MAX_COUNT=30               # Run for ~1 minute
DELAY_GREEN=1              # 1 second delay
DELAY_BLUE=3               # 3 second delay

# Create the shared file with initial counter value
echo "0" > "${SHARED_FILE}"

# Monitor function - displays the counter value
monitor() {
    # Get session info
    SESSION_NAME=$(tmux display-message -p '#S')
    
    # Setup display
    clear
    echo "===== MINI COUNTER MONITOR ====="
    echo "SESSION: ${SESSION_NAME}"
    echo "Shared file: ${SHARED_FILE}"
    echo ""
    
    # Start time
    START_TIME=$(date +%s)
    
    # Main monitoring loop
    while true; do
        # Read counter value
        COUNT=$(cat "${SHARED_FILE}" 2>/dev/null || echo "0")
        
        # Get elapsed time
        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))
        
        # Display
        clear
        echo "===== MINI COUNTER MONITOR ====="
        echo "SESSION: ${SESSION_NAME} - Time: ${ELAPSED}s"
        echo ""
        echo "COUNTER VALUE: ${COUNT}"
        echo "TARGET: ${MAX_COUNT}"
        echo ""
        
        # Show which color is incrementing by how much
        echo "GREEN: +3 every ${DELAY_GREEN}s"
        echo "BLUE:  +5 every ${DELAY_BLUE}s"
        echo ""
        
        # Check if we've reached maximum
        if [[ "${COUNT}" -ge "${MAX_COUNT}" ]]; then
            echo "Counter has reached maximum!"
            break
        fi
        
        # Brief pause
        sleep 1
    done
    
    # Final message
    END_TIME=$(date +%s)
    TOTAL_TIME=$((END_TIME - START_TIME))
    echo ""
    echo "Demo completed in ${TOTAL_TIME} seconds"
    
    # Clean up the shared file
    rm -f "${SHARED_FILE}"
}

# Green counter - increments by 3
counter_green() {
    # Get session info
    SESSION_NAME=$(tmux display-message -p '#S')
    PANE_ID=$(tmux display-message -p '#P')
    
    clear
    msg_bg_green "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
    echo "GREEN COUNTER - Increments by +3"
    echo ""
    
    while true; do
        # Read current value
        local current=$(cat "${SHARED_FILE}" 2>/dev/null || echo "0")
        
        # Display value
        clear
        msg_bg_green "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
        echo "GREEN COUNTER - Increments by +3"
        echo ""
        echo "Current value: ${current}"
        
        # Increment by 3
        local new_value=$((current + 3))
        if [[ "${new_value}" -gt "${MAX_COUNT}" ]]; then
            new_value="${MAX_COUNT}"
        fi
        
        # Update the counter file
        echo "${new_value}" > "${SHARED_FILE}"
        
        # Exit if we hit the max
        if [[ "${new_value}" -ge "${MAX_COUNT}" ]]; then
            break
        fi
        
        # Wait before next update
        sleep "${DELAY_GREEN}"
    done
    
    # Final message
    clear
    msg_bg_green "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
    echo "GREEN COUNTER COMPLETE!"
    echo "Final value: $(cat "${SHARED_FILE}")"
}

# Blue counter - increments by 5
counter_blue() {
    # Get session info
    SESSION_NAME=$(tmux display-message -p '#S')
    PANE_ID=$(tmux display-message -p '#P')
    
    clear
    msg_bg_blue "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
    echo "BLUE COUNTER - Increments by +5"
    echo ""
    
    while true; do
        # Read current value
        local current=$(cat "${SHARED_FILE}" 2>/dev/null || echo "0")
        
        # Display value
        clear
        msg_bg_blue "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
        echo "BLUE COUNTER - Increments by +5"
        echo ""
        echo "Current value: ${current}"
        
        # Increment by 5
        local new_value=$((current + 5))
        if [[ "${new_value}" -gt "${MAX_COUNT}" ]]; then
            new_value="${MAX_COUNT}"
        fi
        
        # Update the counter file
        echo "${new_value}" > "${SHARED_FILE}"
        
        # Exit if we hit the max
        if [[ "${new_value}" -ge "${MAX_COUNT}" ]]; then
            break
        fi
        
        # Wait before next update
        sleep "${DELAY_BLUE}"
    done
    
    # Final message
    clear
    msg_bg_blue "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
    echo "BLUE COUNTER COMPLETE!"
    echo "Final value: $(cat "${SHARED_FILE}")"
}

# Main function
main() {
    clear
    echo "Starting Minimal Tmux Counter Demo"
    echo "Demonstrates variable sharing between two panes"
    echo ""
    
    # Create a new tmux session
    local session_name
    session_name=$(create_tmux_session "mini_counter")
    if [[ -z "${session_name}" ]]; then
        echo "Failed to create tmux session. Exiting."
        exit 1
    fi
    echo "Created tmux session: ${session_name}"
    sleep 1
    
    # Start the monitor in the first pane
    echo "Starting monitor in pane 0"
    execute_shell_function "${session_name}" 0 monitor "SH_GLOBALS_LOADED SHARED_FILE MAX_COUNT DELAY_GREEN DELAY_BLUE"
    sleep 1
    
    # Start green counter (pane 1)
    echo "Starting green counter"
    local pane1
    pane1=$(create_new_pane "${session_name}" "v")
    execute_shell_function "${session_name}" "${pane1}" counter_green "SH_GLOBALS_LOADED SHARED_FILE MAX_COUNT DELAY_GREEN"
    
    # Start blue counter (pane 2)
    echo "Starting blue counter"
    local pane2
    pane2=$(create_new_pane "${session_name}")
    execute_shell_function "${session_name}" "${pane2}" counter_blue "SH_GLOBALS_LOADED SHARED_FILE MAX_COUNT DELAY_BLUE"
    
    echo ""
    echo "Demo started in tmux session: ${session_name}"
    echo "Monitor will show counter values in real-time"
    echo ""
    echo "Press Ctrl+C to end demonstration"
    
    # Keep script running until killed
    trap 'echo -e "\nDemonstration ended by user"; exit 0' INT
    while true; do
        sleep 1
    done
}

# Run main function
main 