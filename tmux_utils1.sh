#!/usr/bin/env bash

# =======================================================================
# NAMING CONVENTION REFACTORING GUIDE:
# 
# This file is being refactored to follow these rules:
# 1. All functions use tmx_ prefix (indicates tmux functionality)
# 2. No "tmux" in function names after the prefix (redundant)
# 3. Global variables use TMX_ prefix (uppercase for globals)
# 
# Examples:
# - create_tmux_session → tmx_create_session
# - kill_tmux_session → tmx_kill_session
# - TMUX_TERM_EMULATOR → TMX_TERM_EMULATOR
# =======================================================================

# tmux_utils.sh - Universal utilities for working with tmux
# ------------------------------------------------------------

# Source global utilities - use absolute path for shellcheck
# shellcheck source=./sh-globals.sh
# shellcheck disable=SC1091,SC2317,SC2155,SC2034,SC2250,SC2162,SC2312
source "sh-globals.sh"

# Source the new utility files
source "tmux_base_utils.sh" || { echo "ERROR: Failed to source tmux_base_utils.sh"; exit 1; }
source "tmux_script_generator.sh" || { echo "ERROR: Failed to source tmux_script_generator.sh"; exit 1; }

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    sh-globals_init "$@"
fi

# Guard variable to prevent re-initialization when sourced in pane scripts
export TMUX_UTILS1_SOURCED=1

# Initialize the tracking array in both contexts
if [[ ! -v TMX_SESSION_TEMPS ]]; then
    declare -A TMX_SESSION_TEMPS=()
    msg_debug "Initialized TMX_SESSION_TEMPS array"
fi

# Only run initialization code if not sourced in a pane
if [[ -z "${TMUX_UTILS1_SOURCED_IN_PANE:-}" ]]; then
    # Default terminal configuration
    # Terminal preference order: user-specified > konsole > xterm > gnome-terminal
    TMX_TERM_EMULATOR="${TMX_TERM_EMULATOR:-}"

    # Debug directory for saving script copies
    # If DEBUG=1 and TMX_DEBUG_DIR is not set, use a default directory
    if [[ "${DEBUG:-0}" -eq 1 && -z "${TMX_DEBUG_DIR}" ]]; then
        # Create default debug directory in script's location
        SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
        TMX_DEBUG_DIR="${SCRIPT_DIR}/tmux_debug_scripts"
        # Check if directory exists and prompt before deleting
        if [[ -d "${TMX_DEBUG_DIR}" ]]; then
            # Use standard read prompt
            read -p "Debug directory '${TMX_DEBUG_DIR}' exists. Clear it? [y/N]: " clear_choice
            echo "" # Newline after prompt
            if [[ "${clear_choice,,}" == "y" ]]; then # Convert to lowercase
                msg_info "Clearing existing debug directory: ${TMX_DEBUG_DIR}"
        rm -rf "${TMX_DEBUG_DIR}"
            else
                msg_info "Using existing debug directory without clearing: ${TMX_DEBUG_DIR}"
            fi
        fi
        mkdir -p "${TMX_DEBUG_DIR}"
        msg_debug "Using debug scripts directory: ${TMX_DEBUG_DIR}"
    fi

    # Use user-specified debug directory if set
    TMX_DEBUG_DIR="${TMX_DEBUG_DIR:-}"

    # Global variable to hold the result of handle_duplicate_session
    CHOSEN_SESSION_NAME=""

    # Global variables for session confirmation
    TMX_SESSION_CONFIRM_COLOR="${GREEN}"  # Default confirmation color
    TMX_SESSION_CONFIRM_TIME=1            # Default display time in seconds

    # Add a debug directory setting for script debugging
    TMX_DEBUG_DIR="${TMX_DEBUG_DIR:-}"  # Directory to save debug scripts, if set
fi

# Detect available terminal if not specified
tmx_detect_terminal() {
    # If already set and exists, use it
    if [[ -n "${TMX_TERM_EMULATOR}" ]] && command -v "${TMX_TERM_EMULATOR}" &>/dev/null; then
        msg_debug "Using pre-configured terminal: ${TMX_TERM_EMULATOR}"
        return 0
    fi
    
    # Check for available terminals in preference order
    local terminals=("konsole" "xterm" "gnome-terminal" "xfce4-terminal" "terminator")
    
    for term in "${terminals[@]}"; do
        if command -v "${term}" &>/dev/null; then
            TMX_TERM_EMULATOR="${term}"
            msg_debug "Detected terminal emulator: ${TMX_TERM_EMULATOR}"
            return 0
        fi
    done
    
    msg_debug "No suitable terminal emulator found"
    return 1
}

# Launch a terminal with a tmux session
# Arguments:
#   $1: Session name
# Returns: 0 on success, 1 on failure
tmx_launch_terminal() {
    local session_name="${1}"
    
    # Detect terminal emulator if not already set
    tmx_detect_terminal || {
        msg_error "No terminal emulator available to launch session '${session_name}'"
        return 1
    }
    
    # Open terminal with tmux session if we have one
    if [[ -n "${TMX_TERM_EMULATOR}" ]]; then
        msg_debug "Launching terminal '${TMX_TERM_EMULATOR}' for session '${session_name}'"
        # Handle different terminal syntax
        case "${TMX_TERM_EMULATOR}" in
            konsole)
                # Suppress Qt errors to stderr
                "${TMX_TERM_EMULATOR}" --new-tab -e tmux attach-session -t "${session_name}" 2>/dev/null &
                sleep 0.5  # Give it a moment to start
                # For konsole, assume success if we got this far
                msg_debug "Konsole launch initiated for '${session_name}'"
                return 0
                ;;
            gnome-terminal|xfce4-terminal)
                "${TMX_TERM_EMULATOR}" -- tmux attach-session -t "${session_name}" 2>/dev/null &
                sleep 0.5
                # For these terminals, also assume success by default
                msg_debug "Terminal launch initiated for '${session_name}'"
                return 0
                ;;
            *)
                # Generic fallback - launch and verify
                "${TMX_TERM_EMULATOR}" -e "tmux attach-session -t ${session_name}" 2>/dev/null &
                local terminal_pid=$!
                sleep 0.5
                
                # For other terminals, try to check PID but be more lenient
                if kill -0 $terminal_pid 2>/dev/null; then
                    msg_debug "Terminal launch succeeded (PID: $terminal_pid)"
                    return 0
                else
                    # Check if session is attached, which is a better indicator of success
                    if tmux list-sessions | grep -q "${session_name}" | grep -q "(attached)"; then
                        msg_debug "Terminal appears attached to session '${session_name}'"
                        return 0
                    else
                        msg_debug "Cannot verify terminal launch for '${session_name}'"
                        # Return success anyway since modern terminals often fork quickly
                        return 0
                    fi
                fi
                ;;
        esac
    else
        msg_error "No terminal emulator available"
        return 1
    fi
}

