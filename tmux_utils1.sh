#!/usr/bin/env bash

# tmux_utils.sh - Universal utilities for working with tmux
# ------------------------------------------------------------

# Source global utilities - use absolute path for shellcheck
# shellcheck source=./sh-globals.sh
# shellcheck disable=SC1091
source "sh-globals.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    sh-globals_init "$@"
fi

# Default terminal configuration
# Terminal preference order: user-specified > konsole > xterm > gnome-terminal
TMUX_TERM_EMULATOR="${TMUX_TERM_EMULATOR:-}"

# Array to track temporary scripts for each session
declare -A TMUX_SESSION_TEMPS=()

# Detect available terminal if not specified
detect_terminal_emulator() {
    # If already set and exists, use it
    if [[ -n "${TMUX_TERM_EMULATOR}" ]] && command -v "${TMUX_TERM_EMULATOR}" &>/dev/null; then
        return 0
    fi
    
    # Check for available terminals in preference order
    local terminals=("konsole" "xterm" "gnome-terminal" "xfce4-terminal" "terminator")
    
    for term in "${terminals[@]}"; do
        if command -v "${term}" &>/dev/null; then
            TMUX_TERM_EMULATOR="${term}"
            log_debug "Detected terminal emulator: ${TMUX_TERM_EMULATOR}"
            return 0
        fi
    done
    
    log_debug "No suitable terminal emulator found"
    return 1
}

# Create a new tmux session and open it in a terminal
# Returns the session name on success, empty string on failure
create_tmux_session() {
    # Check if a session name was provided, otherwise generate one
    local session_name="${1:-tmux_session_$(date +%Y%m%d_%H%M%S)}"
    log_debug "Creating session: ${session_name}"
    
    # Create detached session
    if ! tmux new-session -d -s "${session_name}"; then
        log_debug "Failed to create tmux session"
        return 1
    fi
    
    # Detect terminal emulator if not already set
    detect_terminal_emulator || {
        log_debug "No terminal emulator available"
        # Don't fail completely, just warn - the session is still created
    }
    
    # Open terminal with tmux session if we have one
    if [[ -n "${TMUX_TERM_EMULATOR}" ]]; then
        # Handle different terminal syntax
        case "${TMUX_TERM_EMULATOR}" in
            konsole)
                "${TMUX_TERM_EMULATOR}" --new-tab -e tmux attach-session -t "${session_name}" &
                ;;
            gnome-terminal|xfce4-terminal)
                "${TMUX_TERM_EMULATOR}" -- tmux attach-session -t "${session_name}" &
                ;;
            *)
                # Generic fallback
                "${TMUX_TERM_EMULATOR}" -e "tmux attach-session -t ${session_name}" &
                ;;
        esac
    else
        log_debug "No terminal emulator available. Use 'tmux attach-session -t ${session_name}' to connect."
    fi
    
    # Give tmux a moment to initialize
    sleep 0.5
    
    # Check if session was created successfully
    if ! tmux has-session -t "${session_name}" 2>/dev/null; then
        log_debug "Session verification failed"
            return 1
        fi
    
    # Log session creation
    {
        echo "${session_name}"
        msg_success "New session '${session_name}' created. Use 'tmux attach-session -t ${session_name}' to reconnect."
    } >> ~/.tmux_sessions.log
    
    # Set global SESSION_NAME for use by calling script
    SESSION_NAME="${session_name}"
    
    # Also echo the session name so it can be captured
    echo "${session_name}"
    
    return 0
}

# ======== TMUX SCRIPT EXECUTION METHODS ========
# There are three main ways to run scripts in tmux panes:
#
# 1. EMBEDDED MODE: Direct inline scripts with heredoc
#    execute_script "${SESSION_NAME}" 0 "VARS" <<EOF
#      # Your script here
#    EOF
#
# 2. SCRIPT MODE: Scripts defined in files or functions that return script text
#    execute_function "${SESSION_NAME}" 0 script_generator_function "VARS"
#    execute_file "${SESSION_NAME}" 0 "/path/to/script.sh" "VARS"
#
# 3. DIRECT FUNCTION MODE (RECOMMENDED): Real shell functions, not string generators
#    execute_shell_function "${SESSION_NAME}" 0 actual_shell_function "VARS"
#    - Most natural to write and maintain
#    - Full IDE/syntax support
#    - Easy debugging outside of tmux

