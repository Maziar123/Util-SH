#!/usr/bin/env bash
# tmux_variable_sharing.sh - Demonstrates and compares different variable sharing methods in tmux

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
echo "SCRIPT_DIR: ${SCRIPT_DIR}"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/sh-globals.sh"
# shellcheck source=../tmux_utils1.sh
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    # Enable debug logging
    export DEBUG=1
    sh-globals_init "$@"
fi

# === CONFIGURATION ===
SHARED_DIR="/tmp/tmux_share_$$.d"
mkdir -p "${SHARED_DIR}"

# Cleanup function
cleanup() {
    rm -rf "${SHARED_DIR}"
}
trap cleanup EXIT

# === SHARING METHODS ===

# Method 1: File-based sharing
file_writer() {
    local counter=0
    local start_time=$(date +%s%N)
    local iterations=1000
    
    for ((i=0; i<iterations; i++)); do
        echo "$((counter++))" > "${SHARED_DIR}/file_counter.txt"
        sync
    done
    
    local end_time=$(date +%s%N)
    local duration=$((end_time - start_time))
    echo "File-based: $duration ns ($((duration/iterations)) ns/op)" > "${SHARED_DIR}/file_perf.txt"
}

file_reader() {
    while true; do
        if [[ -f "${SHARED_DIR}/file_counter.txt" ]]; then
            clear
            msg_bg_blue "File-based Counter:"
            cat "${SHARED_DIR}/file_counter.txt"
        fi
        sleep 0.1
    done
}

# Method 2: Tmux variable sharing
tmux_var_writer() {
    local counter=0
    local start_time=$(date +%s%N)
    local iterations=1000
    
    for ((i=0; i<iterations; i++)); do
        tmux set-environment -g TMUX_COUNTER "$((counter++))"
    done
    
    local end_time=$(date +%s%N)
    local duration=$((end_time - start_time))
    echo "Tmux var: $duration ns ($((duration/iterations)) ns/op)" > "${SHARED_DIR}/tmux_perf.txt"
}

tmux_var_reader() {
    while true; do
        clear
        msg_bg_green "Tmux Variable Counter:"
        tmux show-environment -g TMUX_COUNTER
        sleep 0.1
    done
}

# Method 3: Named pipe sharing
pipe_writer() {
    local pipe="${SHARED_DIR}/counter_pipe"
    mkfifo "${pipe}"
    
    local counter=0
    local start_time=$(date +%s%N)
    local iterations=1000
    
    for ((i=0; i<iterations; i++)); do
        echo "$((counter++))" > "${pipe}" &
    done
    
    local end_time=$(date +%s%N)
    local duration=$((end_time - start_time))
    echo "Named pipe: $duration ns ($((duration/iterations)) ns/op)" > "${SHARED_DIR}/pipe_perf.txt"
}

pipe_reader() {
    local pipe="${SHARED_DIR}/counter_pipe"
    
    while true; do
        if read -r value < "${pipe}"; then
            clear
            msg_bg_magenta "Named Pipe Counter:"
            echo "${value}"
        fi
        sleep 0.1
    done
}

# Performance monitor
perf_monitor() {
    while true; do
        clear
        msg_header "Performance Comparison"
        echo "==========================="
        
        if [[ -f "${SHARED_DIR}/file_perf.txt" ]]; then
            cat "${SHARED_DIR}/file_perf.txt"
        fi
        
        if [[ -f "${SHARED_DIR}/tmux_perf.txt" ]]; then
            cat "${SHARED_DIR}/tmux_perf.txt"
        fi
        
        if [[ -f "${SHARED_DIR}/pipe_perf.txt" ]]; then
            cat "${SHARED_DIR}/pipe_perf.txt"
        fi
        
        sleep 1
    done
}

# Interactive menu demo (from test_tmux1.sh)
interactive_menu() {
    local this_session=$(tmux display-message -p '#S')
    local pane_id=$(tmux display-message -p '#P')
    
    clear
    msg_header "Interactive Variable Sharing Demo"
    msg_bg_magenta "SESSION: ${this_session} - PANE: ${pane_id}"
    msg_info "This pane demonstrates interactive variable manipulation"
    echo ""
    
    # Show current counter value
    local current=$(cat "${SHARED_DIR}/file_counter.txt" 2>/dev/null || echo "0")
    echo "Initial shared counter value: ${current}"
    echo ""
    
    # Run a menu-driven counter increment demo
    msg_cyan "Select a counter operation:"
    select op in "Add 1" "Add 10" "Double" "Reset" "Exit"; do
        case $op in
            "Add 1")
                local new_value=$((current + 1))
                echo "${new_value}" > "${SHARED_DIR}/file_counter.txt"
                msg_green "Counter: ${current} -> ${new_value} (+1)"
                current="${new_value}"
                ;;
            "Add 10")
                local new_value=$((current + 10))
                echo "${new_value}" > "${SHARED_DIR}/file_counter.txt"
                msg_green "Counter: ${current} -> ${new_value} (+10)"
                current="${new_value}"
                ;;
            "Double")
                local new_value=$((current * 2))
                echo "${new_value}" > "${SHARED_DIR}/file_counter.txt"
                msg_green "Counter: ${current} -> ${new_value} (doubled)"
                current="${new_value}"
                ;;
            "Reset")
                echo "0" > "${SHARED_DIR}/file_counter.txt"
                msg_yellow "Counter reset to 0"
                current="0"
                ;;
            "Exit")
                break
                ;;
            *)
                msg_error "Invalid option"
                ;;
        esac
        sync
        echo ""
        echo "Select another operation or Exit:"
    done
}

# === MAIN FUNCTION ===
main() {
    # Create a new tmux session
    local session_name="var_share_demo_$$"
    
    if ! create_session_with_duplicate_handling "${session_name}"; then
        msg_error "Failed to create tmux session"
        return 1
    fi
    
    # Get the actual session name (in case it was modified for uniqueness)
    session_name="${SESSION_NAME}"
    
    # Create panes for different sharing methods
    msg_info "Setting up demonstration panes..."
    
    # Performance monitor in pane 0
    execute_shell_function "${session_name}" 0 perf_monitor "SHARED_DIR"
    
    # File-based sharing (panes 1-2)
    p1=$(create_new_pane "${session_name}" "v")
    execute_shell_function "${session_name}" "${p1}" file_writer "SHARED_DIR"
    
    p2=$(create_new_pane "${session_name}" "h")
    execute_shell_function "${session_name}" "${p2}" file_reader "SHARED_DIR"
    
    # Tmux variable sharing (panes 3-4)
    p3=$(create_new_pane "${session_name}" "v")
    execute_shell_function "${session_name}" "${p3}" tmux_var_writer
    
    p4=$(create_new_pane "${session_name}" "h")
    execute_shell_function "${session_name}" "${p4}" tmux_var_reader
    
    # Named pipe sharing (panes 5-6)
    p5=$(create_new_pane "${session_name}" "v")
    execute_shell_function "${session_name}" "${p5}" pipe_writer "SHARED_DIR"
    
    p6=$(create_new_pane "${session_name}" "h")
    execute_shell_function "${session_name}" "${p6}" pipe_reader "SHARED_DIR"
    
    # Interactive menu demo (pane 7)
    p7=$(create_new_pane "${session_name}" "v")
    execute_shell_function "${session_name}" "${p7}" interactive_menu "SHARED_DIR"
    
    # Keep script running and show instructions
    msg_info "Variable sharing demo is running in session: ${session_name}"
    msg_success "Press Enter to clean up and exit..."
    read -r
    
    # Cleanup
    kill_tmux_session "${session_name}"
}

# Run the main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 