# Create a new tmux session and open it in a terminal
# Arguments:
#   $1: Session name
#   $2: Launch terminal flag (optional, default: true)
#     - Can be "true" or "false" to control terminal launching
#     - Can also be "--headless" which will be treated as "false"
# Returns: 0 on success, 1 on failure
tmx_create_session() {
    # Check if a session name was provided, otherwise generate one
    local session_name="${1:-session_$(date +%Y%m%d_%H%M%S)}"
    local launch_terminal="${2:-true}"
    
    # Handle case where launch_terminal is "--headless"
    if [[ "${launch_terminal}" == "--headless" ]]; then
        launch_terminal="false"
    fi
    
    msg_debug "Attempting to create session: ${session_name} (launch_terminal=${launch_terminal})"
    
    # Check if session already exists
    if tmux has-session -t "${session_name}" 2>/dev/null; then
        msg_error "Session '${session_name}' already exists"
        return 1
    fi
    
    # Create detached session
    if ! tmux new-session -d -s "${session_name}"; then
        msg_error "Failed to create tmux session '${session_name}'"
        return 1
    fi
    
    # Launch terminal if requested
    if [[ "${launch_terminal}" == "true" ]]; then
        if ! tmx_launch_terminal "${session_name}"; then
            msg_warning "Terminal launch failed for '${session_name}', but session created."
            # Continue as the session was still created successfully
        fi
    else
        # Use plain message for headless mode (no box formatting to avoid capture issues)
        msg_info "Headless tmux session '${session_name}' created! To connect, run:"
        msg_info "tmux attach-session -t ${session_name}"
    fi
    
    # Give tmux a moment to initialize
    sleep 2  # Increased from 0.5 to 2 seconds
    
    # Check if session was created successfully
    if ! tmux has-session -t "${session_name}" 2>/dev/null; then
        msg_debug "=================================================="
        msg_debug "Verification command failed: 'tmux has-session -t ${session_name}'"
        msg_debug "Environment debugging info:"
        msg_debug "- TMUX variable: ${TMUX:-not set}"
        msg_debug "- TMUX_SOCKET: ${TMUX_SOCKET:-not set}"
        msg_debug "- Current user: $(whoami)"
        msg_debug "- Current path: $(pwd)"
        
        # Try running with explicit socket if TMUX_SOCKET is set
        if [[ -n "${TMUX_SOCKET:-}" ]]; then
            msg_debug "Trying with explicit socket: tmux -S ${TMUX_SOCKET} has-session -t ${session_name}"
            tmux -S "${TMUX_SOCKET}" has-session -t "${session_name}" && msg_debug "Session exists with explicit socket!"
        fi
        
        # Try with absolute unescaped session name
        msg_debug "Trying alternate command: 'tmux list-sessions | grep ${session_name}'"
        tmux list-sessions 2>/dev/null | grep "${session_name}" && msg_debug "Session found in list-sessions output!"
        
        # Log all sessions
        msg_debug "All active sessions:"
        tmux list-sessions 2>/dev/null || msg_debug "No sessions found"
        msg_debug "=================================================="
        
        msg_error "Session verification failed for '${session_name}'"
        return 1
    fi
    
    msg_debug "Session successfully created: ${session_name}"
    
    # Log session creation
    {
        echo "${session_name}"
        msg_success "New session '${session_name}' created. Use 'tmux attach-session -t ${session_name}' to reconnect."
    } >> ~/.tmux_sessions.log
    
    # Export the session name for use by calling code
    export TMX_SESSION_NAME="${session_name}"
    
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

# Helper function to generate common script boilerplate -> MOVED to tmux_script_generator.sh
# tmx_generate_script_boilerplate() { ... }

# Execute a command in a specific tmux pane
# Arguments:
#   $1: Session name
#   $2: Pane index or pane ID (%ID format)
#   $3: Command to execute (can be multi-line)
tmx_execute_in_pane() {
    local session="${1}"
    local pane_input="${2}" # Original input (index or %ID)
    local cmd="${3}"
    local target_pane_id=""

    msg_debug "tmx_execute_in_pane: session='${session}', pane_input='${pane_input}'"

    # Determine the target pane ID
    if [[ "${pane_input}" =~ ^%[0-9]+$ ]]; then
        # Input is already a pane ID
        target_pane_id="${pane_input}"
        msg_debug "Using provided pane ID: ${target_pane_id}"
    elif [[ "${pane_input}" =~ ^[0-9]+$ ]]; then
        # Input is a pane index, convert to ID
        msg_debug "Input is pane index ${pane_input}, converting to ID..."
        target_pane_id=$(tmx_get_pane_id "${session}" "${pane_input}")
        if [[ -z "${target_pane_id}" ]]; then
            msg_error "Failed to find pane ID for index ${pane_input} in session ${session}"
            return 1
        fi
        msg_debug "Converted index ${pane_input} to pane ID: ${target_pane_id}"
    else
        msg_error "Invalid pane identifier: '${pane_input}'. Must be an index (e.g., 0) or ID (e.g., %1)."
        return 1
    fi

    msg_debug "Executing in pane ${target_pane_id}: ${cmd}"

    # Create a temporary script to execute
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    # Check for empty session name to avoid bad array subscript error
    if [[ -n "${session}" ]]; then
        TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    else
        msg_warning "Empty session name provided for temp script tracking"
    fi
    
    # Generate script content using helper function
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${cmd}" "User command")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script using the Pane ID
    msg_debug "Sending script ${tmp_script} to pane ${target_pane_id}"
    tmux send-keys -t "${target_pane_id}" "${tmp_script}" C-m

    local send_status=$?
    msg_debug "send-keys status for ${target_pane_id}: ${send_status}"
    return ${send_status}
}

# Modern function to execute multi-line commands in tmux panes
# Uses heredoc for better readability
# Usage: tmx_execute_script SESSION PANE [VARS] <<'EOF'
#   commands here
#   more commands
# EOF
# Arguments:
#   $1: Session name
#   $2: Pane index or pane ID (%ID format)
#   $3: Space-separated list of variables to export (optional)
tmx_execute_script() {
    local session="${1}"
    local pane_input="${2}" # Original input (index or %ID)
    local vars="${3:-}"  # Optional: variable names to export from current shell
    local target_pane_id=""

    msg_debug "tmx_execute_script: session='${session}', pane_input='${pane_input}', vars='${vars:-none}'"

    # Determine the target pane ID
    if [[ "${pane_input}" =~ ^%[0-9]+$ ]]; then
        # Input is already a pane ID
        target_pane_id="${pane_input}"
        msg_debug "Using provided pane ID: ${target_pane_id}"
    elif [[ "${pane_input}" =~ ^[0-9]+$ ]]; then
        # Input is a pane index, convert to ID
        msg_debug "Input is pane index ${pane_input}, converting to ID..."
        target_pane_id=$(tmx_get_pane_id "${session}" "${pane_input}")
        if [[ -z "${target_pane_id}" ]]; then
            msg_error "Failed to find pane ID for index ${pane_input} in session ${session}"
            return 1
        fi
        msg_debug "Converted index ${pane_input} to pane ID: ${target_pane_id}"
    else
        msg_error "Invalid pane identifier: '${pane_input}'. Must be an index (e.g., 0) or ID (e.g., %1)."
        return 1
    fi

    # Use msg_debug for internal operation details
    msg_debug "Execute script via heredoc in pane ${target_pane_id} (vars: ${vars:-none})"

    # Read the script content from heredoc
    local content
    content=$(cat)
    
    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    # Check for empty session name to avoid bad array subscript error
    if [[ -n "${session}" ]]; then
        TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    else
        msg_warning "Empty session name provided for temp script tracking"
    fi
    
    # Generate script content using helper function
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${content}" "User script" "${vars}")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script using the Pane ID
    msg_debug "Sending script ${tmp_script} to pane ${target_pane_id}"
    tmux send-keys -t "${target_pane_id}" "${tmp_script}" C-m

    local send_status=$?
    msg_debug "send-keys status for ${target_pane_id}: ${send_status}"
    return ${send_status}
}

# Create a new pane in a tmux session
# Arguments:
#   $1: Session name
#   $2: Split type (optional, default: h for horizontal)
# Returns: The ID of the new pane (in %ID format)
tmx_create_pane() {
    local session="${1}"
    local split_type="${2:-h}"  # Default to horizontal split
    
    # Validate split type
    if [[ "${split_type}" != "h" && "${split_type}" != "v" ]]; then
        msg_warning "Invalid split type: ${split_type}. Using horizontal."
        split_type="h"
    fi
    
    # Create a new pane
    tmux split-window "-${split_type}" -t "${session}"
    local result=$?
    
    if [[ ${result} -eq 0 ]]; then
        # Get the ID of the most recently created pane
        local pane_id
        pane_id=$(tmux list-panes -t "${session}" -F "#{pane_id}" | tail -1)
        msg_debug "Created new pane with ID: ${pane_id}"
        
        echo "${pane_id}"
    fi
    
    return ${result}
}

# List active tmux sessions
tmx_list_sessions() {
    if ! tmux list-sessions 2>/dev/null; then
        msg_info "No active tmux sessions"
        return 1
    fi
    return 0
}

# Kill a tmux session
# Arguments:
#   $1: Session name
tmx_kill_session() {
    local session="${1}"
    
    if [[ -z "${session}" ]]; then
        msg_error "Kill session failed: No session name provided"
        return 1
    fi
    
    if tmux kill-session -t "${session}" 2>/dev/null; then
        msg_info "Killed session: ${session}"
        return 0
    else
        msg_warning "Failed to kill session (may not exist): ${session}"
        return 1
    fi
}

# Send text to a tmux pane without executing
# Arguments:
#   $1: Session name
#   $2: Pane index or pane ID (%ID format)
#   $3: Text to send
tmx_send_text() {
    local session="${1}"
    local pane_input="${2}" # Original input (index or %ID)
    local text="${3}"
    local target_pane_id=""

    msg_debug "tmx_send_text: session='${session}', pane_input='${pane_input}'"

    # Determine the target pane ID
    if [[ "${pane_input}" =~ ^%[0-9]+$ ]]; then
        # Input is already a pane ID
        target_pane_id="${pane_input}"
        msg_debug "Using provided pane ID: ${target_pane_id}"
    elif [[ "${pane_input}" =~ ^[0-9]+$ ]]; then
        # Input is a pane index, convert to ID
        msg_debug "Input is pane index ${pane_input}, converting to ID..."
        target_pane_id=$(tmx_get_pane_id "${session}" "${pane_input}")
        if [[ -z "${target_pane_id}" ]]; then
            msg_error "Failed to find pane ID for index ${pane_input} in session ${session}"
            return 1
        fi
        msg_debug "Converted index ${pane_input} to pane ID: ${target_pane_id}"
    else
        msg_error "Invalid pane identifier: '${pane_input}'. Must be an index (e.g., 0) or ID (e.g., %1)."
        return 1
    fi

    msg_debug "Sending text to pane ${target_pane_id}"
    tmux send-keys -t "${target_pane_id}" "${text}"
    local send_status=$?
    msg_debug "send-keys status for ${target_pane_id}: ${send_status}"
    return ${send_status}
}

# Execute a command in all panes of a window
# Arguments:
#   $1: Session name
#   $2: Window index (optional, default: 0)
#   $3: Command to execute
#   $4: Skip pane IDs list - space-separated list of pane IDs to skip (optional)
tmx_execute_all_panes() {
    local session="${1}"
    local window="${2:-0}"
    local cmd="${3}"
    local skip_ids="${4:-}"
    
    msg_debug "tmx_execute_all_panes: session='${session}', window='${window}', skip_ids='${skip_ids:-none}'"

    # Convert skip_ids to an array for easier checking
    local -a skip_id_array
    if [[ -n "${skip_ids}" ]]; then
        read -ra skip_id_array <<< "${skip_ids}"
    fi
    
    # Get all panes in the window with their IDs
    local pane_list
    pane_list=$(tmux list-panes -t "${session}:${window}" -F "#{pane_id}")
    msg_debug "Panes found in ${session}:${window}: ${pane_list//$'
'/ }"

    # Process each pane
    while IFS= read -r pane_id; do
        # Check if this pane ID should be skipped
        local skip=0
        for skip_id in "${skip_id_array[@]}"; do
            if [[ "${pane_id}" == "${skip_id}" ]]; then
                msg_debug "Skipping pane ${pane_id} as requested"
                skip=1
                break
            fi
        done
        
        if [[ "${skip}" -eq 0 ]]; then
            msg_debug "Executing command in pane ${pane_id}"
            # Pass the ID directly to tmx_execute_in_pane
            tmx_execute_in_pane "${session}" "${pane_id}" "${cmd}"
        fi
    done <<< "${pane_list}"
    
    return 0
}

# Check if a tmux session exists
# Arguments:
#   $1: Session name
# Returns: 0 if session exists, 1 otherwise
tmx_session_exists() {
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
tmx_create_window() {
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
        msg_error "Failed to create new window in session '${session}'"
        return 1
    fi
}

# Close a tmux session and clean up its resources
tmx_close_session() {
    local session="${1}"
    
    if [[ -z "${session}" ]]; then
        msg_error "Close session failed: No session name provided"
        return 1
    fi
    
    # Clean up temp scripts associated with this session
    if [[ -n "${TMX_SESSION_TEMPS[${session}]:-}" ]]; then
        msg_debug "Cleaning up temp files for session ${session}"
        for tmp_file in ${TMX_SESSION_TEMPS[${session}]}; do
            if [[ -f "${tmp_file}" ]]; then
                rm -f "${tmp_file}"
                msg_debug "Removed temp file: ${tmp_file}"
            fi
        done
        unset TMX_SESSION_TEMPS[${session}]
    fi
    
    # Kill the session
    if tmux has-session -t "${session}" 2>/dev/null; then
        tmux kill-session -t "${session}" 2>/dev/null
        msg_info "Closed session: ${session}"
        return 0
    else
        msg_debug "Session not found (already closed?): ${session}"
        return 1
    fi
}

# Cleanup all sessions and their resources
tmx_cleanup_all() {
    msg_debug "Cleaning up all tracked tmux sessions and resources"
    
    # Get all sessions managed by us
    local sessions=()
    # Safety check for array existence
    if [[ -v TMX_SESSION_TEMPS ]]; then
        for session in "${!TMX_SESSION_TEMPS[@]}"; do
            # Skip empty session names
            if [[ -n "$session" ]]; then
                sessions+=("${session}")
            fi
        done
        
        # Close each session
        for session in "${sessions[@]}"; do
            tmx_close_session "${session}"
        done
        
        # Clean up any remaining temp files
        for session_temps in "${TMX_SESSION_TEMPS[@]}"; do
            for tmp_file in ${session_temps}; do
                if [[ -f "${tmp_file}" ]]; then
                    rm -f "${tmp_file}"
                    msg_debug "Removed orphaned temp file: ${tmp_file}"
                fi
            done
        done
        
        # Clear the tracking array
        TMX_SESSION_TEMPS=()
    else
        msg_debug "TMX_SESSION_TEMPS array not initialized, nothing to clean up"
    fi
    
    return 0
}

# Set up cleanup on script exit
# trap 'tmx_cleanup_all' EXIT HUP INT QUIT TERM

# Execute a script defined in a function
# Arguments:
#   $1: Session name
#   $2: Pane index or pane ID (%ID format)
#   $3: Function name to execute
#   $4: Space-separated list of variables to export (optional)
# Example:
#   my_script() { echo "echo 'Hello world'"; }
#   tmx_execute_function "my_session" 0 my_script "VAR1 VAR2"
tmx_execute_function() {
    local session="${1}"
    local pane_input="${2}" # Original input (index or %ID)
    local func_name="${3}"
    local vars="${4:-}"
    local target_pane_id=""

    msg_debug "tmx_execute_function: session='${session}', pane_input='${pane_input}', func='${func_name}', vars='${vars:-none}'"

    # Determine the target pane ID
    if [[ "${pane_input}" =~ ^%[0-9]+$ ]]; then
        # Input is already a pane ID
        target_pane_id="${pane_input}"
        msg_debug "Using provided pane ID: ${target_pane_id}"
    elif [[ "${pane_input}" =~ ^[0-9]+$ ]]; then
        # Input is a pane index, convert to ID
        msg_debug "Input is pane index ${pane_input}, converting to ID..."
        target_pane_id=$(tmx_get_pane_id "${session}" "${pane_input}")
        if [[ -z "${target_pane_id}" ]]; then
            msg_error "Failed to find pane ID for index ${pane_input} in session ${session}"
            return 1
        fi
        msg_debug "Converted index ${pane_input} to pane ID: ${target_pane_id}"
    else
        msg_error "Invalid pane identifier: '${pane_input}'. Must be an index (e.g., 0) or ID (e.g., %1)."
        return 1
    fi

    # Use msg_debug for internal operation details
    msg_debug "Execute function '${func_name}' in pane ${target_pane_id} (vars: ${vars:-none})"

    # Check if function exists
    if ! declare -f "${func_name}" > /dev/null; then
        msg_error "Function '${func_name}' not found"
        return 1
    fi
    
    # Get script content from function
    local content
    content=$("${func_name}")
    
    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    # Check for empty session name to avoid bad array subscript error
    if [[ -n "${session}" ]]; then
        TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    else
        msg_warning "Empty session name provided for temp script tracking"
    fi
    
    # Generate script content using helper function
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${content}" "Script from function '${func_name}'" "${vars}")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script using the Pane ID
    msg_debug "Sending script ${tmp_script} to pane ${target_pane_id}"
    tmux send-keys -t "${target_pane_id}" "${tmp_script}" C-m

    local send_status=$?
    msg_debug "send-keys status for ${target_pane_id}: ${send_status}"
    return ${send_status}
}

# Load a script from a file and execute it in a pane
# Arguments:
#   $1: Session name
#   $2: Pane index or pane ID (%ID format)
#   $3: Script file path
#   $4: Space-separated list of variables to export (optional)
tmx_execute_file() {
    local session="${1}"
    local pane_input="${2}" # Original input (index or %ID)
    local script_file="${3}"
    local vars="${4:-}"
    local target_pane_id=""

    msg_debug "tmx_execute_file: session='${session}', pane_input='${pane_input}', file='${script_file}', vars='${vars:-none}'"

    # Determine the target pane ID
    if [[ "${pane_input}" =~ ^%[0-9]+$ ]]; then
        # Input is already a pane ID
        target_pane_id="${pane_input}"
        msg_debug "Using provided pane ID: ${target_pane_id}"
    elif [[ "${pane_input}" =~ ^[0-9]+$ ]]; then
        # Input is a pane index, convert to ID
        msg_debug "Input is pane index ${pane_input}, converting to ID..."
        target_pane_id=$(tmx_get_pane_id "${session}" "${pane_input}")
        if [[ -z "${target_pane_id}" ]]; then
            msg_error "Failed to find pane ID for index ${pane_input} in session ${session}"
            return 1
        fi
        msg_debug "Converted index ${pane_input} to pane ID: ${target_pane_id}"
    else
        msg_error "Invalid pane identifier: '${pane_input}'. Must be an index (e.g., 0) or ID (e.g., %1)."
        return 1
    fi

    # Use msg_debug for internal operation details
    msg_debug "Execute file '${script_file}' in pane ${target_pane_id} (vars: ${vars:-none})"

    # Check if file exists
    if [[ ! -f "${script_file}" ]]; then
        msg_error "Script file '${script_file}' not found"
        return 1
    fi
    
    # Read script content from file
    local content
    content=$(<"${script_file}")
    
    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    # Check for empty session name to avoid bad array subscript error
    if [[ -n "${session}" ]]; then
        TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    else
        msg_warning "Empty session name provided for temp script tracking"
    fi
    
    # Generate script content using helper function
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${content}" "Script from file '${script_file}'" "${vars}")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
    # Wait for the file to be created on disk
    if ! _tmx_wait_for_file "${tmp_script}" "-f" "creation"; then
        return 1 # Error message handled by helper
    fi
    
    # Make script executable
    chmod +x "${tmp_script}"

    if ! _tmx_wait_for_file "${tmp_script}" "-x" "executable permission $tmp_script "; then
        return 1 # Error message handled by helper
    fi
    
    # Execute temporary script using the Pane ID
    msg_debug "Sending script ${tmp_script} to pane ${target_pane_id}"
    tmux send-keys -t "${target_pane_id}" "${tmp_script}" C-m

    local send_status=$?
    msg_debug "send-keys status for ${target_pane_id}: ${send_status}"
    return ${send_status}
}

# Execute a shell function directly (not as a string generator)
# This allows using normal shell functions in tmux panes
# Arguments:
#   $1: Session name
#   $2: Pane index or pane ID (%ID format)
#   $3: Shell function to execute (must be defined in the current shell)
#   $4: Space-separated list of variables to export (optional)
tmx_execute_shell_function() {
    local session="${1}"
    local pane_input="${2}" # Original input (index or %ID)
    local func_name="${3}"
    local vars="${4:-}"
    shift 4 # Shift off the first 4 args
    local func_args=("$@") # Remaining args are function args
    local target_pane_id=""

    msg_debug "tmx_execute_shell_function: session='${session}', pane_input='${pane_input}', func='${func_name}', vars='${vars:-none}'"
    # Print args separately to satisfy linter
    printf -v args_str '%q ' "${func_args[@]}"
    msg_debug "tmx_execute_shell_function: args=(${args_str})"

    # Determine the target pane ID
    if [[ "${pane_input}" =~ ^%[0-9]+$ ]]; then
        # Input is already a pane ID
        target_pane_id="${pane_input}"
        msg_debug "Using provided pane ID: ${target_pane_id}"
    elif [[ "${pane_input}" =~ ^[0-9]+$ ]]; then
        # Input is a pane index, convert to ID
        msg_debug "Input is pane index ${pane_input}, converting to ID..."
        target_pane_id=$(tmx_get_pane_id "${session}" "${pane_input}")
        if [[ -z "${target_pane_id}" ]]; then
            msg_error "Failed to find pane ID for index ${pane_input} in session ${session}"
            return 1
        fi
        msg_debug "Converted index ${pane_input} to pane ID: ${target_pane_id}"
    else
        msg_error "Invalid pane identifier: '${pane_input}'. Must be an index (e.g., 0) or ID (e.g., %1)."
        return 1
    fi

    # Use msg_debug for internal operation details
    msg_debug "Execute shell function '${func_name}' in pane ${target_pane_id} (vars: ${vars:-none}) (args: ${#func_args[@]})"

    # Export the function definition itself
    local func_def
    # Attempt to capture the function definition. Error out if it fails in the current context.
    if ! func_def=$(declare -f "${func_name}"); then
        msg_error "Failed to capture definition for shell function '${func_name}'. Is it defined and exported correctly in the calling scope?"
        return 1
    fi

    # Clean up any potentially malformed newlines or quotes in the function definition
    func_def=$(echo "${func_def}" | sed 's/^[[:space:]]*$//')
    
    msg_debug "tmx_execute_shell_function: Captured function definition for ${func_name}:\n${func_def}"

    # Also export definitions of helper functions needed by func_def
    local helper_defs
    # Ensure tmx_var_set and tmx_var_get are available before declaring them
    if ! declare -f tmx_var_set > /dev/null || ! declare -f tmx_var_get > /dev/null; then
      msg_error "Helper functions tmx_var_set/tmx_var_get not found in parent shell!"
      # Attempt to source tmux_utils1.sh directly as a fallback
      local current_script_path="$(readlink -f "${BASH_SOURCE[0]}")"
      local utils_path="$(dirname "${current_script_path}")/tmux_utils1.sh"
      if [[ -f "${utils_path}" ]]; then
          source "${utils_path}" || { msg_error "Fallback source failed for ${utils_path}"; return 1; }
      else
          msg_error "Could not find ${utils_path} for fallback source."; return 1;
      fi
      # Check again
      if ! declare -f tmx_var_set > /dev/null || ! declare -f tmx_var_get > /dev/null; then
           msg_error "Helper functions still not found after fallback source!"
           return 1
      fi
    fi
    helper_defs=$(declare -f tmx_var_set tmx_var_get)

    msg_debug "tmx_execute_shell_function: Helper definitions to include:\n${helper_defs}"

    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    # Check for empty session name to avoid bad array subscript error
    if [[ -n "${session}" ]]; then
        TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    else
        msg_warning "Empty session name provided for temp script tracking"
    fi
    
    # Simple invocation of the function without any explicit exit
    # Let tmx_generate_script_boilerplate handle the exit statement
    # local run_content="${func_name}"
    # Build the command string to run the function with args
    local args_string=""
    for arg in "${func_args[@]}"; do
        args_string+=$(printf '%q ' "$arg") # Quote each argument
    done
    local run_content="${func_name} ${args_string}" # This line replaces the simple func_name call
    
    # Combine helper and main function definitions with proper newlines
    local all_func_defs="${helper_defs}"$'\n'"${func_def}"

    # Generate main function script using the helper, including all function definitions
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${run_content}" "Shell function '${func_name}'" "${vars}" "${all_func_defs}")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
    # Wait for the file to be created on disk
    if ! _tmx_wait_for_file "${tmp_script}" "-f" "creation"; then
        return 1 # Error message handled by helper
    fi
    
    # Save debug copy if TMX_DEBUG_DIR is set
    if [[ -n "${TMX_DEBUG_DIR}" ]]; then
        # Create debug directory if it doesn't exist
        mkdir -p "${TMX_DEBUG_DIR}"
        
        # Get the target pane ID
        local debug_pane_id="${pane_input}" # Default to original input
        
        # If input was an index, convert it to ID format
        if [[ ! "${pane_input}" =~ ^%[0-9]+$ && "${pane_input}" =~ ^[0-9]+$ ]]; then
            # Convert index to ID using the target_pane_id that should be already resolved
            debug_pane_id="${target_pane_id}"
        fi
        
        # Create a timestamped debug copy with proper ID format
        local debug_file="${TMX_DEBUG_DIR}/${session}_${debug_pane_id}_${func_name}_$(date +%s).sh"
        cp "${tmp_script}" "${debug_file}"
        chmod +x "${debug_file}"

        # Verify the script for syntax errors
        if bash -n "${debug_file}" 2>/dev/null; then
            msg_debug "Saved debug script to: ${debug_file} (syntax OK)"
        else
            msg_warning "Saved debug script with syntax errors: ${debug_file}"
            # Log the syntax checking error
            bash -n "${debug_file}" 2>&1 | head -3 >> "${TMX_DEBUG_DIR}/syntax_errors.log"
        fi
    fi
    
    # --- BEGIN DEBUG_SUBSCRIPT INTERCEPTION ---
    # Check if DEBUG_SUBSCRIPT is set and matches the current function name
    if [[ -n "${DEBUG_SUBSCRIPT:-}" && "${DEBUG_SUBSCRIPT}" == "${func_name}" ]]; then
        # Debug log setup
        DEBUG_LOG="/tmp/debug_intercept.log"
        {
            echo "=== DEBUG INTERCEPTION LOG $(date) ==="
            echo "Function: ${func_name}"
            echo "Temp script: ${tmp_script}"
            echo "Current directory: $(pwd)"
        } > "$DEBUG_LOG"

        # Ensure we're using direct screen output (the default), not stdout
        export MSG_TO_STDOUT=0

        msg "" # Blank line
        msg_box "DEBUG INTERCEPT: Call to '${func_name}'" "${YELLOW}"
        msg_warning "Debugging requested for function: ${func_name}"
        msg_cyan "Temporary script generated at: ${tmp_script}"
        msg ""

        msg_bold "Option 1: Debug in Terminal with bashdb"
        msg_yellow "  bashdb ${tmp_script}"
        msg ""

        msg_bold "Option 2: Debug in Neovim with GdbStartBashDB"
        msg_yellow "  nvim -c ':GdbStartBashDB bashdb ${tmp_script}'"
        msg ""

        msg_warning "NOTE: The temporary script might be deleted when the main script exits."
        msg_warning "The main script is paused. Choose your debugging option:"
        msg ""

        # Force flush output buffer
        sync

        # Present options to user
        msg_bold "Enter your choice:"
        msg "  1 - Debug in external terminal (bashdb)"
        msg "  2 - Debug in Neovim (GdbStartBashDB)"
        msg "  q - Quit debugging (skip execution)"

        # Read user choice
        local choice
        read -r -p "Enter choice [1/2/q]: " choice </dev/tty

        case "${choice}" in
            1)
                msg_info "Preparing script ${tmp_script} for bashdb..."
                # Comment out problematic terminal control lines for bashdb
                sed -i -e 's/^\s*stty -echo/# stty -echo/g' \
                       -e 's/^\s*stty echo/# stty echo/g' \
                       -e 's/^\s*clear/# clear/g' "${tmp_script}"
                
                msg_info "Executing bashdb in target pane (${session}:0.${pane_input})..."
                local debug_cmd="bashdb $(printf '%q' "${tmp_script}")"
                msg_debug "DEBUG_SUBSCRIPT: Sending to pane ${target_pane_id}: ${debug_cmd}"
                tmux send-keys -t "${target_pane_id}" "${debug_cmd}" C-m
                return 0 # Signal successful interception, skip normal execution
                ;;
            2)
                msg_info "Executing nvim GdbStartBashDB in target pane (${session}:0.${pane_input})..."
                # Ensure the nvim command is properly quoted for send-keys
                local nvim_cmd="nvim -c ':GdbStartBashDB bashdb $(printf '%q' "${tmp_script}")'"
                msg_debug "DEBUG_SUBSCRIPT: Sending to pane ${target_pane_id}: ${nvim_cmd}"
                tmux send-keys -t "${target_pane_id}" "${nvim_cmd}" C-m
                return 0 # Signal successful interception, skip normal execution
                ;;
            q|Q|*)
                msg_warning "Debugging canceled. Skipping execution."
                return 1 # Skip execution and signal error/cancel
                ;;
        esac

        # Only reached if the case statement somehow fails to match, which shouldn't happen
        msg "" # Add newline after read
    fi
    # --- END DEBUG_SUBSCRIPT INTERCEPTION ---
    
    # Normal execution continues from here

    if ! _tmx_wait_for_file "${tmp_script}" "-f" "before executable permission"; then
        return 1 # Error message handled by helper
    fi
    
    # Make script executable
    chmod +x "${tmp_script}"

    # Wait for the executable permission to be set
    if ! _tmx_wait_for_file "${tmp_script}" "-x" "executable permission"; then
        return 1 # Error message handled by helper
    fi

    # Execute temporary script using explicit bash invocation
    local send_cmd="bash $(printf '%q' "${tmp_script}")"
    # Use bash explicitly to ensure consistent environment
    msg_debug "Executing in pane ${target_pane_id} via send-keys: ${send_cmd}"
    tmux send-keys -t "${target_pane_id}" "${send_cmd}" C-m
    
    local send_status=$?
    msg_debug "send-keys status for ${target_pane_id}: ${send_status}"
    return ${send_status}
}