# Execute a command in a specific tmux pane
# Arguments:
#   $1: Session name
#   $2: Pane index
#   $3: Command to execute (can be multi-line)
execute_in_pane() {
    local session="${1}"
    local pane="${2}" 
    local cmd="${3}"
    
    log_debug "Exec in ${session}:${pane}: ${cmd}"
    
    # Create a temporary script to execute
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    TMUX_SESSION_TEMPS[${session}]="${TMUX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Get absolute path to the project directory
    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    
    # Write a script that sets up the environment like a normal script
    {
        echo '#!/usr/bin/env bash'
        echo ""
        echo "# Set up script environment"
        echo "SCRIPT_DIR=\"${script_dir}\""
        echo 'cd "${SCRIPT_DIR}"'
        echo 'export PATH="${SCRIPT_DIR}:${PATH}"'
        echo ""
        echo "# Source sh-globals.sh like a normal script"
        echo "source \"${script_dir}/sh-globals.sh\""
        echo ""
        echo "# Initialize globals"
        echo "export DEBUG=1"
        echo "sh-globals_init"
        echo ""
        echo "# Define session self-destruct function"
        echo "tmux_self_destruct() {"
        echo "  local session_name=\$(tmux display-message -p '#S')"
        echo "  echo \"Closing session \${session_name}...\""
        echo "  ( sleep 0.5; tmux kill-session -t \"\${session_name}\" ) &"
        echo "}"
        echo ""
        echo "# User command follows"
        echo "${cmd}"
    } > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script
    tmux send-keys -t "${session}:0.${pane}" "${tmp_script}" C-m
    
    return $?
}

# Modern function to execute multi-line commands in tmux panes
# Uses heredoc for better readability
# Usage: execute_script SESSION PANE [VARS] <<'EOF'
#   commands here
#   more commands
# EOF
execute_script() {
    local session="${1}"
    local pane="${2}"
    local vars="${3:-}"  # Optional: variable names to export from current shell
    
    # Read the script content from heredoc
    local content
    content=$(cat)
    
    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    TMUX_SESSION_TEMPS[${session}]="${TMUX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Get absolute path to the project directory
    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    
    # Write the header of the script
    {
        echo '#!/usr/bin/env bash'
        echo ""
        echo "# Set up script environment"
        echo "SCRIPT_DIR=\"${script_dir}\""
        echo 'cd "${SCRIPT_DIR}"'
        echo 'export PATH="${SCRIPT_DIR}:${PATH}"'
        
        # Export specified variables from parent shell
        if [[ -n "${vars}" ]]; then
            echo "# Export variables from parent shell"
            for var in ${vars}; do
                # Get value and escape it properly for inclusion in the script
                local value="${!var}"
                echo "export ${var}=\"${value}\""
            done
        fi
        
        echo ""
        echo "# Source sh-globals.sh"
        echo "source \"${script_dir}/sh-globals.sh\""
        echo ""
        echo "# Initialize globals"
        echo "export DEBUG=1"
        echo "sh-globals_init"
        echo ""
        echo "# Define session self-destruct function"
        echo "tmux_self_destruct() {"
        echo "  local session_name=\$(tmux display-message -p '#S')"
        echo "  echo \"Closing session \${session_name}...\""
        echo "  ( sleep 0.5; tmux kill-session -t \"\${session_name}\" ) &"
        echo "}"
        echo ""
        echo "# User script follows"
        echo "${content}"
    } > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script
    tmux send-keys -t "${session}:0.${pane}" "${tmp_script}" C-m
    
    return $?
}

