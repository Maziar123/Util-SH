#!/usr/bin/env bash
# ===================================================================
# tmux_compare_sharing.sh - Compare variable sharing methods in tmux
# ===================================================================
# DESCRIPTION:
#   Demonstrates two different ways to share variables between tmux panes:
#   1. Using temporary files (traditional method)
#   2. Using tmux environment variables (cleaner approach)
#
#   Creates a tmux session with 4 panes:
#     1. Monitor for file-based variables
#     2. Monitor for tmux environment variables
#     3. Counter using file-based sharing
#     4. Counter using tmux environment variables
#
# USAGE:
#   ./tmux_compare_sharing.sh [--headless]
#
# OPTIONS:
#   --headless - Create session without launching a terminal
# ===================================================================

# === SETUP ===
# Source required utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"   # For colors and messaging
source "${SCRIPT_DIR}/tmux_utils1.sh"  # For tmux session management
sh-globals_init "$@"

# Create temporary file for file-based sharing
FILE_COUNTER="/tmp/file_counter_$$.txt"
echo "0" > "${FILE_COUNTER}"  # Initialize to zero

# === PANE FUNCTIONS ===
# Monitor for file-based counter
monitor_file() {
    # Display title
    tmux rename-window "Sharing Comparison"
    
    # Infinite loop to continuously update display
    while true; do
        clear
        # Check if msg_heading is available before calling
        if command -v msg_header &>/dev/null; then
             msg_header "FILE-BASED SHARING"
        else
             msg_bold "=== FILE-BASED SHARING ===" # Fallback with bold
        fi
        msg "Reading from: ${FILE_COUNTER}"
        if [[ -f "${FILE_COUNTER}" ]]; then
            value=$(cat "${FILE_COUNTER}")
            # Check if msg_info is available
            if command -v msg_cyan &>/dev/null; then
                msg_cyan "Current value: ${value}"
            else
                msg "Current value: ${value}" # Fallback with plain msg
            fi
        else
            # Check if msg_error is available
            if command -v msg_error &>/dev/null; then
                msg_error "File not found!"
            else
                 msg_red "ERROR: File not found!" # Fallback with red msg
            fi
        fi
        sleep 1
    done
}

# Monitor for tmux environment variable-based counter
monitor_tmux_var() {
    # Infinite loop to continuously update display
    while true; do
        clear
        # Check if msg_heading is available
        if command -v msg_header &>/dev/null; then
             msg_header "TMUX VARIABLE SHARING"
        else
             msg_bold "=== TMUX VARIABLE SHARING ===" # Fallback with bold
        fi
        msg "Reading from tmux environment"
        
        # Get value from tmux environment
        value=$(tmux show-environment -g TMUX_COUNTER 2>/dev/null | cut -d= -f2)
        if [[ -n "${value}" ]]; then
            # Check if msg_info is available
            if command -v msg_magenta &>/dev/null; then
                msg_magenta "Current value: ${value}"
            else
                msg "Current value: ${value}" # Fallback with plain msg
            fi
        else
             # Check if msg_error is available
            if command -v msg_error &>/dev/null; then
                msg_error "Variable not set!"
            else
                msg_red "ERROR: Variable not set!" # Fallback with red msg
            fi
            # Initialize it if not set
            tmux set-environment -g TMUX_COUNTER 0
        fi
        sleep 1
    done
}

# Counter using file-based sharing
file_counter() {
    # Infinite loop to update counter
    while true; do
        if [[ -f "${FILE_COUNTER}" ]]; then
            # Read current value
            value=$(($(cat "${FILE_COUNTER}") + 1))
            # Write updated value
            echo "${value}" > "${FILE_COUNTER}"
            
            # Display
            clear
            msg_bg_green "FILE COUNTER: ${value}"
        else
            clear
            msg_error "File not found!"
            echo "0" > "${FILE_COUNTER}"
        fi
        sleep 1
    done
}

# Counter using tmux environment variables
tmux_var_counter() {
    # Initialize if not set
    tmux set-environment -g TMUX_COUNTER 0
    
    # Infinite loop to update counter
    while true; do
        # Get current value
        current=$(tmux show-environment -g TMUX_COUNTER | cut -d= -f2)
        if [[ -n "${current}" ]]; then
            # Increment
            value=$((current + 1))
            # Update tmux environment
            tmux set-environment -g TMUX_COUNTER ${value}
            
            # Display
            clear
            msg_bg_blue "TMUX COUNTER: ${value}"
        else
            clear
            msg_error "Variable not set!"
            tmux set-environment -g TMUX_COUNTER 0
        fi
        sleep 1
    done
}

# === MAIN FUNCTION ===
main() {
    # Parse command-line arguments
    local headless=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --headless)
                headless=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    # Create a new tmux session with duplicate handling
    # Call directly, don't capture output. Check return status.
    if ! create_session_with_duplicate_handling "compare_vars" "$([ "$headless" = "false" ] && echo true || echo false)"; then
        # Function returns 1 if user exited or creation failed.
        # Specific messages are handled within the functions.
        msg_warning "Session creation aborted or failed. Exiting."
        exit 1
    fi
    
    # Use the globally set SESSION_NAME
    local session_name="${SESSION_NAME}"

    # Check if SESSION_NAME is actually set (should be if function returned 0)
    if [[ -z "${session_name}" ]]; then
        msg_error "Critical error: Session name not set despite successful return. Exiting."
        exit 1
    fi
    
    # Display connection information using msg_* functions
    msg_section "Tmux Session Created" 52 "="
    msg "Tmux session '${session_name}' created!"
    msg "If no terminal window opened automatically, connect with:"
    msg_info "tmux attach-session -t ${session_name}"
    msg_section "" 52 "=" # Divider
    
    # Initialize tmux environment variable
    # Ensure the target session exists before setting environment
    if tmux has-session -t "${session_name}" 2>/dev/null; then
        tmux set-environment -g TMUX_COUNTER 0
    else
        msg_error "Failed to find session '${session_name}' before setting environment."
        # Decide whether to exit or continue without setting the var
        # exit 1 
    fi
    
    # Setup panes
    # First pane (0) - File-based monitor
    execute_shell_function "${session_name}" 0 monitor_file "FILE_COUNTER"
    
    # Second pane (1) - Tmux variable monitor
    pane1=$(create_new_pane "${session_name}" "v")
    execute_shell_function "${session_name}" "${pane1}" monitor_tmux_var
    
    # Third pane (2) - File-based counter
    pane2=$(create_new_pane "${session_name}" "h")
    execute_shell_function "${session_name}" "${pane2}" file_counter "FILE_COUNTER"
    
    # Fourth pane (3) - Tmux variable counter
    pane3=$(create_new_pane "${session_name}" "v")
    execute_shell_function "${session_name}" "${pane3}" tmux_var_counter
    
    # Set up cleanup on exit
    trap 'rm -f "${FILE_COUNTER}"; exit 0' INT TERM EXIT
    
    # Keep parent process running using msg_* functions
    msg "Running session: ${session_name}"
    msg_subtle "Press Ctrl+C to stop this script (session will remain active)"
    while true; do sleep 1; done
}

# Show usage using msg_* functions
usage() {
    msg_header "Usage: $(get_script_name) [options]"
    msg "Options:"
    msg "  --headless    Create session without launching a terminal"
    msg "  -h, --help    Show this help message"
}

# === RUN MAIN ===
main "$@" 