# Handle duplicate session names
# Arguments:
#   $1: Session name
# Sets global variable CHOSEN_SESSION_NAME:
#   - Original session name if user chooses to force close existing session or if it didn't exist
#   - New incremented session name if user chooses to use a new name
#   - Empty string if user chooses to exit
tmx_handle_duplicate_session() {
    local session_name="${1}"
    CHOSEN_SESSION_NAME="" # Reset global variable
    
    # Check if session exists
    if ! tmux has-session -t "${session_name}" 2>/dev/null; then
        # Session doesn't exist, set original name and return
        CHOSEN_SESSION_NAME="${session_name}"
        return 0
    fi
    
    # Session exists, offer options using msg_* functions
    msg "" # Add a newline
    msg_section "ATTENTION: Session '${session_name}' already exists!" 52 "="
    msg "Choose an option:"
    msg "  1. Force close existing session and create new one"
    msg "  2. Create new session with incremented name"
    msg "  3. Exit without creating a session"
    msg ""
    
    local choice
    # Use prompt_input for getting the choice, though read is also fine here
    # For simplicity and direct control over timeout, sticking with read but using msg_ for prompt
    msg_bold "$(msg_yellow "> Enter choice [1-3] (default: 2): ")"
    # Add timeout to avoid hanging indefinitely (10 seconds)
    read -r -t 10 choice || choice=2
    
    # Add newline after prompt
    msg ""
    
    # Handle timeout - default to option 2
    if [[ -z "${choice}" ]]; then
        choice=2
        msg_info "Timeout or empty input - using option 2 (create new session with incremented name)"
    fi
    
    case "${choice}" in
        1)
            # Kill existing session
            msg_info "Closing existing session '${session_name}'..."
            tmux kill-session -t "${session_name}" 2>/dev/null
            CHOSEN_SESSION_NAME="${session_name}"
            ;;
        2)
            # Find an available incremented name
            local i=1
            local new_name
            while true; do
                new_name="${session_name}_${i}"
                if ! tmux has-session -t "${new_name}" 2>/dev/null; then
                    msg_success "Using new session name: ${new_name}"
                    CHOSEN_SESSION_NAME="${new_name}"
                    break
                fi
                i=$((i + 1))
            done
            ;;
        3)
            # Exit - Set global variable to empty
            msg_warning "Exiting without creating a session."
            CHOSEN_SESSION_NAME=""
            ;;
        *)
            # Invalid choice - default to option 2
            msg_warning "Invalid choice - using option 2 (create new session with incremented name)"
            local i=1
            local new_name
            while true; do
                new_name="${session_name}_${i}"
                if ! tmux has-session -t "${new_name}" 2>/dev/null; then
                    msg_success "Using new session name: ${new_name}"
                    CHOSEN_SESSION_NAME="${new_name}"
                    break
                fi
                i=$((i + 1))
            done
            ;;
    esac
}

