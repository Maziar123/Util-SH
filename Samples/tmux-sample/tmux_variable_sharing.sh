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
    
    if ! tmx_create_session_with_handling "${session_name}"; then
        msg_error "Failed to create tmux session"
        return 1
    fi
    
    # Get the actual session name (in case it was modified for uniqueness)
    session_name="${SESSION_NAME}"
    
    # Create panes for different sharing methods
    msg_info "Setting up demonstration panes..."
    
    # Performance monitor (top pane)
    p0=$(tmx_pane_function "${session_name}" perf_monitor "0" "SHARED_DIR")
    
    # File sharing (left side, top half)
    p1=$(tmx_pane_function "${session_name}" file_writer "v" "SHARED_DIR")
    
    # File sharing (left side, bottom half)
    p2=$(tmx_pane_function "${session_name}" file_reader "h" "SHARED_DIR")
    
    # Tmux variable sharing (middle, top half)
    p3=$(tmx_pane_function "${session_name}" tmux_var_writer "v" "")
    
    # Tmux variable sharing (middle, bottom half)
    p4=$(tmx_pane_function "${session_name}" tmux_var_reader "h" "")
    
    # Named pipe sharing (right side, top half)
    p5=$(tmx_pane_function "${session_name}" pipe_writer "v" "SHARED_DIR")
    
    # Named pipe sharing (right side, bottom half)
    p6=$(tmx_pane_function "${session_name}" pipe_reader "h" "SHARED_DIR")
    
    # Interactive menu - separate pane on far right
    p7=$(tmx_pane_function "${session_name}" interactive_menu "v" "SHARED_DIR")
    
    # Keep script running and show instructions
    msg_info "Variable sharing demo is running in session: ${session_name}"
    msg_success "Press Enter to clean up and exit..."
    read -r
    
    # Cleanup
    echo "Cleaning up, killing session ${session_name}"
    tmx_kill_session "${session_name}"
}

# Run the main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 