# Create a new pane in a tmux session
# Arguments:
#   $1: Session name
#   $2: Split type (optional, default: h for horizontal)
# Returns: The index of the new pane
create_new_pane() {
    local session="${1}"
    local split_type="${2:-h}"  # Default to horizontal split
    
    # Validate split type
    if [[ "${split_type}" != "h" && "${split_type}" != "v" ]]; then
        log_debug "Invalid split type: ${split_type}. Using horizontal."
        split_type="h"
    fi
    
    # Create a new pane
    tmux split-window "-${split_type}" -t "${session}"
    local result=$?
    
    if [[ ${result} -eq 0 ]]; then
        # Get the index of the most recently created pane
        local pane_index
        pane_index=$(tmux list-panes -t "${session}" | wc -l)
        # Adjust to zero-based indexing
        pane_index=$((pane_index - 1))
        echo "${pane_index}"
    fi
    
    return ${result}
}

# List active tmux sessions
list_tmux_sessions() {
    if ! tmux list-sessions 2>/dev/null; then
        echo "No active tmux sessions"
        return 1
    fi
    return 0
}

# Kill a tmux session
# Arguments:
#   $1: Session name
kill_tmux_session() {
    local session="${1}"
    
    if [[ -z "${session}" ]]; then
        log_debug "No session name provided"
        return 1
    fi
    
    if tmux kill-session -t "${session}" 2>/dev/null; then
        log_debug "Killed session: ${session}"
        return 0
    else
        log_debug "Failed to kill session: ${session}"
        return 1
    fi
}

# Send text to a tmux pane without executing
# Arguments:
#   $1: Session name
#   $2: Pane index
#   $3: Text to send
send_text_to_pane() {
    local session="${1}"
    local pane="${2}"
    local text="${3}"
    
    tmux send-keys -t "${session}:0.${pane}" "${text}"
    return $?
}

# Execute a command in all panes of a window
# Arguments:
#   $1: Session name
#   $2: Window index (optional, default: 0)
#   $3: Command to execute
execute_in_all_panes() {
    local session="${1}"
    local window="${2:-0}"
    local cmd="${3}"
    
    # Get all pane indexes in the window
    local panes
    panes=$(tmux list-panes -t "${session}:${window}" -F "#{pane_index}")
    
    # Execute command in each pane
    for pane in ${panes}; do
        execute_in_pane "${session}" "${pane}" "${cmd}"
    done
    
    return 0
}