# Create a tmux session with duplicate handling
# Arguments:
#   $1: Base session name
#   $2: Launch terminal flag (optional, default: true)
# Returns:
#   - 0 on success
#   - 1 if user chose to exit or creation failed
# Sets global SESSION_NAME on success
tmx_create_session_with_handling() {
    local base_session_name="${1}"
    local launch_terminal="${2:-true}"
    
    # Handle duplicate session name interactively
    tmx_handle_duplicate_session "${base_session_name}"

    # Use the session name chosen by the user (stored in global variable)
    local session_name="${CHOSEN_SESSION_NAME}"
    
    # Check if user decided to exit (empty global variable)
    if [[ -z "${session_name}" ]]; then
        return 1 # User chose to exit
    fi
    
    # Create the session. tmx_create_session sets the global SESSION_NAME
    if ! tmx_create_session "${session_name}" "${launch_terminal}"; then
        msg_debug "Session creation failed in tmx_create_session"
        return 1 # Creation failed
    fi
    
    # Session created successfully, SESSION_NAME is set globally
    return 0
}

# Create a tmux session with initial variables set
# Arguments:
#   $1: Session name
#   $2: Variable names array (passed by name reference)
#   $3: Initial value for variables (optional, default: 0)
#   $4: Launch terminal flag (optional, default: true)
# Returns: 0 on success, 1 on failure
# Sets TMX_SESSION_NAME with the created session name
tmx_create_session_with_vars() {
    local session_name="${1}"
    local -n array_ref="${2}"  # Renamed from var_array_ref to avoid circular reference
    local initial_value="${3:-0}"
    local launch_terminal="${4:-true}"
    
    # Check if session already exists
    if tmux has-session -t "${session_name}" 2>/dev/null; then
        msg_error "Session '${session_name}' already exists"
        return 1
    fi
    
    # Create the session first
    if ! tmx_create_session "${session_name}" "${launch_terminal}"; then
        msg_error "Failed to create session with name '${session_name}'"
        return 1
    fi
    
    # Session name will be the same as input since we don't handle duplicates
    msg_debug "Session created successfully with name: ${session_name}"
    
    # Initialize variables for this session
    if ! tmx_init_vars_array array_ref "${initial_value}" "${session_name}"; then
        msg_warning "Some variables failed to initialize for session '${session_name}'"
        # Continue anyway as the session was created successfully
    fi
    
    msg_debug "Variables initialized for session '${session_name}'"
    
    return 0
}

# ======== TMUX ENVIRONMENT VARIABLE HELPERS ========

# Internal helper: Wait for a file condition with timeout
# Arguments:
#   $1: File path
#   $2: Check condition (e.g., "-f" for exists, "-x" for executable)
#   $3: Description for error message (e.g., "creation", "executable permission")
# Returns: 0 on success, 1 on timeout
_tmx_wait_for_file() {
    local file_path="${1}"
    local condition="${2}"
    local description="${3:-file condition}"
    local timeout=10  # Maximum seconds to wait
    local interval=0.1  # Check interval in seconds
    local elapsed=0
    
    msg_debug "Waiting for file '${file_path}' condition '${condition}'..."
    
    while (( $(echo "$elapsed < $timeout" | bc -l) )); do
        if test "${condition}" "${file_path}" 2>/dev/null; then
            msg_debug "File '${file_path}' condition '${condition}' met after ${elapsed}/${timeout} seconds."
            return 0
        fi
        sleep ${interval}
        elapsed=$(echo "$elapsed + $interval" | bc -l)
    done
    
    msg_error "Timeout waiting for ${description} (${condition}): '${file_path}'"
    return 1
}

# Set a tmux environment variable (global or session-specific) -> MOVED to tmux_base_utils.sh
# tmx_var_set() { ... }

# Get a tmux environment variable (global or session-specific) -> MOVED to tmux_base_utils.sh
# tmx_var_get() { ... }

# Initialize multiple tmux environment variables from an array
# Arguments:
#   $1: Name of the bash array containing variable names (passed by name reference)
#   $2: Default value for initialization (optional, defaults to 0)
#   $3: Target session name (optional, defaults to global)
tmx_init_vars_array() {
    local -n var_array_ref="$1" # Use nameref to get the array
    local default_value="${2:-0}"
    local target_session="${3:-}"
    local var_name
    local result=0 # Track overall success

    msg_debug "Initializing tmux vars from array '${1}' with default '${default_value}' for session '${target_session:-global}'"

    for var_name in "${var_array_ref[@]}"; do
        if ! tmx_var_set "${var_name}" "${default_value}" "${target_session}"; then
            msg_warning "Failed to initialize tmux variable: ${var_name}"
            result=1 # Mark failure if any variable fails
        fi
    done

    return ${result}
}

# Create a control pane in the given session to monitor variables and control other panes
# Arguments:
#   $1: Session name
#   $2: Variable names to monitor (space-separated string)
#   $3: Pane indices to control (space-separated string)
#   $4: Refresh rate in seconds (optional, default: 1)
#   $5: Target pane index/ID (optional, default: 0 - use the first pane)
# Returns: The pane ID of the control pane
tmx_control_pane() {
    local session="${1}"
    local vars="${2}"
    local panes="${3}"
    local refresh_rate="${4:-1}"
    local target_pane="${5:-0}"  # Default to using pane 0
    
    msg_debug "Creating control pane in session '${session}', target: ${target_pane}"
    
    local control_pane_id=""
    
    # Check if target_pane is already a pane ID
    if [[ "${target_pane}" =~ ^%[0-9]+$ ]]; then
        # Use the provided pane ID
        control_pane_id="${target_pane}"
        msg_debug "Using provided pane ID: ${control_pane_id}"
    elif [[ "${target_pane}" =~ ^[0-9]+$ ]]; then
        # Convert index to pane ID
        control_pane_id=$(tmx_get_pane_id "${session}" "${target_pane}")
        if [[ -z "${control_pane_id}" ]]; then
            msg_warning "Could not find pane with index ${target_pane}, creating new pane"
            # Create a new horizontal pane as fallback with control title
            control_pane_id=$(tmx_create_pane "${session}" "h")
        else
            msg_debug "Using pane with index ${target_pane}, ID: ${control_pane_id}"
        fi
    else
        # Invalid target, create a new pane with title
        msg_warning "Invalid target pane '${target_pane}', creating new pane"
        control_pane_id=$(tmx_create_pane "${session}" "h")
    fi
    
    if [[ -z "${control_pane_id}" ]]; then
        msg_error "Failed to get or create control pane in session '${session}'"
        return 1
    fi
    
    # Set the title for the control pane using our dedicated function
    local control_title="L:Control | F:control_function | btn:0"
    tmx_set_pane_title "${session}" "${control_pane_id}" "${control_title}"
    
    msg_debug "Control pane ID: ${control_pane_id}"
    
    # Set control pane ID in environment for access by other functions
    tmx_var_set "pane_id_0" "${control_pane_id}" "${session}"
    tmx_var_set "pane_label_0" "Control" "${session}"
    tmx_var_set "pane_func_0" "control_function" "${session}"
    
    # Execute the control function in the pane
    if ! tmx_execute_shell_function "${session}" "${control_pane_id}" "control_function" "" "${vars}" "${panes}" "${session}" "${refresh_rate}"; then
        msg_error "Failed to initialize control function in pane ${control_pane_id}"
        return 1
    fi
    
    # Return the pane ID
    echo "${control_pane_id}"
    return 0
}

