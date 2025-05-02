#!/usr/bin/env bash
# tmux_embedded_scripts.sh - Examples of embedded scripts for tmux

# Source the tmux utilities
# shellcheck source=../tmux_utils1.sh
source "tmux_utils1.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    sh-globals_init "$@"
fi

# Create a temporary directory for shared files
SHARED_DIR="/tmp/tmux_embedded_demo_$$"
mkdir -p "${SHARED_DIR}"

# Cleanup function
cleanup() {
    rm -rf "${SHARED_DIR}"
}
trap cleanup EXIT

# Main function to demonstrate embedded scripts
main() {
    local session_name="embedded_demo_$$"
    
    # Create the tmux session with duplicate handling
    if ! create_session_with_duplicate_handling "${session_name}"; then
        msg_error "Failed to create tmux session"
        return 1
    fi
    
    # Get the actual session name (in case it was modified for uniqueness)
    session_name="${SESSION_NAME}"
    
    # Create additional panes for demos
    msg_info "Creating panes for demos..."
    create_new_pane "${session_name}" "v"  # Split vertically
    create_new_pane "${session_name}" "h"  # Split horizontally
    
    # Demo 1: Welcome Script
    msg_info "Running Welcome Script in pane 0..."
    execute_script "${session_name}" 0 "APP_NAME APP_VERSION" <<'EOF'
# Get session and pane info directly
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#P')

# Clear screen and display header
clear
msg_header "${APP_NAME} v${APP_VERSION}"
msg_bg_blue "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
msg_info "Welcome to the tmux session!"

# Show some basic information
echo "Current time: $(date)"
echo "Working directory: $(pwd)"
echo ""

# Display shared variables
echo "Variables shared from parent process:"
echo "- App: ${APP_NAME}"
echo "- Version: ${APP_VERSION}"
echo "- Session: ${SESSION_NAME}"
echo "- Pane: ${PANE_ID}"

msg_success "Script execution successful"
EOF

    # Demo 2: System Information
    msg_info "Running System Info Script in pane 1..."
    execute_script "${session_name}" 1 "SHARED_DIR" <<'EOF'
# Get session and pane info
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#P')

# Clear screen and display header
clear
msg_bg_green "SYSTEM INFORMATION - SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
echo "-----------------------------------"

# Create shared info directory if it doesn't exist
mkdir -p "${SHARED_DIR}"
SYSTEM_INFO_FILE="${SHARED_DIR}/system_info.txt"

# Write system information to shared file
{
    echo "System Information collected at $(date)"
    echo "-----------------------------------"
    echo "Kernel: $(uname -r)"
    echo "Hostname: $(hostname)"
    echo "CPU Info: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
    echo "Memory:"
    free -h | head -2
    echo ""
    echo "Disk usage:"
    df -h | grep -E '^/dev/' | sort
} > "${SYSTEM_INFO_FILE}"

# Display info and notify where it's stored
msg_info "System information collected:"
cat "${SYSTEM_INFO_FILE}"
echo ""
msg_success "Information saved to: ${SYSTEM_INFO_FILE}"
echo "Other tmux panes can access this information"
EOF

    # Demo 3: Interactive Counter
    msg_info "Running Interactive Counter in pane 2..."
    execute_script "${session_name}" 2 "SHARED_DIR" <<'EOF'
# Get session and pane info
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#P')

# Clear screen and display header
clear
msg_bg_yellow "SHARED COUNTER - SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
echo ""

# Create/access shared counter file
COUNTER_FILE="${SHARED_DIR}/counter.txt"
if [[ ! -f "${COUNTER_FILE}" ]]; then
    echo "0" > "${COUNTER_FILE}"
    chmod 666 "${COUNTER_FILE}"
fi

# Function to read current counter value
get_counter() {
    cat "${COUNTER_FILE}" 2>/dev/null || echo "0"
}

# Function to increment counter by specified amount
increment_counter() {
    local increment="${1:-1}"
    local current_value
    current_value=$(get_counter)
    local new_value=$((current_value + increment))
    echo "${new_value}" > "${COUNTER_FILE}"
    sync
    echo "${new_value}"
}

# Show initial value
echo "Initial counter value: $(get_counter)"
echo ""

# Increment a few times at random intervals
msg_info "Incrementing counter every second..."
for i in {1..5}; do
    # Sleep random time (0.5-2 seconds)
    sleep $(awk "BEGIN {print 0.5 + rand() * 1.5}")
    
    # Get current value then increment
    current=$(get_counter)
    increment=$((RANDOM % 5 + 1))
    new_value=$(increment_counter $increment)
    
    # Show what happened
    msg_green "Counter: ${current} -> ${new_value} (+${increment})"
done

echo ""
msg_success "Final counter value: $(get_counter)"
echo "Check other panes to see if they've updated the counter too!"
EOF

    # Wait for user to press a key
    msg_info "Demo is running in tmux session '${session_name}'"
    msg_success "Press Enter to clean up and exit..."
    read -r
    
    # Cleanup
    kill_tmux_session "${session_name}"
}

# Run the main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    export APP_NAME="Tmux Embedded Scripts Demo"
    export APP_VERSION="1.0.0"
    main "$@"
fi 