# Check if a tmux session exists
# Arguments:
#   $1: Session name
# Returns: 0 if session exists, 1 otherwise
session_exists() {
    local session="${1}"
    
    if tmux has-session -t "${session}" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Create a new window in a tmux session
# Arguments:
#   $1: Session name
#   $2: Window name (optional)
# Returns: The index of the new window
create_new_window() {
    local session="${1}"
    local window_name="${2:-}"
    
    local cmd="tmux new-window -t ${session}"
    if [[ -n "${window_name}" ]]; then
        cmd="${cmd} -n ${window_name}"
    fi
    
    # Create the window and get its index
    local window_index
    window_index=$(eval "${cmd}" 2>/dev/null && tmux display-message -p "#{window_index}")
    
    if [[ -n "${window_index}" ]]; then
        echo "${window_index}"
        return 0
    else
        return 1
    fi
}

# Close a tmux session and clean up its resources
close_tmux_session() {
    local session="${1}"
    
    if [[ -z "${session}" ]]; then
        log_debug "No session name provided"
        return 1
    fi
    
    # Clean up temp scripts associated with this session
    if [[ -n "${TMUX_SESSION_TEMPS[${session}]:-}" ]]; then
        log_debug "Cleaning up temp files for session ${session}"
        for tmp_file in ${TMUX_SESSION_TEMPS[${session}]}; do
            if [[ -f "${tmp_file}" ]]; then
                rm -f "${tmp_file}"
                log_debug "Removed temp file: ${tmp_file}"
            fi
        done
        unset TMUX_SESSION_TEMPS[${session}]
    fi
    
    # Kill the session
    if tmux has-session -t "${session}" 2>/dev/null; then
        tmux kill-session -t "${session}" 2>/dev/null
        log_debug "Killed session: ${session}"
        return 0
    else
        log_debug "Session not found: ${session}"
        return 1
    fi
}

# Cleanup all sessions and their resources
cleanup_all_tmux_sessions() {
    log_debug "Cleaning up all tmux sessions and resources"
    
    # Get all sessions managed by us
    local sessions=()
    for session in "${!TMUX_SESSION_TEMPS[@]}"; do
        sessions+=("${session}")
    done
    
    # Close each session
    for session in "${sessions[@]}"; do
        close_tmux_session "${session}"
    done
    
    # Clean up any remaining temp files
    for session_temps in "${TMUX_SESSION_TEMPS[@]}"; do
        for tmp_file in ${session_temps}; do
            if [[ -f "${tmp_file}" ]]; then
                rm -f "${tmp_file}"
                log_debug "Removed orphaned temp file: ${tmp_file}"
            fi
        done
    done
    
    # Clear the tracking array
    TMUX_SESSION_TEMPS=()
    
    return 0
}

# Set up cleanup on script exit
trap 'cleanup_all_tmux_sessions' EXIT HUP INT QUIT TERM

# Execute a script defined in a function
# Arguments:
#   $1: Session name
#   $2: Pane index
#   $3: Function name to execute
#   $4: Space-separated list of variables to export (optional)
# Example:
#   my_script() { echo "echo 'Hello world'"; }
#   execute_function "my_session" 0 my_script "VAR1 VAR2"
execute_function() {
    local session="${1}"
    local pane="${2}"
    local func_name="${3}"
    local vars="${4:-}"
    
    # Check if function exists
    if ! declare -f "${func_name}" > /dev/null; then
        log_error "Function '${func_name}' not found"
        return 1
    fi
    
    # Get script content from function
    local content
    content=$("${func_name}")
    
    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    TMUX_SESSION_TEMPS[${session}]="${TMUX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Get absolute path to the project directory
    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    
    # Write the header of the script
    {
        echo '#!/usr/bin/env bash'
        echo ""
        echo "# Set up script environment"
        echo "SCRIPT_DIR=\"${script_dir}\""
        echo 'cd "${SCRIPT_DIR}"'
        echo 'export PATH="${SCRIPT_DIR}:${PATH}"'
        
        # Export specified variables from parent shell
        if [[ -n "${vars}" ]]; then
            echo "# Export variables from parent shell"
            for var in ${vars}; do
                # Get value and escape it properly for inclusion in the script
                local value="${!var}"
                echo "export ${var}=\"${value}\""
            done
        fi
        
        echo ""
        echo "# Source sh-globals.sh"
        echo "source \"${script_dir}/sh-globals.sh\""
        echo ""
        echo "# Initialize globals"
        echo "export DEBUG=1"
        echo "sh-globals_init"
        echo ""
        echo "# Define session self-destruct function"
        echo "tmux_self_destruct() {"
        echo "  local session_name=\$(tmux display-message -p '#S')"
        echo "  echo \"Closing session \${session_name}...\""
        echo "  ( sleep 0.5; tmux kill-session -t \"\${session_name}\" ) &"
        echo "}"
        echo ""
        echo "# Script from function '${func_name}' follows"
        echo "${content}"
    } > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script
    tmux send-keys -t "${session}:0.${pane}" "${tmp_script}" C-m
    
    return $?
}

# Load a script from a file and execute it in a pane
# Arguments:
#   $1: Session name
#   $2: Pane index
#   $3: Script file path
#   $4: Space-separated list of variables to export (optional)
execute_file() {
    local session="${1}"
    local pane="${2}"
    local script_file="${3}"
    local vars="${4:-}"
    
    # Check if file exists
    if [[ ! -f "${script_file}" ]]; then
        log_error "Script file '${script_file}' not found"
        return 1
    fi
    
    # Read script content from file
    local content
    content=$(<"${script_file}")
    
    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    TMUX_SESSION_TEMPS[${session}]="${TMUX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Get absolute path to the project directory
    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    
    # Write the header of the script
    {
        echo '#!/usr/bin/env bash'
        echo ""
        echo "# Set up script environment"
        echo "SCRIPT_DIR=\"${script_dir}\""
        echo 'cd "${SCRIPT_DIR}"'
        echo 'export PATH="${SCRIPT_DIR}:${PATH}"'
        
        # Export specified variables from parent shell
        if [[ -n "${vars}" ]]; then
            echo "# Export variables from parent shell"
            for var in ${vars}; do
                # Get value and escape it properly for inclusion in the script
                local value="${!var}"
                echo "export ${var}=\"${value}\""
            done
        fi
        
        echo ""
        echo "# Source sh-globals.sh"
        echo "source \"${script_dir}/sh-globals.sh\""
        echo ""
        echo "# Initialize globals"
        echo "export DEBUG=1"
        echo "sh-globals_init"
        echo ""
        echo "# Define session self-destruct function"
        echo "tmux_self_destruct() {"
        echo "  local session_name=\$(tmux display-message -p '#S')"
        echo "  echo \"Closing session \${session_name}...\""
        echo "  ( sleep 0.5; tmux kill-session -t \"\${session_name}\" ) &"
        echo "}"
        echo ""
        echo "# Script from file '${script_file}' follows"
        echo "${content}"
    } > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script
    tmux send-keys -t "${session}:0.${pane}" "${tmp_script}" C-m
    
    return $?
}

# Execute a shell function directly (not as a string generator)
# This allows using normal shell functions in tmux panes
# Arguments:
#   $1: Session name
#   $2: Pane index
#   $3: Shell function to execute (must be defined in the current shell)
#   $4: Space-separated list of variables to export (optional)
# Example:
#   # Define a normal shell function
#   monitor_files() {
#     watch_dir="${WATCH_DIR:-$(pwd)}"
#     echo "Monitoring $watch_dir"
#     while true; do
#       find "$watch_dir" -type f -mtime -1 | sort
#       sleep 5
#     done
#   }
#   # Execute it directly in a tmux pane
#   execute_shell_function "my_session" 0 monitor_files "WATCH_DIR"
execute_shell_function() {
    local session="${1}"
    local pane="${2}"
    local func_name="${3}"
    local vars="${4:-}"
    
    # Check if function exists
    if ! declare -f "${func_name}" > /dev/null; then
        log_error "Shell function '${func_name}' not found"
        return 1
    fi
    
    # Export the function definition itself
    local func_def
    func_def=$(declare -f "${func_name}")
    
    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    TMUX_SESSION_TEMPS[${session}]="${TMUX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Get absolute path to the project directory
    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    
    # Write the script that will run the function
    {
        echo '#!/usr/bin/env bash'
        echo ""
        echo "# Set up script environment"
        echo "SCRIPT_DIR=\"${script_dir}\""
        echo 'cd "${SCRIPT_DIR}"'
        echo 'export PATH="${SCRIPT_DIR}:${PATH}"'
        
        # Export specified variables from parent shell
        if [[ -n "${vars}" ]]; then
            echo "# Export variables from parent shell"
            for var in ${vars}; do
                # Get value and escape it properly for inclusion in the script
                local value="${!var}"
                echo "export ${var}=\"${value}\""
            done
        fi
        
        echo ""
        echo "# Source sh-globals.sh"
        echo "source \"${script_dir}/sh-globals.sh\""
        echo ""
        echo "# Initialize globals"
        echo "export DEBUG=1"
        echo "sh-globals_init"
        echo ""
        echo "# Define session self-destruct function"
        echo "tmux_self_destruct() {"
        echo "  local session_name=\$(tmux display-message -p '#S')"
        echo "  echo \"Closing session \${session_name}...\""
        echo "  ( sleep 0.5; tmux kill-session -t \"\${session_name}\" ) &"
        echo "}"
        echo ""
        echo "# Define the shell function"
        echo "${func_def}"
        echo ""
        echo "# Execute the function"
        echo "${func_name}"
    } > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script
    tmux send-keys -t "${session}:0.${pane}" "${tmp_script}" C-m
    
    return $?
}