# Define the control function (moved from tmx_control_pane)
control_function() {
    # Variables to monitor and panes to control
    local vars="$1"
    local panes="$2"
    local session="$3"
    local refresh_rate="$4"

    # Debug the received parameters using msg_debug
    msg_debug "Control function started with:"
    msg_debug "- Variables to monitor: ${vars}"
    msg_debug "- Pane indices to control: ${panes}" # Note: control_function still takes indices
    msg_debug "- Session: ${session}"
    msg_debug "- Refresh rate: ${refresh_rate}"
    
    # Convert space-separated strings into arrays
    read -ra VAR_ARRAY <<< "$vars"
    read -ra PANE_ARRAY <<< "$panes"
    msg_debug "control_function: VAR_ARRAY size=${#VAR_ARRAY[@]}"
    msg_debug "control_function: PANE_ARRAY size=${#PANE_ARRAY[@]}"
    
    # Check for pane ID variables - typically stored as pane_id_1, pane_id_2, etc.
    local -A PANE_ID_MAP=()
    
    # Even if no panes were passed, we can discover them from variables
    if [[ ${#PANE_ARRAY[@]} -eq 0 ]]; then
        msg_debug "control_function: No panes passed explicitly, looking for pane IDs in variables"
        # Look through variables for pane_id_X and use those indices
        for var in "${VAR_ARRAY[@]}"; do
            if [[ "$var" == pane_id_* ]]; then
                local index="${var##pane_id_}"
                # Add index to PANE_ARRAY if not already there
                local already_added=0
                for p in "${PANE_ARRAY[@]}"; do
                    if [[ "$p" == "$index" ]]; then
                        already_added=1
                        break
                    fi
                done
                if [[ $already_added -eq 0 ]]; then
                    PANE_ARRAY+=("$index")
                    msg_debug "control_function: Auto-added pane index $index from variable $var"
                fi
            fi
        done
        msg_debug "control_function: After auto-discovery, PANE_ARRAY size=${#PANE_ARRAY[@]}"
    fi
    
    # Map pane_id_X variables to their IDs
    for var in "${VAR_ARRAY[@]}"; do
        if [[ "$var" == pane_id_* ]]; then
            local index="${var##pane_id_}"
            local id_value=$(tmx_var_get "$var" "$session" 2>/dev/null)
            if [[ -n "$id_value" ]]; then
                PANE_ID_MAP["$index"]="$id_value"
                msg_debug "control_function: Found pane ID mapping: $index -> $id_value"
            fi
        fi
    done
    
    # Validate refresh_rate (default to 1 if empty or invalid)
    if [[ -z "${refresh_rate}" || ! "${refresh_rate}" =~ ^[0-9]+$ ]]; then
        msg_warning "WARNING: Invalid refresh rate '${refresh_rate}', using default of 1 second"
        refresh_rate=1
    fi
    
    # Initial Setup display using msg_*
    msg "=== TMUX CONTROL PANE ==="
    msg "Session: $session | Refresh: ${refresh_rate}s"
    msg "Controls: [q] Quit all | [r] Restart pane | [number] Close pane"
    msg_section "" 50 "-" # Use msg_section for divider
    
    # Enable special terminal handling for input
    stty -echo
    
    # Set the control pane title once before entering the loop
    local control_title="L:Control | F:control_function | btn:0"
    tmx_set_pane_title "${session}" "$(tmx_var_get "pane_id_0" "$session" 2>/dev/null)" "${control_title}"
    
    # Main control loop
    msg_debug "control_function: Entering main loop"
    while true; do
        # Trace loop execution
        msg_debug "control_function: Starting loop iteration at $(date '+%H:%M:%S.%3N')"
        
        # Robust screen clearing - try multiple methods to ensure it works
        msg_debug "control_function: Clearing screen..."
        clear                       # Standard clear command
        echo -ne "\033c"            # Reset terminal
        echo -ne "\033[2J\033[H"    # Clear and home cursor
        
        msg "=== TMUX CONTROL PANE ==="
        msg "Session: $session | Refresh: ${refresh_rate}s | $(date '+%H:%M:%S')"
        msg "Controls: [q] Quit all | [r] Restart pane | [number] Close pane"
        msg_section "" 50 "-"
        
        # Display variables
        msg_debug "control_function: Processing ${#VAR_ARRAY[@]} variables"
        msg_bold "= Variables ="
        for var in "${VAR_ARRAY[@]}"; do
            # Skip pane_id_* variables as they're used internally
            if [[ "$var" == pane_id_* ]]; then
                continue
            fi
            
            local value=$(tmx_var_get "$var" "$session" 2>/dev/null || echo "N/A")
            msg_debug "control_function: Variable '$var' = '$value'"
            
            # Choose color based on variable name (using existing msg_* colors)
            if [[ "$var" == *"green"* ]]; then
                msg_green "$var: $value"
            elif [[ "$var" == *"blue"* ]]; then
                msg_blue "$var: $value"
            elif [[ "$var" == *"red"* ]]; then
                msg_red "$var: $value"
            elif [[ "$var" == *"yellow"* ]]; then
                msg_yellow "$var: $value"
            else
                msg "$var: $value" # Use plain msg for default
            fi
        done
        
        # Display panes
        msg_debug "control_function: Checking pane status by direct ID lookup"
        msg_bold "= Panes ="
        
        # Get all actual pane IDs in the session
        local all_panes=$(tmux list-panes -t "${session}" -F "#{pane_id}")
        msg_debug "control_function: Available panes in session: ${all_panes}"
        
        # Check each button number's corresponding pane
        for button_num in {1..9}; do
            local pane_id=$(tmx_var_get "pane_id_${button_num}" "$session" 2>/dev/null)
            local pane_label=$(tmx_var_get "pane_label_${button_num}" "$session" 2>/dev/null)
            
            # Skip if no pane ID found for this button
            if [[ -z "$pane_id" ]]; then
                continue
            fi
            
            # Use default label if none was set
            if [[ -z "$pane_label" ]]; then
                pane_label="Pane ${button_num}"
            fi
            
            local pane_exists=0
            if echo "$all_panes" | grep -q "^${pane_id}$"; then
                pane_exists=1
                msg_debug "Found pane for button ${button_num}: ${pane_id} (${pane_label})"
            fi
            
            if [[ $pane_exists -eq 1 ]]; then
                msg_success "Pane ${button_num}: ${pane_label} (${pane_id}) - press ${button_num} to close"
            else
                msg_warning "Pane ${button_num}: ${pane_label} - Not running"
            fi
        done
        
        msg_debug "control_function: Finished checking pane statuses"
        msg_debug "control_function: Preparing for non-blocking read..."
        
        # Improved non-blocking input handling
        input=""
        read -t 0.1 -N 1 input </dev/tty || true
        
        if [[ -n "$input" ]]; then
            msg_debug "control_function: Received input: '$input'"
            case "$input" in
                q)
                    msg_debug "control_function: Quit command received"
                    msg_warning "Closing all panes and exiting..."
                    # Iterate downwards from 9 to 1
                    for ((button_num=9; button_num>=1; button_num--));
                    do
                        local pane_id=$(tmx_var_get "pane_id_${button_num}" "$session" 2> /dev/null)
                        local pane_label=$(tmx_var_get "pane_label_${button_num}" "$session" 2> /dev/null)
                        
                        if [[ -z "$pane_label" ]]; then
                            pane_label="Pane ${button_num}"
                        fi
                        
                        if [[ -n "$pane_id" ]]; then
                            msg_debug "control_function: Killing pane ${button_num} (${pane_label}) using ID ${pane_id}"
                            if tmx_kill_pane_by_id "$pane_id"; then
                                msg_success "Closed pane ${button_num}: ${pane_label} (ID: ${pane_id})"
                            else
                                msg_warning "Failed to close pane ${button_num}: ${pane_label} (ID: ${pane_id})"
                            fi
                            sleep 0.1
                        fi
                    done
                    msg_debug "control_function: Killing session ${session}"
                    ( tmux kill-session -t "$session" 2> /dev/null & )
                    msg_info "Exiting control function..."
                    trap '' INT TERM
                    exit 0
                ;;
                r)
                    msg_debug "control_function: Restart command received"
                    msg_yellow "Enter pane number to restart: "
                    read -n 1 button_num
                    msg ""
                    msg_debug "control_function: Button number to restart: '$button_num'"
                    if [[ "$button_num" =~ ^[0-9]+$ ]]; then
                        local pane_id=$(tmx_var_get "pane_id_${button_num}" "$session" 2> /dev/null)
                        local pane_label=$(tmx_var_get "pane_label_${button_num}" "$session" 2> /dev/null)
                        
                        if [[ -z "$pane_label" ]]; then
                            pane_label="Pane ${button_num}"
                        fi
                        
                        if [[ -n "$pane_id" ]]; then
                            msg_debug "control_function: Found pane ID ${pane_id} (${pane_label}) for button ${button_num}"
                            msg_warning "Restart functionality requires customization for pane: ${pane_label}"
                        else
                            msg_error "No pane ID found for button ${button_num}"
                        fi
                    else
                        msg_error "Invalid input: Enter a valid pane number."
                    fi
                    sleep 1
                ;;
                [0-9])
                    local button_num="$input"
                    msg_debug "control_function: Close pane command received for button: $button_num"
                    local pane_id=$(tmx_var_get "pane_id_${button_num}" "$session" 2> /dev/null)
                    local pane_label=$(tmx_var_get "pane_label_${button_num}" "$session" 2> /dev/null)
                    
                    if [[ -z "$pane_label" ]]; then
                        pane_label="Pane ${button_num}"
                    fi
                    
                    if [[ -n "$pane_id" ]]; then
                        msg_debug "control_function: Found pane ID ${pane_id} (${pane_label}) for button ${button_num}"
                        if tmx_kill_pane_by_id "$pane_id"; then
                            msg_success "Closed pane ${button_num}: ${pane_label} (ID: ${pane_id})"
                            
                            # Force immediate refresh of UI 
                            clear
                            continue
                        else
                            msg_warning "Failed to close pane ${button_num}: ${pane_label} (ID: ${pane_id})"
                        fi
                    else
                        msg_error "No pane ID found for button ${button_num}"
                    fi
                ;;
                *)
                    msg_debug "Ignoring unexpected input: $input"
                ;;
            esac
        fi

        # Ensure terminal is cleared properly
        msg_debug "control_function: Sleeping for ${refresh_rate}s"
        sleep "$refresh_rate"
    done

    # Restore terminal settings
    stty echo
    msg_debug "control_function: Exiting"
}

# ======== TMUX PANE ID MANAGEMENT FUNCTIONS ========

# Kill a pane by its ID (stable, doesn't change when other panes are added/removed) -> MOVED to tmux_base_utils.sh
# tmx_kill_pane_by_id() { ... }

# Get pane ID for a specific pane index in a session -> MOVED to tmux_base_utils.sh
# tmx_get_pane_id() { ... }

