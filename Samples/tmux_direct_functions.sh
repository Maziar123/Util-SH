#!/usr/bin/env bash
# tmux_direct_functions.sh - Direct shell function examples for tmux

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/sh-globals.sh"
# shellcheck source=../tmux_utils1.sh
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals only if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    # Enable debug logging
    export DEBUG=1
    sh-globals_init "$@"
fi

# These are normal shell functions (not string generators)
# They contain actual commands that will be executed directly

# Monitor files in a directory
monitor_files() {
    local watch_dir="${WATCH_DIR:-$(pwd)}"
    
    msg_bg_cyan "File Monitor (Direct Function)"
    msg_info "This pane is monitoring file changes in: $watch_dir"
    echo "Press Ctrl+C to stop monitoring"
    
    # Initial listing
    echo "----------------------------------------"
    echo "Last modified files (last 5):"
    find "$watch_dir" -type f -printf "%TY-%Tm-%Td %TH:%TM:%TS %p\n" 2>/dev/null | sort -r | head -5
    
    # Setup monitoring loop
    while true; do
        sleep 5
        echo "----------------------------------------"
        echo "Last modified files (last 5):"
        find "$watch_dir" -type f -printf "%TY-%Tm-%Td %TH:%TM:%TS %p\n" 2>/dev/null | sort -r | head -5
    done
}

# Monitor system resources
monitor_system() {
    local refresh_rate="${REFRESH_RATE:-3}"
    
    msg_bg_green "System Monitor (Direct Function)"
    msg_info "Monitoring system resources every ${refresh_rate} seconds"
    echo "Press Ctrl+C to stop monitoring"
    
    # Setup monitoring loop
    while true; do
        echo "----------------------------------------"
        echo "Time: $(date)"
        
        # CPU usage
        echo "CPU Usage:"
        top -bn1 | head -3 | tail -2
        
        # Memory usage
        echo "Memory Usage:"
        free -h | head -2
        
        # Disk usage
        echo "Disk Usage:"
        df -h | grep -E '^/dev/' | sort | head -3
        
        sleep "$refresh_rate"
        echo ""
    done
}

# Interactive shell menu
interactive_menu() {
    msg_bg_yellow "Interactive Menu (Direct Function)"
    msg_info "This is an interactive shell menu"
    
    # Main menu loop
    while true; do
        echo "----------------------------------------"
        echo "MAIN MENU"
        echo "1) System Information"
        echo "2) List Files"
        echo "3) Current Processes"
        echo "4) Exit"
        
        read -p "Enter choice [1-4]: " choice
        echo ""
        
        case $choice in
            1)
                echo "System Information:"
                uname -a
                echo "Hostname: $(hostname)"
                echo "User: $(whoami)"
                echo "Memory:"
                free -h | head -2
                ;;
            2)
                echo "Files in current directory:"
                ls -la
                ;;
            3)
                echo "Current processes (top 10):"
                ps aux | head -11
                ;;
            4)
                msg_info "Exiting menu"
                return 0
                ;;
            *)
                msg_error "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Self-destruct countdown
self_destruct_countdown() {
    local countdown="${COUNTDOWN:-10}"
    
    msg_bg_red "SESSION SELF-DESTRUCT (Direct Function)"
    msg_warning "This session will self-destruct in ${countdown} seconds"
    echo "Press Ctrl+C to abort"
    
    # Countdown loop
    for (( i=countdown; i>0; i-- )); do
        echo "Self-destruct in $i seconds..."
        sleep 1
    done
    
    msg_error "INITIATING SELF-DESTRUCT SEQUENCE"
    sleep 1
    tmux_self_destruct
}

# Main function
main() {
    # Create a new tmux session
    local session_name
    session_name=$(create_tmux_session)
    if [[ -z "${session_name}" ]]; then
        msg_error "Failed to create session. Exiting."
        exit 1
    fi
    msg_success "Created new tmux session: ${session_name}"
    sleep 2  # Give time for session to initialize
    
    # Demo direct shell functions in different panes
    
    # Set up file monitoring in the first pane
    msg_info "Setting up file monitor in pane 0"
    WATCH_DIR="/tmp"  # Example directory to monitor
    execute_shell_function "${session_name}" 0 monitor_files "WATCH_DIR"
    sleep 2
    
    # Create a new pane and set up system monitoring
    local pane_idx
    pane_idx=$(create_new_pane "${session_name}")
    if [[ -n "${pane_idx}" ]]; then
        msg_success "Created pane ${pane_idx} for system monitoring"
        REFRESH_RATE=5
        execute_shell_function "${session_name}" "${pane_idx}" monitor_system "REFRESH_RATE"
        sleep 2
    fi
    
    # Create another pane for interactive menu
    local pane_idx2
    pane_idx2=$(create_new_pane "${session_name}" "v")
    if [[ -n "${pane_idx2}" ]]; then
        msg_success "Created pane ${pane_idx2} for interactive menu"
        execute_shell_function "${session_name}" "${pane_idx2}" interactive_menu
        sleep 2
    fi
    
    # Create a final pane for self-destruct countdown
    local pane_idx3
    pane_idx3=$(create_new_pane "${session_name}" "h")
    if [[ -n "${pane_idx3}" ]]; then
        msg_success "Created pane ${pane_idx3} for self-destruct countdown"
        COUNTDOWN=15  # longer countdown to have time to see the other panes
        execute_shell_function "${session_name}" "${pane_idx3}" self_destruct_countdown "COUNTDOWN"
    fi
    
    msg_info "All panes set up. Session will self-destruct from pane ${pane_idx3}"
    
    # Wait for session to end
    while tmux has-session -t "${session_name}" 2>/dev/null; do
        sleep 1
    done
    
    msg_success "Session ${session_name} has ended"
}

# If run directly (not sourced), execute main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 