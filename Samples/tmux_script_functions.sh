#!/usr/bin/env bash
# tmux_script_functions.sh - Library of tmux script functions

# Source the tmux utilities
# shellcheck source=../tmux_utils1.sh
source "tmux_utils1.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    sh-globals_init "$@"
fi

# Create a temporary directory for shared files
SHARED_DIR="/tmp/tmux_script_demo_$$"
mkdir -p "${SHARED_DIR}"

# Cleanup function
cleanup() {
    rm -rf "${SHARED_DIR}"
}
trap cleanup EXIT

# === SCRIPT FUNCTIONS ===

# Welcome script for the first pane
welcome_script() {
    cat <<EOF
# Welcome script from function
msg_header "\${APP_NAME} v\${APP_VERSION}"
msg_bg_blue "Welcome to \${SESSION_NAME}!"
msg_info "This is the main pane (0)"

# Display system information
echo "Host: \$(hostname)"
echo "User: \$(whoami)"
echo "Date: \$(date)"

msg_yellow "Wait 3 seconds for next pane creation..."
EOF
}

# Info script for system information display
info_script() {
    cat <<EOF
msg_bg_green "System Information"
echo "-----------------------------------"
msg_info "System Details:"
echo "Current directory: \$(pwd)"
echo "TMUX Session: \$(tmux display-message -p '#S')"
echo "TMUX Pane: \$(tmux display-message -p '#P')"

# Write system information to shared file
{
    echo "System Information collected at \$(date)"
    echo "-----------------------------------"
    echo "Kernel: \$(uname -r)"
    echo "Hostname: \$(hostname)"
    echo "CPU Info: \$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
    echo "Memory:"
    free -h | head -2
    echo ""
    echo "Disk usage:"
    df -h | grep -E '^/dev/' | sort
} > "\${SHARED_DIR}/system_info.txt"

msg_success "System info saved to: \${SHARED_DIR}/system_info.txt"
EOF
}

# Process monitor script with embedded functionality
process_monitor_script() {
    cat <<EOF
msg_bg_yellow "Process Monitor"
msg_info "This pane will monitor system processes"

# Set up monitoring loop
watch_process="\${WATCH_PROCESS:-bash}"
msg_info "Monitoring processes matching: \$watch_process"
echo "Press Ctrl+C to stop monitoring"

# Create status file
echo "STATUS=RUNNING" > "\${SHARED_DIR}/monitor_status.txt"
echo "START_TIME=\$(date +%s)" >> "\${SHARED_DIR}/monitor_status.txt"

while true; do
    echo "----------------------------------------"
    echo "Current processes:"
    ps aux | grep "\$watch_process" | grep -v grep
    
    # Update status
    echo "LAST_UPDATE=\$(date +%s)" >> "\${SHARED_DIR}/monitor_status.txt"
    echo "PROCESS_COUNT=\$(ps aux | grep "\$watch_process" | grep -v grep | wc -l)" >> "\${SHARED_DIR}/monitor_status.txt"
    
    sleep 3
done
EOF
}

# File monitor script with embedded functionality
file_monitor_script() {
    cat <<EOF
msg_bg_cyan "File Monitor"
msg_info "This pane will monitor file changes"

# Set up monitoring loop
watch_dir="\${SHARED_DIR}"
msg_info "Monitoring directory: \$watch_dir"
echo "Press Ctrl+C to stop monitoring"

# Create status file
echo "STATUS=RUNNING" > "\${SHARED_DIR}/file_monitor_status.txt"
echo "START_TIME=\$(date +%s)" >> "\${SHARED_DIR}/file_monitor_status.txt"

while true; do
    echo "----------------------------------------"
    echo "Last modified files (last 5):"
    find "\$watch_dir" -type f -printf "%TY-%Tm-%Td %TH:%TM:%TS %p\n" | sort -r | head -5
    
    # Update status
    echo "LAST_UPDATE=\$(date +%s)" >> "\${SHARED_DIR}/file_monitor_status.txt"
    echo "FILE_COUNT=\$(find "\$watch_dir" -type f | wc -l)" >> "\${SHARED_DIR}/file_monitor_status.txt"
    
    sleep 5
done
EOF
}

# Status monitor script that shows all monitoring results
status_monitor_script() {
    cat <<EOF
msg_header "Status Monitor"
msg_info "Monitoring all pane activities"

while true; do
    clear
    echo "=== STATUS MONITOR ==="
    echo "Time: \$(date)"
    echo ""
    
    # Show system info summary
    if [[ -f "\${SHARED_DIR}/system_info.txt" ]]; then
        msg_bg_green "System Information Summary"
        head -n 3 "\${SHARED_DIR}/system_info.txt"
        echo "..."
    fi
    
    # Show process monitor status
    if [[ -f "\${SHARED_DIR}/monitor_status.txt" ]]; then
        echo ""
        msg_bg_yellow "Process Monitor Status"
        cat "\${SHARED_DIR}/monitor_status.txt"
    fi
    
    # Show file monitor status
    if [[ -f "\${SHARED_DIR}/file_monitor_status.txt" ]]; then
        echo ""
        msg_bg_cyan "File Monitor Status"
        cat "\${SHARED_DIR}/file_monitor_status.txt"
    fi
    
    sleep 2
done
EOF
}

# === MAIN FUNCTION ===
main() {
    local session_name="script_functions_demo_$$"
    
    # Create the tmux session with duplicate handling
    if ! create_session_with_duplicate_handling "${session_name}"; then
        msg_error "Failed to create tmux session"
        return 1
    fi
    
    # Get the actual session name (in case it was modified for uniqueness)
    session_name="${SESSION_NAME}"
    
    # Create additional panes for demos
    msg_info "Creating panes for demos..."
    
    # Demo 1: Welcome Script using execute_function
    msg_info "Running Welcome Script in pane 0..."
    execute_function "${session_name}" 0 welcome_script "APP_NAME APP_VERSION SESSION_NAME"
    sleep 2
    
    # Demo 2: System Info Script using execute_function
    msg_info "Running System Info Script in pane 1..."
    p1=$(create_new_pane "${session_name}" "v")
    execute_function "${session_name}" "${p1}" info_script "SHARED_DIR"
    sleep 2
    
    # Demo 3: Process Monitor using execute_function
    msg_info "Running Process Monitor in pane 2..."
    p2=$(create_new_pane "${session_name}" "h")
    export WATCH_PROCESS="tmux"
    execute_function "${session_name}" "${p2}" process_monitor_script "WATCH_PROCESS SHARED_DIR"
    
    # Demo 4: File Monitor using execute_function
    msg_info "Running File Monitor in pane 3..."
    p3=$(create_new_pane "${session_name}" "v")
    execute_function "${session_name}" "${p3}" file_monitor_script "SHARED_DIR"
    
    # Demo 5: Status Monitor using execute_function
    msg_info "Running Status Monitor in pane 4..."
    p4=$(create_new_pane "${session_name}" "h")
    execute_function "${session_name}" "${p4}" status_monitor_script "SHARED_DIR"
    
    # Wait for user to press a key
    msg_info "Demo is running in tmux session '${session_name}'"
    msg_success "Press Enter to clean up and exit..."
    read -r
    
    # Cleanup
    kill_tmux_session "${session_name}"
}

# Run the main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    export APP_NAME="Tmux Script Functions Demo"
    export APP_VERSION="1.0.0"
    main "$@"
fi 