# Create a new pane and execute a shell function in it
# Arguments:
#   $1: Session name
#   $2: Shell function to execute (must be defined in the current shell)
#   $3: Pane options:
#      - Integer: Use existing pane with this index
#      - %ID: Use existing pane with this ID
#      - "v": Create new vertical split pane
#      - "h": Create new horizontal split pane
#   $4: Space-separated list of variables to export (optional)
# Returns: The ID (%ID format) of the pane used
tmx_pane_function() {
    local session="${1}"
    local func_name="${2}"
    local pane_option="${3:-h}"  # Default to horizontal split
    local vars="${4:-}"
    shift 4 # Shift off the first 4 args
    local func_args=("$@") # Remaining args are function args
    local pane_id
    local created_new_pane=0 # Flag to indicate if we created a pane

    msg_debug "Executing ${func_name} in session=${session}, pane=${pane_option} (args: ${#func_args[@]})"

    # Check if pane_option is a number (existing pane index), %ID (existing pane ID), or split type
    if [[ "${pane_option}" =~ ^%[0-9]+$ ]]; then
        # Use existing pane with the given ID
        pane_id="${pane_option}"
        msg_debug "Using existing pane ID ${pane_id} in session ${session}"
    elif [[ "${pane_option}" =~ ^[0-9]+$ ]]; then
        # Convert index to pane ID for backward compatibility
        pane_id=$(tmx_get_pane_id "${session}" "${pane_option}")
        if [[ -z "${pane_id}" ]]; then
            msg_error "Failed to find pane ID for index ${pane_option} in session ${session}"
            return 1
        fi
        msg_debug "Converted index ${pane_option} to pane ID ${pane_id}"
    else
        # Create a new pane with specified split type and title
        if [[ "${pane_option}" != "h" && "${pane_option}" != "v" ]]; then
            msg_warning "Invalid split type: ${pane_option}. Using horizontal."
            pane_option="h"
        fi
        
        # Create a title for the new pane
        local pane_title="L:${func_name} | F:${func_name}"
        pane_id=$(tmx_create_pane "${session}" "${pane_option}" "${pane_title}")
        if [[ -z "${pane_id}" ]]; then
            msg_error "Failed to create new pane in session ${session}"
            return 1
        fi
        created_new_pane=1
        msg_debug "Created new ${pane_option} pane with ID ${pane_id} in session ${session}"
    fi
    
    # Execute the function in the selected pane
    msg_debug "Executing shell function '${func_name}' in target pane ID ${pane_id}"

    # Execute the shell function, passing the PANE ID directly
    if ! tmx_execute_shell_function "${session}" "${pane_id}" "${func_name}" "${vars}" "${func_args[@]}"; then
        msg_error "Execution of '${func_name}' failed in pane ${pane_id}"
        # Optional: If we created this pane, kill it on failure?
        # if [[ "${created_new_pane}" -eq 1 ]]; then
        #     msg_warning "Killing pane ${pane_id} due to execution failure."
        #     tmx_kill_pane_by_id "${pane_id}"
        # fi
        return 1
    fi

    # Return the pane ID for future reference (stable identifier)
    echo "${pane_id}"
}

# Setup the first pane (pane 0) with a shell function
# RENAMED: Use tmx_pane_function with "0" as the pane option
tmx_first_pane_function() {
    local session="${1}"
    local func_name="${2}"
    local vars="${3:-}"
    shift 3 # Shift off the first 3 args
    local func_args=("$@") # Remaining args are function args
    
    msg_debug "tmx_first_pane_function: Targeting first pane (index 0) in session ${session}"

    # Get the ID of the first pane (index 0)
    local first_pane_id
    first_pane_id=$(tmx_get_pane_id "${session}" "0")
    if [[ -z "${first_pane_id}" ]]; then
        msg_error "Failed to find pane ID for index 0 in session ${session}. Cannot target first pane."
        return 1
    fi

    msg_debug "Found first pane ID: ${first_pane_id}"

    # Call the unified function using the retrieved Pane ID
    tmx_pane_function "${session}" "${func_name}" "${first_pane_id}" "${vars}" "${func_args[@]}"
}

# List all panes in a session with their IDs and indices
# Arguments:
#   $1: Session name
#   $2: Variable prefix for storing IDs (optional)
# Outputs: Debug information about all panes in the session
# Sets variables if prefix is provided:
#   - ${prefix}_COUNT: Number of panes
#   - ${prefix}_IDS: Space-separated list of pane IDs
#   - ${prefix}_INDICES: Space-separated list of pane indices
#   - ${prefix}_ID_1, ${prefix}_ID_2, etc.: Individual pane IDs
#   - ${prefix}_IDX_1, ${prefix}_IDX_2, etc.: Individual pane indices
tmx_list_session_panes() {
    local session="${1}"
    local var_prefix="${2:-}"
    
    # Get all panes in the session with their indices and IDs
    local pane_info
    pane_info=$(tmux list-panes -t "${session}" -F "#{pane_index} #{pane_id}")
    
    if [[ -z "${pane_info}" ]]; then
        msg_warning "No panes found in session '${session}'"
        return 1
    fi
    
    # Count the number of panes
    local pane_count
    pane_count=$(echo "${pane_info}" | wc -l)
    
    # Initialize arrays for IDs and indices
    local ids=()
    local indices=()
    
    # Debug information header
    msg_debug "===== Session '${session}' Panes (${pane_count} total) ====="
    
    # Process each pane
    local i=1
    while IFS=' ' read -r idx id; do
        msg_debug "Pane #${i}: Index=${idx}, ID=${id}"
        
        # Store in arrays
        ids+=("${id}")
        indices+=("${idx}")
        
        # Set individual variables if prefix is provided
        if [[ -n "${var_prefix}" ]]; then
            # Set individual ID and index variables
            local id_var="${var_prefix}_ID_${i}"
            local idx_var="${var_prefix}_IDX_${i}"
            
            # Use declare to create the variables in the parent scope
            declare -g "${id_var}=${id}"
            declare -g "${idx_var}=${idx}"
            
            # Store ID in tmux variable for persistence
            tmx_var_set "pane_id_${i}" "${id}" "${session}"
        fi
        
        i=$((i + 1))
    done <<< "${pane_info}"
    
    # Join arrays into space-separated strings
    local ids_str="${ids[*]}"
    local indices_str="${indices[*]}"
    
    # Set summary variables if prefix is provided
    if [[ -n "${var_prefix}" ]]; then
        declare -g "${var_prefix}_COUNT=${pane_count}"
        declare -g "${var_prefix}_IDS=${ids_str}"
        declare -g "${var_prefix}_INDICES=${indices_str}"
        
        msg_debug "${var_prefix}_COUNT = ${pane_count}"
        msg_debug "${var_prefix}_IDS = ${ids_str}"
        msg_debug "${var_prefix}_INDICES = ${indices_str}"
    fi
    
    # Return 0 for success
    return 0
}

# Create a monitoring control pane with simplified interface for applications
# Arguments:
#   $1: Session name
#   $2: Array name containing counter variables to monitor
#   $3: Variable prefix for storing IDs (optional)
#   $4: Refresh rate in seconds (optional, default: 1)
#   $5: Target pane index/ID (optional, default: 0 - use the first pane)
# Returns: The pane ID of the control pane
tmx_create_monitoring_control() {
    local session="${1}"
    local -n counter_vars_ref="${2}"  # Name reference to counter vars array
    local pane_ids_prefix="${3:-}"    # Prefix for pane ID variables (optional)
    local refresh_rate="${4:-1}"
    local target_pane="${5:-0}"  
    
    msg_debug "Creating monitoring control pane in session '${session}'"
    
    # Convert counter vars array to space-separated string
    local counter_vars_str=""
    for var in "${counter_vars_ref[@]}"; do
        counter_vars_str+="${var} "
    done
    
    # Get registered pane IDs from session variables (NOT relying on bash variables)
    local pane_id_vars=""
    local panes_to_control=""
    local i=1
    
    # Find all pane_id_X variables in session
    while true; do
        local id_value=$(tmx_var_get "pane_id_${i}" "${session}" 2>/dev/null)
        if [[ -z "${id_value}" ]]; then
            break  # No more pane IDs found
        fi
        
        # Add to variables to monitor
        pane_id_vars+="pane_id_${i} "
        
        # Add to panes to control
        panes_to_control+="${i} "
        
        i=$((i + 1))
    done
    
    # If no panes found but prefix is provided, try legacy method
    if [[ -z "${panes_to_control}" && -n "${pane_ids_prefix}" ]]; then
        # Legacy method using bash variables
        local count_var="${pane_ids_prefix}_COUNT"
        local pane_count="${!count_var:-0}"
        
        for ((i=1; i<=pane_count; i++)); do
            pane_id_vars+="pane_id_${i} "
        done
        
        # Use indices array from prefix
        local indices_var="${pane_ids_prefix}_INDICES"
        panes_to_control="${!indices_var:-}"
    fi
    
    # Combine all variables to monitor
    local all_vars="${counter_vars_str} ${pane_id_vars}"
    all_vars="${all_vars% }"  # Remove trailing space
    
    # Trim trailing space from panes_to_control
    panes_to_control="${panes_to_control% }"
    
    msg_debug "Monitoring variables: ${all_vars}"
    msg_debug "Controlling panes: ${panes_to_control}"
    
    # Call the control pane function with the prepared arguments
    local control_pane_id
    control_pane_id=$(tmx_control_pane "${session}" "${all_vars}" "${panes_to_control}" "${refresh_rate}" "${target_pane}")
    
    if [[ -n "${control_pane_id}" ]]; then
        # Register this as pane_id_0 if not already set
        if [[ -z "$(tmx_var_get "pane_id_0" "${session}" 2>/dev/null)" ]]; then
            tmx_var_set "pane_id_0" "${control_pane_id}" "${session}"
            tmx_var_set "pane_label_0" "Control" "${session}"
            tmx_var_set "pane_func_0" "control_function" "${session}"
            
            # Set a title for the control pane
            local pane_title="L:Control | F:control_function | btn:0"
            tmx_set_pane_title "${session}" "${control_pane_id}" "${pane_title}"
        fi
    fi
    
    # Return the control pane ID
    echo "${control_pane_id}"
    return 0
}

# Set up cleanup on script exit
# trap 'tmx_cleanup_all' EXIT HUP INT QUIT TERM

# Display session information with pane IDs in a formatted way
# Arguments:
#   $1: Session name
#   $2: Control pane ID
#   $3: Array of pane IDs with optional labels
#     Format: "pane_id:label pane_id:label ..."
#     Example: "%0:Main %1:Server %2:Client"
#   $4: Section width (optional, default: 60)
# Returns: 0 on success
tmx_display_session_info() {
    local session="${1}"
    local control_id="${2}"
    local pane_data="${3}"
    local width="${4:-60}"
    
    msg_section "Session Information" "${width}" "="
    echo "Session: ${session}"
    echo "Pane IDs (stable identifiers):"
    echo "  Control: ${control_id}"
    
    # Process pane data if provided
    if [[ -n "${pane_data}" ]]; then
        # Split the pane data string by spaces
        local panes=()
        read -ra panes <<< "${pane_data}"
        
        # Display each pane with its label
        for pane_info in "${panes[@]}"; do
            local id="${pane_info%%:*}"
            local label="${pane_info#*:}"
            
            # If no label was provided (no colon), use a default label
            if [[ "${id}" == "${label}" ]]; then
                label="Pane ${id}"
            fi
            
            echo "  ${label}:   ${id}"
        done
    fi
    
    msg_section "" "${width}" "="
    return 0
}

# Monitor a tmux session until it terminates
# Arguments:
#   $1: Session name
#   $2: Sleep interval in seconds (optional, default: 0.5)
#   $3: Message to display while monitoring (optional)
# Returns: 0 when session terminates normally, 1 on error
tmx_monitor_session() {
    local session="${1}"
    local interval="${2:-0.5}"
    local message="${3:-"Monitoring session ${session}... Press Ctrl+C to exit"}"
    
    # Set up signal handler for clean exit
    trap 'echo "Received interrupt signal, exiting..."; return 0' INT TERM
    
    # Display monitoring message
    msg_info "${message}"
    
    # Loop until the session is terminated
    while true; do
        # Check if session still exists
        if ! tmux has-session -t "${session}" 2>/dev/null; then
            msg_success "Session '${session}' was terminated, exiting..."
            break
        fi
        
        # Sleep to avoid excessive CPU usage
        sleep "${interval}"
    done
    
    return 0
}

