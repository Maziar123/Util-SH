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
# Returns the session name on success, empty string on failure
tmx_create_session() {
    # Check if a session name was provided, otherwise generate one
    local session_name="${1:-session_$(date +%Y%m%d_%H%M%S)}"
    local launch_terminal="${2:-true}"
    
    # Handle case where launch_terminal is "--headless"
    if [[ "${launch_terminal}" == "--headless" ]]; then
        launch_terminal="false"
    fi
    
    msg_debug "Attempting to create session: ${session_name} (launch_terminal=${launch_terminal})"
    
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
    
    # Set global SESSION_NAME for use by calling script
    SESSION_NAME="${session_name}"
    
    # Return only the actual session name
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
    
    # Make script executable
    chmod +x "${tmp_script}"
    
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
    
    # Generate main function script using the helper, including helper functions
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${run_content}" "Shell function '${func_name}'" "${vars}" "${helper_defs}
${func_def}")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
    # Save debug copy if TMX_DEBUG_DIR is set
    if [[ -n "${TMX_DEBUG_DIR}" ]]; then
        # Create debug directory if it doesn't exist
        mkdir -p "${TMX_DEBUG_DIR}"
        
        # Create a timestamped debug copy with function name
        local debug_file="${TMX_DEBUG_DIR}/${session}_${pane_input}_${func_name}_$(date +%s).sh"
        cp "${tmp_script}" "${debug_file}"
        chmod +x "${debug_file}"
        
        # Get the target pane ID again just in case it wasn't set correctly above (shouldn't happen)
        # This uses pane_input which might be index or ID
        local debug_pane_target="${pane_input}" # Default to original input
        if [[ ! "${pane_input}" =~ ^%[0-9]+$ && "${pane_input}" =~ ^[0-9]+$ ]]; then
            # If input was index, use the resolved ID
            debug_pane_target="${target_pane_id}"
        fi

        # Sanitize pane ID for filename (% becomes _)
        local safe_pane_id="${debug_pane_target//%/}"
        local debug_file="${TMX_DEBUG_DIR}/${session}_pane${safe_pane_id}_${func_name}_$(date +%s).sh"
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
    
    # Make script executable
    chmod +x "${tmp_script}"
    
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
# Returns:
#   - 0 on success
#   - 1 if creation failed
# Sets global SESSION_NAME on success
tmx_create_session_with_vars() {
    local session_name="${1}"
    local -n array_ref="${2}"  # Renamed from var_array_ref to avoid circular reference
    local initial_value="${3:-0}"
    local launch_terminal="${4:-true}"
    
    # Create the session first
    if ! tmx_create_session_with_handling "${session_name}" "${launch_terminal}"; then
        msg_error "Failed to create session with name '${session_name}'"
        return 1
    fi
    
    # Get the actual session name from global variable
    session_name="${SESSION_NAME}"
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
            # Create a new horizontal pane as fallback
            control_pane_id=$(tmx_create_pane "${session}" "h")
        else
            msg_debug "Using pane with index ${target_pane}, ID: ${control_pane_id}"
        fi
    else
        # Invalid target, create a new pane
        msg_warning "Invalid target pane '${target_pane}', creating new pane"
        control_pane_id=$(tmx_create_pane "${session}" "h")
    fi
    
    if [[ -z "${control_pane_id}" ]]; then
        msg_error "Failed to get or create control pane in session '${session}'"
        return 1
    fi
    
    msg_debug "Control pane ID: ${control_pane_id}"
    
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
        msg_debug "control_function: Checking status of ${#PANE_ARRAY[@]} panes"
        msg_bold "= Panes ="
        
        # Get the list of all panes in the current session with their IDs for accurate detection
        local all_panes=$(tmux list-panes -t "${session}" -F "#{pane_index} #{pane_id}")
        msg_debug "control_function: Available panes in session: ${all_panes}"
        
        # Check current status of each tracked pane
        for pane_idx in "${PANE_ARRAY[@]}"; do
            # First look for the pane ID in our mapping
            local pane_id="${PANE_ID_MAP[$pane_idx]:-}"
            local pane_exists=0
            
            if [[ -n "$pane_id" ]]; then
                # Check if the pane ID exists using tmux has-session (more reliable)
                if tmux has-session -t "$pane_id" 2>/dev/null; then
                    pane_exists=1
                    msg_debug "control_function: Pane $pane_idx ($pane_id) EXISTS via ID check"
                else
                    # Double-check by scanning the pane list
                    if echo "${all_panes}" | grep -q " ${pane_id}$"; then
                        pane_exists=1
                        msg_debug "control_function: Pane $pane_idx ($pane_id) EXISTS via pane list grep"
                    fi
                fi
            else
                # If no ID mapping, fall back to index-based check
                if echo "${all_panes}" | grep -q "^${pane_idx} %"; then
                    pane_exists=1
                    # Extract the ID for future use
                    pane_id=$(echo "${all_panes}" | grep "^${pane_idx} %" | awk '{print $2}')
                    PANE_ID_MAP["$pane_idx"]="$pane_id"
                    msg_debug "control_function: Pane $pane_idx EXISTS with newly retrieved ID $pane_id"
                fi
            fi
            
            # Display status based on findings
            if [[ $pane_exists -eq 1 ]]; then
                msg_success "Pane ${pane_idx}: Running - press ${pane_idx} to close"
            else
                msg_warning "Pane ${pane_idx}: Not running"
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
                    msg_warning "Closing all panes and exiting..." # Use warning for quit action
                    
                    # First attempt to kill all managed panes using their IDs
                    for pane_idx in "${PANE_ARRAY[@]}"; do
                        local pane_id="${PANE_ID_MAP[$pane_idx]:-}"
                        if [[ -n "$pane_id" ]]; then
                            msg_debug "control_function: Killing pane $pane_idx using ID $pane_id"
                            if tmx_kill_pane_by_id "$pane_id"; then
                                msg_success "Closed pane $input using ID-based kill"
                                # Update the display immediately to reflect the change
                                sleep 1
                                continue
                            else
                                msg_warning "ID-based kill failed for pane $input ($pane_id), checking if already closed..."
                            fi
                        else
                            # If no ID found (e.g., pane_id_X var wasn't set), try to get ID from index now
                            msg_warning "control_function: No mapped ID for pane index $pane_idx, attempting lookup"
                            local fallback_id=$(tmx_get_pane_id "$session" "$pane_idx")
                            if [[ -n "$fallback_id" ]]; then
                                msg_debug "control_function: Found fallback ID ${fallback_id}, killing..."
                                tmx_kill_pane_by_id "$fallback_id"
                            else
                                msg_error "control_function: Cannot find ID for pane index $pane_idx to kill it."
                            fi
                        fi
                        # Add a small delay to allow tmux to process the kill
                        sleep 0.1
                    done
                    
                    # Send a direct kill-session command
                    msg_debug "control_function: Killing session ${session}"
                    # Force the kill-session command to complete before exiting
                    (tmux kill-session -t "$session" 2>/dev/null &)
                    
                    # Force exit of the control pane script
                    msg_info "Exiting control function..."
                    # Use a trap to ensure we exit properly
                    trap '' INT TERM
                    exit 0
                    ;;
                r)
                    msg_debug "control_function: Restart command received"
                    msg_yellow "Enter pane number to restart: " # Use yellow for prompt
                    read -n 1 pane_num
                    # Add a newline after read for better formatting
                    msg "" 
                    msg_debug "control_function: Pane number to restart: '$pane_num'"
                    if [[ "$pane_num" =~ ^[0-9]+$ ]]; then
                        # Check if pane_num is in the array using a loop instead of pattern matching
                        local pane_exists=0
                        for p in "${PANE_ARRAY[@]}"; do
                            if [[ "$p" == "$pane_num" ]]; then
                                pane_exists=1
                                break
                            fi
                        done

                        if [[ "$pane_exists" -eq 1 ]]; then
                            msg_debug "control_function: Found pane ${pane_num} in managed panes"
                            # Logic to restart a pane would go here
                            # This depends on how panes were originally launched
                            msg_warning "Restart functionality requires customization" # Use warning
                        else
                            msg_debug "control_function: Pane ${pane_num} not found in managed panes"
                            msg_error "Pane ${pane_num} is not managed by this control pane." # Error if invalid pane num
                        fi
                    else
                         msg_error "Invalid input: Enter a valid pane number." # Error if not a number
                    fi
                    sleep 1 # Pause briefly after input
                    ;;
                [0-9])
                    msg_debug "control_function: Close pane command received for pane: $input"
                    # Check if input is in the array using a loop
                    local pane_exists=0
                    for p in "${PANE_ARRAY[@]}"; do
                        msg_debug "control_function: Checking if pane '$p' matches target '$input'"
                        if [[ "$p" == "$input" ]]; then
                            pane_exists=1
                            msg_debug "control_function: FOUND pane $input in managed panes"
                            break
                        fi
                    done

                    if [[ "$pane_exists" -eq 1 ]]; then
                        # Get the pane ID for stable reference
                        local pane_id="${PANE_ID_MAP[$input]:-}"
                        msg_debug "control_function: Closing pane $input (ID: $pane_id)..."
                        msg_info "Closing pane $input..." 
                        
                        # Check if we have an ID to use
                        if [[ -n "$pane_id" ]]; then
                            # ID-based killing (preferred)
                            msg_debug "control_function: Killing via pane ID: $pane_id"
                            if tmx_kill_pane_by_id "$pane_id"; then
                                msg_success "Closed pane $input using ID-based kill"
                                # Update the display immediately to reflect the change
                                sleep 1
                                continue
                            else
                                msg_warning "ID-based kill failed for pane $input ($pane_id), checking if already closed..."
                            fi
                        else
                            msg_debug "control_function: No ID found for pane $input"
                        fi
                        
                        # If ID-based kill failed or ID wasn't found, check if pane still exists by index
                        msg_debug "control_function: Re-checking if pane index $input still exists..."
                        local current_panes=$(tmux list-panes -t "${session}" -F "#{pane_index}")
                        if echo "${current_panes}" | grep -q "^${input}$"; then
                            msg_error "Failed to close pane $input (index exists, but kill failed)."
                        else
                            msg_warning "Pane $input seems to be already closed (index not found)."
                            # Force a screen refresh
                            sleep 0.5 # Short pause before continuing loop
                            continue
                        fi

                    else
                        msg_debug "control_function: Pane $input not found in managed panes"
                        msg_error "Pane $input is not managed by this control pane."
                        sleep 1
                    fi
                    ;;
                *)
                    # Ignore any other input
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
        # Create a new pane with specified split type
        if [[ "${pane_option}" != "h" && "${pane_option}" != "v" ]]; then
            msg_warning "Invalid split type: ${pane_option}. Using horizontal."
            pane_option="h"
        fi
        pane_id=$(tmx_create_pane "${session}" "${pane_option}")
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