# Register pane IDs and prepare control information
# Arguments:
#   $1: Session name
#   $2: Pane info array in format "id:label id:label" (e.g. "%1:Green %2:Blue")
#   $3: Variable prefix for storing IDs (e.g. "PANE")
# Sets in parent scope:
#   - ${PREFIX}_ID_N variables for each pane
#   - PANES_TO_CONTROL with indices for control
# Returns: 0 on success
tmx_register_panes() {
    local session="${1}"
    local pane_info="${2}"
    local prefix="${3:-PANE}"
    
    # Split pane info into array
    local panes=()
    read -ra panes <<< "${pane_info}"
    
    # List of pane indices for control functions
    local panes_to_control=""
    
    # Process each pane and create variables
    local i=1
    for pane_data in "${panes[@]}"; do
        # Extract pane ID and label
        local id="${pane_data%%:*}"
        local label="${pane_data#*:}"
        
        # If no label provided, use default
        if [[ "${id}" == "${label}" ]]; then
            label="Pane ${i}"
        fi
        
        # Set the ID variable in parent scope
        local id_var="${prefix}_ID_${i}"
        declare -g "${id_var}=${id}"
        
        # Add pane index to control list
        panes_to_control+="${i} "
        
        i=$((i + 1))
    done
    
    # Set global PANES_TO_CONTROL (trim trailing space)
    declare -g PANES_TO_CONTROL="${panes_to_control% }"
    
    return 0
}

# Display comprehensive session and pane information
# Arguments:
#   $1: Session name
#   $2: Control pane ID (optional, auto-detected if not provided)
#   $3: Variable prefix for storing IDs (optional, default: "PANE")
#   $4: Section width (optional, default: 60)
#   $5: Debug level (optional, default: 1 - normal debug, 2 - extended debug)
# Returns: 0 on success
tmx_display_info() {
    local session="${1}"
    local control_id="${2:-}"
    local prefix="${3:-PANE}"
    local width="${4:-60}"
    local debug_level="${5:-1}"
    
    # Validate session
    if [[ -z "${session}" ]]; then
        msg_error "No session name provided for tmx_display_info"
        return 1
    fi
    
    # Check if session exists
    if ! tmux has-session -t "${session}" 2>/dev/null; then
        msg_error "Session '${session}' does not exist"
        return 1
    fi
    
    # Auto-detect control pane ID if not provided
    if [[ -z "${control_id}" ]]; then
        control_id=$(tmux display-message -p -t "${session}:0.0" '#{pane_id}' 2>/dev/null)
        [[ -n "${control_id}" ]] && msg_debug "Auto-detected control pane ID: ${control_id}"
    fi
    
    # Get all panes in the session
    local pane_info=$(tmux list-panes -t "${session}" -F "#{pane_index} #{pane_id}")
    local pane_count=0
    
    if [[ -z "${pane_info}" ]]; then
        msg_warning "No panes found in session '${session}'"
    else
        # Count panes
        pane_count=$(echo "${pane_info}" | wc -l)
        msg_debug "Found ${pane_count} panes in session '${session}'"
        
        # Arrays for pane data
        local ids=()
        local indices=()
        
        # Process each pane and store its information
        local i=1
        while IFS=' ' read -r idx id; do
            # Store in arrays
            ids+=("${id}")
            indices+=("${idx}")
            
            # Set variables in parent scope
            local id_var="${prefix}_ID_${i}"
            local idx_var="${prefix}_IDX_${i}"
            
            declare -g "${id_var}=${id}"
            declare -g "${idx_var}=${idx}"
            
            # Store ID in tmux variable for persistence - BUT ONLY IF IT DOESN'T EXIST YET
            # This prevents overwriting existing pane registrations
            if [[ -z "$(tmx_var_get "pane_id_${i}" "${session}" 2>/dev/null)" ]]; then
                msg_debug "No existing pane registration for index ${i}, registering ID ${id}"
                tmx_var_set "pane_id_${i}" "${id}" "${session}"
            fi
            
            i=$((i + 1))
        done <<< "${pane_info}"
        
        # Set summary variables
        local ids_str="${ids[*]}"
        local indices_str="${indices[*]}"
        
        declare -g "${prefix}_COUNT=${pane_count}"
        declare -g "${prefix}_IDS=${ids_str}"
        declare -g "${prefix}_INDICES=${indices_str}"
        
        # Set PANES_TO_CONTROL if not already set
        if [[ -z "${PANES_TO_CONTROL}" ]]; then
            declare -g PANES_TO_CONTROL="${indices_str}"
        fi
        
        # Extended debug logging
        if [[ "${debug_level}" -ge 2 ]]; then
            msg_debug "${prefix}_COUNT = ${pane_count}"
            msg_debug "${prefix}_IDS = ${ids_str}"
            msg_debug "${prefix}_INDICES = ${indices_str}"
            msg_debug "PANES_TO_CONTROL = ${PANES_TO_CONTROL}"
        fi
    fi
    
    # Build pane data string with labels for display
    local pane_data=""
    
    # First try to use registered label variables
    local has_registered_labels=0
    
    # Check if any ID variables exist
    local id_var="${prefix}_ID_1"
    if [[ -v "${id_var}" ]]; then
        local i=1
        while true; do
            id_var="${prefix}_ID_${i}"
            local label_var="${prefix}_LABEL_${i}"
            
            # Break if no more IDs
            if [[ ! -v "${id_var}" ]]; then
                break
            fi
            
            local id="${!id_var}"
            
            # Get label (from variable or fallback to pane title)
            if [[ -v "${label_var}" ]]; then
                # Use registered label
                local label="${!label_var}"
                pane_data+="${id}:${label} "
                has_registered_labels=1
            else
                # Try to get title from tmux
                local pane_title
                pane_title=$(tmux display-message -p -t "${id}" '#{pane_title}' 2>/dev/null)
                
                if [[ -n "${pane_title}" && "${pane_title}" != "bash" && "${pane_title}" != "${SHELL##*/}" ]]; then
                    pane_data+="${id}:${pane_title} "
                else
                    pane_data+="${id}:Pane ${i} "
                fi
            fi
            
            i=$((i + 1))
        done
    elif [[ -n "${pane_info}" ]]; then
        # No registered variables, use raw pane list
        local i=1
        while IFS=' ' read -r idx id; do
            # Try to get pane title from tmux
            local pane_title
            pane_title=$(tmux display-message -p -t "${id}" '#{pane_title}' 2>/dev/null)
            
            if [[ -n "${pane_title}" && "${pane_title}" != "bash" && "${pane_title}" != "${SHELL##*/}" ]]; then
                pane_data+="${id}:${pane_title} "
            else
                pane_data+="${id}:Pane ${i} "
            fi
            
            i=$((i + 1))
        done <<< "${pane_info}"
    fi
    
    # Remove trailing space
    pane_data="${pane_data% }"
    
    # Extended debug logging
    if [[ "${debug_level}" -ge 2 ]]; then
        msg_debug "Session '${session}' detailed information:"
        msg_debug "Control pane ID: ${control_id}"
        msg_debug "Pane data: ${pane_data}"
        
        # Log all the variables we've set
        for ((j=1; ; j++)); do
            id_var="${prefix}_ID_${j}"
            if [[ -v "${id_var}" ]]; then
                msg_debug "${id_var}=${!id_var}"
            else
                break
            fi
        done
    fi
    
    # === Display formatted session information ===
    msg_section "Session Information" "${width}" "="
    msg "Session: ${session}"
    msg "Pane count: ${pane_count}"
    
    if [[ -n "${control_id}" ]]; then
        msg "Control pane: ${control_id}"
    fi
    
    # Display each pane with its label
    if [[ -n "${pane_data}" ]]; then
        msg_bold "Pane IDs (stable identifiers):"
        
        # Parse and display the pane data
        local panes=()
        read -ra panes <<< "${pane_data}"
        
        # Create a header for the detailed pane information
        msg_section "PANE DETAILS" "${width}" "-"
        msg_bold "BTN | PANE ID | INDEX | LABEL | FUNCTION | SCRIPT"
        msg_section "" "${width}" "-"
        
        for pane_entry in "${panes[@]}"; do
            local id="${pane_entry%%:*}"
            local label="${pane_entry#*:}"
            
            # Skip entries that aren't real pane IDs (temporary script paths, etc.)
            if [[ ! "${id}" =~ ^%[0-9]+$ ]]; then
                continue
            fi
            
            if [[ "${id}" == "${label}" ]]; then
                label="Pane ${id#%}"  # Default label if no colon
            fi
            
            # Try to get the pane index from tmux
            local pane_index=$(tmux list-panes -t "${session}" -F "#{pane_id} #{pane_index}" | grep "^${id} " | awk '{print $2}')
            
            # Try to find which button number corresponds to this pane ID
            local button_num=""
            
            # Find all pane_id variables in the session and check them
            local all_vars=$(tmux show-environment -t "${session}" | grep "^pane_id_" | grep "=${id}$")
            if [[ -n "${all_vars}" ]]; then
                button_num=$(echo "${all_vars}" | sed -n 's/^pane_id_\([0-9]*\)=.*/\1/p' | head -1)
                msg_debug "Found button ${button_num} for pane ${id}"
            fi
            
            # Try to get the function name and script path
            local func_name=""
            local script_info="-"
            
            if [[ -n "${button_num}" ]]; then
                # Get function name
                func_name=$(tmx_var_get "pane_func_${button_num}" "${session}" 2>/dev/null || echo "")
                
                # Get the stored label which would be more accurate
                local stored_label=$(tmx_var_get "pane_label_${button_num}" "${session}" 2>/dev/null)
                if [[ -n "${stored_label}" ]]; then
                    label="${stored_label}"
                fi
                
                # Get script path - check stored scripts first
                local stored_script=$(tmx_var_get "pane_script_${button_num}" "${session}" 2>/dev/null || echo "")
                
                # Debug logs for script detection
                msg_debug "Pane ${id} (btn=${button_num}): Script detection"
                msg_debug "  - Stored script path: '${stored_script}'"
                
                # Check if script exists in TMX_SESSION_TEMPS array
                if [[ -v TMX_SESSION_TEMPS && -n "${TMX_SESSION_TEMPS[${session}]:-}" ]]; then
                    msg_debug "  - Session temp files: ${TMX_SESSION_TEMPS[${session}]}"
                fi
                
                # Set script_info based on available data
                if [[ -n "${stored_script}" && -f "${stored_script}" ]]; then
                    script_info="$(basename "${stored_script}")"
                    msg_debug "  - Using stored script: ${script_info}"
                else
                    # Try multiple approaches to find the script
                    local pane_pid=$(tmux display-message -p -t "${id}" '#{pane_pid}' 2>/dev/null || echo "")
                    if [[ -n "${pane_pid}" ]]; then
                        msg_debug "  - Checking process ${pane_pid} for script path"
                        
                        # Try direct process command
                        local script_path=$(ps -p "${pane_pid}" -o args= 2>/dev/null | grep -o '/tmp/tmp\.[[:alnum:]]*' || echo "")
                        
                        # If not found, try child processes
                        if [[ -z "${script_path}" ]]; then
                            local child_pids=$(pgrep -P "${pane_pid}" 2>/dev/null)
                            for child in ${child_pids}; do
                                local child_cmd=$(ps -p "${child}" -o args= 2>/dev/null | grep -o '/tmp/tmp\.[[:alnum:]]*' || echo "")
                                if [[ -n "${child_cmd}" ]]; then
                                    script_path="${child_cmd}"
                                    msg_debug "  - Found script in child process ${child}: ${script_path}"
                                    break
                                fi
                            done
                        fi
                        
                        if [[ -n "${script_path}" ]]; then
                            script_info="$(basename "${script_path}")"
                            msg_debug "  - Found script in process: ${script_info}"
                        fi
                    fi
                fi
            fi
            
            # If this is the control pane, ensure it has a proper label and button
            if [[ "${id}" == "${control_id}" ]]; then
                # Set control pane label
                label="Control"
                
                # If button is not set, set it to 0
                if [[ -z "${button_num}" ]]; then
                    button_num="0"
                    tmx_var_set "pane_id_0" "${id}" "${session}" 
                    tmx_var_set "pane_label_0" "Control" "${session}"
                    tmx_var_set "pane_func_0" "control_function" "${session}"
                fi
                
                # Set control function
                func_name="${func_name:-control_function}"
                
                # Add control tag to script info
                if [[ "${script_info}" == "-" ]]; then
                    script_info="${script_info} (control)"
                else
                    script_info="${script_info} (control)"
                fi
                
                # Display in cyan for control pane
                msg_cyan " ${button_num} | ${id} | ${pane_index:-?} | ${label} | ${func_name} | ${script_info}"
            else
                # Display normal pane info
                msg " ${button_num:-?} | ${id} | ${pane_index:-?} | ${label} | ${func_name:-?} | ${script_info}"
            fi
        done
        
        msg_section "" "${width}" "-"
    fi
    
    msg_section "" "${width}" "="
    
    return 0
}

# Create a new pane and execute a shell function in it with auto-registration
# Arguments:
#   $1: Session name
#   $2: Label for the pane (e.g. "Green", "Blue")
#   $3: Shell function to execute (must be defined in the current shell)
#   $4: Pane options:
#      - Integer: Use existing pane with this index
#      - %ID: Use existing pane with this ID
#      - "v": Create new vertical split pane
#      - "h": Create new horizontal split pane
#   $5: Space-separated list of variables to export (optional)
#   $6: Variable prefix for storing IDs (optional, default: "PANE")
# Sets in parent scope:
#   - ${PREFIX}_ID_N variables for each pane
#   - Updates PANES_TO_CONTROL with indices for control
# Returns: The ID (%ID format) of the pane used
tmx_create_pane_func() {
    local session="${1}"
    local label="${2}"
    local func_name="${3}"
    local pane_option="${4:-h}"
    local vars="${5:-}"
    local prefix="${6:-PANE}"
    shift 6 # Shift off the first 6 args
    local func_args=("$@") # Remaining args are function args
    
    msg_debug "Creating pane '${label}' with function '${func_name}' in session '${session}'"
    
    # Find the next available index by checking tmux environment variables
    local next_index=1
    while true; do
        # Check if pane_id_X variable already exists in tmux environment
        local existing_id=$(tmx_var_get "pane_id_${next_index}" "${session}" 2>/dev/null)
        if [[ -z "${existing_id}" ]]; then
            # Found an available index
            break
        fi
        next_index=$((next_index + 1))
    done
    
    msg_debug "Using next available index: ${next_index} for pane '${label}'"
    
    # First determine if we're creating a new pane or using an existing one
    local create_new_pane=1
    if [[ "${pane_option}" =~ ^%[0-9]+$ || "${pane_option}" =~ ^[0-9]+$ ]]; then
        create_new_pane=0
    fi
    
    # Get the temp script file name (for title)
    local script_file=""
    
    # Create/prepare a title for the pane
    local pane_title="L:${label} | F:${func_name} | btn:${next_index}"
    
    # Create the pane and get its ID
    local pane_id
    
    if [[ ${create_new_pane} -eq 1 ]]; then
        # Create a new pane 
        pane_id=$(tmx_create_pane "${session}" "${pane_option}")
        
        # We need to execute the function in the new pane
        if [[ -n "${pane_id}" ]]; then
            msg_debug "Executing function '${func_name}' in newly created pane ${pane_id}"
            if ! tmx_execute_shell_function "${session}" "${pane_id}" "${func_name}" "${vars}" "${func_args[@]}"; then
                msg_error "Failed to execute '${func_name}' in pane ${pane_id}"
            fi
        fi
    else
        # Using existing pane - just get the ID without executing function
        if [[ "${pane_option}" =~ ^%[0-9]+$ ]]; then
            pane_id="${pane_option}"
        else
            pane_id=$(tmx_get_pane_id "${session}" "${pane_option}")
        fi
        
        # Execute the function in the existing pane
        if [[ -n "${pane_id}" ]]; then
            msg_debug "Executing function '${func_name}' in existing pane ${pane_id}"
            if ! tmx_execute_shell_function "${session}" "${pane_id}" "${func_name}" "${vars}" "${func_args[@]}"; then
                msg_error "Failed to execute '${func_name}' in pane ${pane_id}"
            fi
        fi
    fi
    
    if [[ -z "${pane_id}" ]]; then
        msg_error "Failed to create pane '${label}' in session '${session}'"
        return 1
    fi
    
    # Set the initial title for the pane
    tmx_set_pane_title "${session}" "${pane_id}" "${pane_title}"
    
    # Register the pane ID with label
    local id_var="${prefix}_ID_${next_index}"
    local label_var="${prefix}_LABEL_${next_index}"
    
    # Set variables in parent scope
    declare -g "${id_var}=${pane_id}"
    declare -g "${label_var}=${label}"
    
    # Update or initialize PANES_TO_CONTROL
    if [[ -v PANES_TO_CONTROL ]]; then
        declare -g PANES_TO_CONTROL="${PANES_TO_CONTROL} ${next_index}"
    else
        declare -g PANES_TO_CONTROL="${next_index}"
    fi
    
    # Set pane ID in tmux environment for persistence
    msg_debug "Registering pane '${label}' with ID ${pane_id} as PANE_ID_${next_index} (index ${next_index})"
    tmx_var_set "pane_id_${next_index}" "${pane_id}" "${session}"
    tmx_var_set "pane_label_${next_index}" "${label}" "${session}"
    
    # Also store the function name for better debugging
    tmx_var_set "pane_func_${next_index}" "${func_name}" "${session}"
    
    # Get the temp script file that was created for this pane
    # Check the TMX_SESSION_TEMPS array for the most recent temp file
    if [[ -n "${TMX_SESSION_TEMPS[${session}]:-}" ]]; then
        local script_files=(${TMX_SESSION_TEMPS[${session}]})
        local latest_script="${script_files[-1]}"
        if [[ -f "${latest_script}" ]]; then
            tmx_var_set "pane_script_${next_index}" "${latest_script}" "${session}"
            script_file="$(basename "${latest_script}")"
            msg_debug "Recorded script ${latest_script} for pane ${next_index}"
            
            # Update the pane title to include script info
            pane_title="L:${label} | F:${func_name} | SF:${script_file} | btn:${next_index}"
            
            # Set the updated title with script info
            tmx_set_pane_title "${session}" "${pane_id}" "${pane_title}"
        fi
    fi
    
    msg_debug "Registered pane '${label}' with ID ${pane_id} as PANE_ID_${next_index} (index ${next_index})"
    
    # Return the pane ID
    echo "${pane_id}"
    return 0
}

# Set title for a tmux pane using both ID and numeric addressing for reliability
# Arguments:
#   $1: Session name
#   $2: Pane identifier (can be ID like %1 or index like 0)
#   $3: Title text to set
# Returns: 0 on success, 1 on failure
tmx_set_pane_title() {
    local session="${1}"
    local pane_input="${2}"
    local title="${3}"
    local target_pane_id=""
    
    # Validate inputs
    if [[ -z "${session}" ]]; then
        msg_error "tmx_set_pane_title: Session name cannot be empty"
        return 1
    fi
    
    if [[ -z "${pane_input}" ]]; then
        msg_error "tmx_set_pane_title: Pane identifier cannot be empty"
        return 1
    fi
    
    if [[ -z "${title}" ]]; then
        msg_debug "tmx_set_pane_title: Empty title provided, using default"
        title="(untitled)"
    fi
    
    # Determine the target pane ID
    if [[ "${pane_input}" =~ ^%[0-9]+$ ]]; then
        # Input is already a pane ID
        target_pane_id="${pane_input}"
        msg_debug "Using provided pane ID: ${target_pane_id}"
    elif [[ "${pane_input}" =~ ^[0-9]+$ ]]; then
        # Input is a pane index, convert to ID for working with both methods
        target_pane_id=$(tmx_get_pane_id "${session}" "${pane_input}")
        if [[ -z "${target_pane_id}" ]]; then
            msg_error "Failed to find pane ID for index ${pane_input} in session ${session}"
            return 1
        fi
        msg_debug "Converted index ${pane_input} to pane ID: ${target_pane_id}"
    else
        msg_error "Invalid pane identifier: '${pane_input}'. Must be an index (e.g., 0) or ID (e.g., %1)."
        return 1
    fi
    
    # Give a moment for the pane to fully initialize if it's newly created
    sleep 0.1
    
    # Method 1: Set title using full session:window.pane target (most reliable)
    local full_target=""
    full_target=$(tmux display-message -p -t "${target_pane_id}" '#{session_name}:#{window_index}.#{pane_index}')
    
    if [[ -n "${full_target}" ]]; then
        msg_debug "Setting pane title with DIRECT command: tmux select-pane -t \"${full_target}\" -T \"${title}\""
        tmux select-pane -t "${full_target}" -T "${title}"
    else
        msg_warning "Could not determine full target path for pane ${target_pane_id}"
    fi
    
    # Method 2: Set title using numeric indices as fallback
    local pane_index=$(tmux display-message -p -t "${target_pane_id}" '#{pane_index}')
    
    if [[ -n "${pane_index}" ]]; then
        msg_debug "Setting title on pane index ${pane_index}: tmux select-pane -t \"${session}:0.${pane_index}\" -T \"${title}\""
        tmux select-pane -t "${session}:0.${pane_index}" -T "${title}"
    else
        msg_warning "Could not determine pane index for pane ${target_pane_id}"
    fi
    
    # Method 3: Set title directly on pane ID as last resort
    msg_debug "Setting title directly on pane ID: tmux select-pane -t \"${target_pane_id}\" -T \"${title}\""
    tmux select-pane -t "${target_pane_id}" -T "${title}"
    
    # Force a refresh of the tmux client to ensure title is displayed
    tmux refresh-client
    
    return 0
}

# Configure tmux to display pane titles in a session
# Arguments:
#   $1: Session name (optional, for current session if not provided)
#   $2: Position (optional, default: top)
# Returns: 0 on success, 1 on failure
tmx_enable_pane_titles() {
    local session="${1:-}"
    local position="${2:-top}"
    
    # Validate position - must be: top, bottom, or off
    if [[ "${position}" != "top" && "${position}" != "bottom" && "${position}" != "off" ]]; then
        msg_warning "Invalid pane title position: ${position}. Using 'top'."
        position="top"
    fi
    
    # If no session provided but we're in a tmux environment, try to get current session
    if [[ -z "${session}" && -n "${TMUX}" ]]; then
        session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
        msg_debug "No session specified, using current session: ${session}"
    fi
    
    # Set session-specific or global options
    if [[ -n "${session}" ]]; then
        # Check if session exists
        if ! tmux has-session -t "${session}" 2>/dev/null; then
            msg_error "Cannot enable pane titles: Session '${session}' does not exist"
            return 1
        fi
        
        # Set session-specific options
        msg_debug "Enabling pane titles in session '${session}' at position '${position}'"
        
        # Set the pane border status (top, bottom, or off)
        tmux set-option -t "${session}" pane-border-status "${position}"
        
        # Define the format of the pane border to show title
        tmux set-option -t "${session}" pane-border-format "#{pane_index}#{?pane_title,: #{pane_title},}"
        
        # Also enable pane border lines for a better visual
        tmux set-option -t "${session}" pane-border-lines single
    else
        # Set global options
        msg_debug "Enabling pane titles globally at position '${position}'"
        
        # Set the pane border status (top, bottom, or off)
        tmux set-option -g pane-border-status "${position}"
        
        # Define the format of the pane border to show title
        tmux set-option -g pane-border-format "#{pane_index}#{?pane_title,: #{pane_title},}"
        
        # Also enable pane border lines for a better visual
        tmux set-option -g pane-border-lines single
    fi
    
    # Force refresh to apply changes immediately
    tmux refresh-client
    
    return 0
}