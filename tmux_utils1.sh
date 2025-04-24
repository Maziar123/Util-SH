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

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    sh-globals_init "$@"
fi

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

# Array to track temporary scripts for each session
declare -A TMX_SESSION_TEMPS=()

# Global variable to hold the result of handle_duplicate_session
CHOSEN_SESSION_NAME=""

# Global variables for session confirmation
TMX_SESSION_CONFIRM_COLOR="${GREEN}"  # Default confirmation color
TMX_SESSION_CONFIRM_TIME=1            # Default display time in seconds

# Add a debug directory setting for script debugging
TMX_DEBUG_DIR="${TMX_DEBUG_DIR:-}"  # Directory to save debug scripts, if set

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

# Helper function to generate common script boilerplate
# Arguments:
#   $1: Script content (the actual commands to run after the boilerplate)
#   $2: Content description (for comments)
#   $3: Space-separated list of variables to export (optional)
#   $4: Extra helper functions to include (optional)
# Returns: Complete script content as string
tmx_generate_script_boilerplate() {
    local content="${1}"
    local description="${2:-script}"
    local vars="${3:-}"
    local helper_functions="${4:-}"
    
    # Get absolute path to the project directory
    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    
    # Start building the script content
    local script_content
    script_content=$(cat <<EOF
#!/usr/bin/env bash

# Enable xtrace for detailed debugging within the pane
set -x

# Set up script environment
SCRIPT_DIR="$(printf '%q' "${script_dir}")"
export PATH="\${SCRIPT_DIR}:\${PATH}"
# Attempt to cd to script dir, continue if it fails
cd "\${SCRIPT_DIR}" || echo "WARNING: Could not cd to \${SCRIPT_DIR}"

EOF
    )
    
    # Add variable exports if any
    if [[ -n "${vars}" ]]; then
        # Add a newline before the comment
        script_content+=$'\n# Export variables from parent shell\n'
        for var in ${vars}; do
            # Get value and quote it properly for inclusion in the script
            local value="${!var}"
            script_content+=$(printf 'export %s=%q\n' "${var}" "${value}")
        done
        script_content+=$'\n'
    fi
    
    # Ensure a newline before the next block
    script_content+=$'\n'
    
    # Add sh-globals sourcing
    script_content+=$(cat <<EOF
echo "--- Sourcing sh-globals ---"
# Source sh-globals.sh (essential for colors/msg functions)
if [[ -f "${script_dir}/sh-globals.sh" ]]; then
    source "${script_dir}/sh-globals.sh" || { echo "ERROR: Failed to source sh-globals.sh"; exit 1; }
else
    echo "ERROR: sh-globals.sh not found at ${script_dir}/sh-globals.sh"; exit 1;
fi
echo "--- sh-globals sourced ---"

# Initialize globals
export DEBUG="${DEBUG:-0}"
sh-globals_init

# Define session self-destruct function
tmx_self_destruct() {
  local session_name=\$(tmux display-message -p '#S')
  msg_info "Closing session \${session_name}..."
  ( sleep 0.5; tmux kill-session -t "\${session_name}" ) &
}

EOF
    )
    
    # Add any helper functions if provided
    if [[ -n "${helper_functions}" ]]; then
        # Add a newline before the comment to ensure proper separation
        script_content+=$'\n# Include helper functions\n'
        script_content+="${helper_functions}"
        script_content+=$'\n\n'
    fi
    
    # Add user content with description - strip any existing exit commands
    # to prevent duplicate exits
    # local cleaned_content="${content/exit 0/}" # Don't strip exit anymore
    
    script_content+=$(cat <<EOF
# ${description} follows
echo "--- Executing main content --- "
${content}

# Add explicit exit to ensure clean termination
# exit 0 # Removed unconditional exit
EOF
    )
    
    # Return the generated script content
    echo "${script_content}"
}

# Execute a command in a specific tmux pane
# Arguments:
#   $1: Session name
#   $2: Pane index
#   $3: Command to execute (can be multi-line)
tmx_execute_in_pane() {
    local session="${1}"
    local pane="${2}" 
    local cmd="${3}"
    
    msg_debug "Exec in ${session}:${pane}: ${cmd}"
    
    # Create a temporary script to execute
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Generate script content using helper function
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${cmd}" "User command")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script
    tmux send-keys -t "${session}:0.${pane}" "${tmp_script}" C-m
    
    return $?
}

# Modern function to execute multi-line commands in tmux panes
# Uses heredoc for better readability
# Usage: tmx_execute_script SESSION PANE [VARS] <<'EOF'
#   commands here
#   more commands
# EOF
tmx_execute_script() {
    local session="${1}"
    local pane="${2}"
    local vars="${3:-}"  # Optional: variable names to export from current shell
    
    # Use msg_debug for internal operation details
    msg_debug "Execute script in ${session}:0.${pane} (vars: ${vars:-none})"
    
    # Read the script content from heredoc
    local content
    content=$(cat)
    
    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Generate script content using helper function
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${content}" "User script" "${vars}")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
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
#   $2: Pane index
#   $3: Text to send
tmx_send_text() {
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
tmx_execute_all_panes() {
    local session="${1}"
    local window="${2:-0}"
    local cmd="${3}"
    
    # Get all pane indexes in the window
    local panes
    panes=$(tmux list-panes -t "${session}:${window}" -F "#{pane_index}")
    
    # Execute command in each pane
    for pane in ${panes}; do
        tmx_execute_in_pane "${session}" "${pane}" "${cmd}"
    done
    
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
    for session in "${!TMX_SESSION_TEMPS[@]}"; do
        sessions+=("${session}")
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
    
    return 0
}

# Set up cleanup on script exit
trap 'tmx_cleanup_all' EXIT HUP INT QUIT TERM

# Execute a script defined in a function
# Arguments:
#   $1: Session name
#   $2: Pane index
#   $3: Function name to execute
#   $4: Space-separated list of variables to export (optional)
# Example:
#   my_script() { echo "echo 'Hello world'"; }
#   tmx_execute_function "my_session" 0 my_script "VAR1 VAR2"
tmx_execute_function() {
    local session="${1}"
    local pane="${2}"
    local func_name="${3}"
    local vars="${4:-}"
    
    # Use msg_debug for internal operation details
    msg_debug "Execute function '${func_name}' in ${session}:0.${pane} (vars: ${vars:-none})"
    
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
    TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Generate script content using helper function
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${content}" "Script from function '${func_name}'" "${vars}")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
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
tmx_execute_file() {
    local session="${1}"
    local pane="${2}"
    local script_file="${3}"
    local vars="${4:-}"
    
    # Use msg_debug for internal operation details
    msg_debug "Execute file '${script_file}' in ${session}:0.${pane} (vars: ${vars:-none})"
    
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
    TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
    # Generate script content using helper function
    local script_content
    script_content=$(tmx_generate_script_boilerplate "${content}" "Script from file '${script_file}'" "${vars}")
    
    # Write the script content to file
    echo "${script_content}" > "${tmp_script}"
    
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
tmx_execute_shell_function() {
    local session="${1}"
    local pane="${2}"
    local func_name="${3}"
    local vars="${4:-}"
    shift 4 # Shift off the first 4 args
    local func_args=("$@") # Remaining args are function args
    
    # Use msg_debug for internal operation details
    msg_debug "Execute shell function '${func_name}' in ${session}:0.${pane} (vars: ${vars:-none}) (args: ${#func_args[@]})"
    
    # Check if function exists
    if ! declare -f "${func_name}" > /dev/null; then
        msg_error "Shell function '${func_name}' not found"
        return 1
    fi
    
    # Export the function definition itself
    local func_def
    func_def=$(declare -f "${func_name}")
    
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

    # Create a temporary script
    local tmp_script
    tmp_script=$(mktemp)
    
    # Register this temp file with the session
    TMX_SESSION_TEMPS[${session}]="${TMX_SESSION_TEMPS[${session}]:-} ${tmp_script}"
    
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
        local debug_file="${TMX_DEBUG_DIR}/${session}_${pane}_${func_name}_$(date +%s).sh"
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
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script
    local send_cmd="bash $(printf '%q' "${tmp_script}")"
    # Use bash explicitly to ensure consistent environment
    msg_debug "Executing in pane ${session}:0.${pane} via send-keys: tmux send-keys -t \"${session}:0.${pane}\" \"${send_cmd}\" C-m"
    tmux send-keys -t "${session}:0.${pane}" "${send_cmd}" C-m
    
    return $?
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

# ======== TMUX ENVIRONMENT VARIABLE HELPERS ========

# Set a tmux environment variable (global or session-specific)
# Arguments:
#   $1: Variable name
#   $2: Variable value
#   $3: Target session name (optional, defaults to global)
tmx_var_set() {
    local var_name="${1}"
    local var_value="${2}"
    local target_session="${3:-}"
    local output
    if [[ -z "${var_name}" ]]; then
        msg_error "tmx_var_set: Variable name cannot be empty."
        return 1
    fi
    msg_debug "Setting tmux env var: ${var_name}=${var_value} in session '${target_session:-global}'"
    if [[ -n "${target_session}" ]]; then
        # Capture stderr (2>&1) and check return code
        if ! output=$(tmux set-environment -t "${target_session}" "${var_name}" "${var_value}" 2>&1); then 
            msg_error "tmx_var_set FAILED for '${var_name}=${var_value}' in session '${target_session}'. tmux output: ${output}"
            return 1
        fi
    else
        # Capture stderr (2>&1) and check return code
        if ! output=$(tmux set-environment -g "${var_name}" "${var_value}" 2>&1); then 
            msg_error "tmx_var_set FAILED for global '${var_name}=${var_value}'. tmux output: ${output}"
            return 1
    fi
    fi
    return 0
}

# Get a tmux environment variable (global or session-specific)
# Arguments:
#   $1: Variable name
#   $2: Target session name (optional, defaults to global)
# Returns: The value of the variable (echoed)
tmx_var_get() {
    local var_name="${1}"
    local target_session="${2:-}"
    local value=""
    local output # For capturing command output + stderr

    if [[ -z "${var_name}" ]]; then
        msg_error "tmx_var_get: Variable name cannot be empty."
        return 1
    fi

    # Handle session-specific or global variables
    if [[ -n "${target_session}" ]]; then
        # Capture stderr (2>&1) and check return code
        if ! output=$(tmux show-environment -t "${target_session}" "${var_name}" 2>&1); then
            # Check if the error is just 'unknown variable' (which means unset)
            if [[ "${output}" == *"unknown variable"* ]]; then
                msg_debug "tmx_var_get: Variable '${var_name}' not found/unset in session '${target_session}'"
                echo "" # Echo nothing for unset
                return 0 # Return success for unset variable
            else
                # Log other errors
                msg_error "tmx_var_get FAILED for '${var_name}' in session '${target_session}'. tmux output: ${output}"
                return 1
            fi
        fi
        # Check if the output indicates the variable was unset (starts with -)
        # This is another way tmux might indicate unset, handle both
        if [[ "${output}" == -* ]]; then
             msg_debug "tmx_var_get: Variable '${var_name}' explicitly unset (-) in session '${target_session}'"
             echo ""
             return 0 # Return success for unset variable
        fi
    else # Global variable
        # Capture stderr (2>&1) and check return code
        if ! output=$(tmux show-environment -g "${var_name}" 2>&1); then
            # Check if the error is just 'unknown variable'
            if [[ "${output}" == *"unknown variable"* ]]; then
                msg_debug "tmx_var_get: Global variable '${var_name}' not found/unset"
                echo ""
                return 0 # Return success for unset variable
            else
                msg_error "tmx_var_get FAILED for global '${var_name}'. tmux output: ${output}"
                return 1
            fi
        fi
        # Check if the output indicates the variable was unset (starts with -)
        if [[ "${output}" == -* ]]; then
             msg_debug "tmx_var_get: Global variable '${var_name}' explicitly unset (-)"
             echo ""
             return 0 # Return success for unset variable
        fi
    fi

    # If successful and variable found, extract value
    value=$(echo "${output}" | cut -d= -f2-)
    echo "${value}"
    return 0
}

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

# Define the control function (moved from tmx_control_pane)
control_function() {
    # Variables to monitor and panes to control
    local vars="$1"
    local panes="$2"
    local session="$3"
    local refresh_rate="$4"

    # Debug the received parameters
    echo "Control function started with:"
    echo "- Variables to monitor: ${vars}"
    echo "- Panes to control: ${panes}"
    echo "- Session: ${session}"
    echo "- Refresh rate: ${refresh_rate}"

    # Convert space-separated strings into arrays
    read -ra VAR_ARRAY <<< "$vars"
    read -ra PANE_ARRAY <<< "$panes"

    # Validate refresh_rate (default to 1 if empty or invalid)
    if [[ -z "${refresh_rate}" || ! "${refresh_rate}" =~ ^[0-9]+$ ]]; then
        echo "WARNING: Invalid refresh rate '${refresh_rate}', using default of 1 second"
        refresh_rate=1
    fi

    # Setup display
    echo "=== TMUX CONTROL PANE ==="
    echo "Session: $session | Refresh: ${refresh_rate}s"
    echo "Controls: [q] Quit all | [r] Restart pane | [number] Close pane"
    echo "-------------------------------"

    # Enable special terminal handling for input
    stty -echo

    # Main control loop
    while true; do
        # Trace loop execution
        msg_debug "control_function: Starting loop iteration at $(date '+%H:%M:%S.%3N')"
        clear
        echo "=== TMUX CONTROL PANE ==="
        echo "Session: $session | Refresh: ${refresh_rate}s | $(date '+%H:%M:%S')"
        echo "Controls: [q] Quit all | [r] Restart pane | [number] Close pane"
        echo "-------------------------------"

        # Display variables
        msg_debug "control_function: Processing ${#VAR_ARRAY[@]} variables"
        echo "= Variables ="
        for var in "${VAR_ARRAY[@]}"; do
            local value=$(tmx_var_get "$var" "$session" 2>/dev/null || echo "N/A")
            msg_debug "control_function: Variable '$var' = '$value'"

            # Choose color based on variable name
            if [[ "$var" == *"green"* ]]; then
                msg_green "$var: $value"
            elif [[ "$var" == *"blue"* ]]; then
                msg_blue "$var: $value"
            elif [[ "$var" == *"red"* ]]; then
                msg_red "$var: $value"
            elif [[ "$var" == *"yellow"* ]]; then
                msg_yellow "$var: $value"
            else
                echo "$var: $value"
            fi
        done

        # Display panes
        msg_debug "control_function: Checking status of ${#PANE_ARRAY[@]} panes"
        echo "= Panes ="
        for pane in "${PANE_ARRAY[@]}";
        do
            # Add extra debugging for has-pane
            local target_pane_id="${session}:0.${pane}"
            msg_debug "control_function: Checking pane existance for target: ${target_pane_id}"
            if tmux has-pane -t "${target_pane_id}" 2>/dev/null; then
                msg_debug "control_function: Pane ${pane} EXISTS (tmux has-pane SUCCEEDED)"
                msg_success "Pane ${pane}: Running - press ${pane} to close"
            else
                local exit_status=$?
                msg_debug "control_function: Pane ${pane} DOES NOT EXIST (tmux has-pane FAILED with status ${exit_status})"
                msg_warning "Pane ${pane}: Not running"
            fi
        done;
        msg_debug "control_function: Checking for user input";

        # Check for input (non-blocking)
        msg_debug "control_function: Checking for user input"
        read -t 0.1 -n 1 input
        if [[ -n "$input" ]]; then
            msg_debug "control_function: Received input: '$input'"
            case "$input" in
                q)
                    msg_debug "control_function: Quit command received"
                    echo "Closing all panes and exiting..."
                    for pane in "${PANE_ARRAY[@]}"; do
                        msg_debug "control_function: Killing pane ${pane}"
                        tmx_kill_pane "$session" "$pane" 2>/dev/null
                    done
                    msg_debug "control_function: Killing session ${session}"
                    tmux kill-session -t "$session" 2>/dev/null
                    break
                    ;;
                r)
                    msg_debug "control_function: Restart command received"
                    echo "Enter pane number to restart: "
                    read -n 1 pane_num
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
                            echo "Restart functionality requires customization"
                        else
                            msg_debug "control_function: Pane ${pane_num} not found in managed panes"
                        fi
                    fi
                    ;;
                [0-9])
                    msg_debug "control_function: Close pane command received for pane: $input"
                    # Check if input is in the array using a loop
                    local pane_exists=0
                    for p in "${PANE_ARRAY[@]}"; do
                        if [[ "$p" == "$input" ]]; then
                            pane_exists=1
                            break
                        fi
                    done

                    if [[ "$pane_exists" -eq 1 ]]; then
                        msg_debug "control_function: Closing pane $input"
                        echo "Closing pane $input..."
                        tmx_kill_pane "$session" "$input"
                    else
                        msg_debug "control_function: Pane $input not found in managed panes"
                    fi
                    ;;
                *)
                    # Ignore any other input
                    msg_debug "Ignoring unexpected input: $input"
                    ;;
            esac
        fi

        msg_debug "control_function: Sleeping for ${refresh_rate}s"
        sleep "$refresh_rate"
    done

    # Restore terminal settings
    stty echo
}

# Create a new pane and execute a shell function in it
# Arguments:
#   $1: Session name
#   $2: Shell function to execute (must be defined in the current shell)
#   $3: Pane options:
#      - Integer: Use existing pane with this index
#      - "v": Create new vertical split pane
#      - "h": Create new horizontal split pane
#   $4: Space-separated list of variables to export (optional)
# Returns: The index of the pane used
tmx_pane_function() {
    local session="${1}"
    local func_name="${2}"
    local pane_option="${3:-h}"  # Default to horizontal split
    local vars="${4:-}"
    shift 4 # Shift off the first 4 args
    local func_args=("$@") # Remaining args are function args
    local pane_index
    
    msg_debug "Executing ${func_name} in session=${session}, pane=${pane_option} (args: ${#func_args[@]})"
    
    # Check if pane_option is a number (existing pane) or split type
    if [[ "${pane_option}" =~ ^[0-9]+$ ]]; then
        # Use existing pane with the given index
        pane_index="${pane_option}"
        msg_debug "Using existing pane ${pane_index} in session ${session}"
    else
        # Create a new pane with specified split type
        if [[ "${pane_option}" != "h" && "${pane_option}" != "v" ]]; then
            msg_warning "Invalid split type: ${pane_option}. Using horizontal."
            pane_option="h"
        fi
        pane_index=$(tmx_create_pane "${session}" "${pane_option}")
        msg_debug "Created new ${pane_option} pane ${pane_index} in session ${session}"
    fi
    
    # Execute the function in the selected pane
    tmx_execute_shell_function "${session}" "${pane_index}" "${func_name}" "${vars}" "${func_args[@]}"
    
    # Return the pane index
    echo "${pane_index}"
    
    return 0
}

# Setup the first pane (pane 0) with a shell function
# RENAMED: Use tmx_pane_function with "0" as the pane option
tmx_first_pane_function() {
    local session="${1}"
    local func_name="${2}"
    local vars="${3:-}"
    
    # Call the new unified function with pane index 0
    tmx_pane_function "${session}" "${func_name}" "0" "${vars}"
}

# Create a new pane and execute a shell function in it
# RENAMED: Use tmx_pane_function with "h" or "v" as the pane option
tmx_create_pane_function() {
    local session="${1}"
    local func_name="${2}"
    local split_type="${3:-h}"  # Default to horizontal split
    local vars="${4:-}"
    
    # Call the new unified function
    tmx_pane_function "${session}" "${func_name}" "${split_type}" "${vars}"
}

# Create session, display confirmation, and initialize variables in one call
# Arguments:
#   $1: Reference variable to store the session name result
#   $2: Session name
#   $3: Headless flag (optional, "--headless" or empty)
#   $4: Name of array containing variable names to initialize
#   $5: Default value for variables (optional, defaults to 0)
# Returns: 0 on success, 1 on failure
tmx_create_session_with_vars() {
    # First parameter is a nameref (reference to caller's variable)
    local -n session_result="$1"
    local session_name="$2"
    local headless="${3:-}"
    local var_array_name="${4}"
    local default_value="${5:-0}"
    
    msg_debug "tmx_create_session_with_vars: starting with session_name='${session_name}' var_array='${var_array_name}'"
    msg_debug "Using reference variable named: $1"
    
    # Create the session - should return only the session name now
    local s=$(tmx_create_session "${session_name}" "${headless}")
    msg_debug "tmx_create_session returned: '${s}'"
    
    # Check if session creation succeeded
    if [[ -z "$s" ]]; then
        msg_error "Failed to create session '${session_name}'"
        session_result=""  # Set empty result
        return 1
    fi
    
    # Now we can safely print success messages without affecting the result
    msg_success "Session '${s}' initialized with variables."
    
    # Initialize tmux variables using the dedicated function
    msg_debug "Initializing variables from array '${var_array_name}' for session '${s}'"
    tmx_init_vars_array "$var_array_name" "$default_value" "$s" || {
        msg_warning "Failed to initialize some variables for session '${s}'"
    }
    
    # Store result in the caller's variable through the reference
    session_result="$s"
    msg_debug "Setting caller's variable to: '${session_result}'"
    
    return 0
}

# ======== TMUX PANE MANAGEMENT FUNCTIONS ========

# Kill a specific pane in a tmux session
# Arguments:
#   $1: Session name
#   $2: Pane index
# Returns: 0 on success, 1 on failure
tmx_kill_pane() {
    local session="${1}"
    local pane="${2}"
    
    if [[ -z "${session}" || -z "${pane}" ]]; then
        msg_error "Kill pane failed: Missing session name or pane index"
        return 1
    fi
    
    if tmux kill-pane -t "${session}:0.${pane}" 2>/dev/null; then
        msg_debug "Killed pane ${pane} in session: ${session}"
        return 0
    else
        msg_warning "Failed to kill pane ${pane} (may not exist) in session: ${session}"
        return 1
    fi
}

# Create a monitor pane to display and track tmux variables
# Arguments:
#   $1: Session name
#   $2: Variables to monitor (space-separated list of tmux variable names)
#   $3: Pane options (similar to tmx_pane_function):
#      - Integer: Use existing pane with this index
#      - "v": Create new vertical split pane
#      - "h": Create new horizontal split pane
#   $4: Refresh interval in seconds (optional, default: 1)
#   $5: Additional environment variables to pass (optional)
# Returns: The index of the monitor pane
tmx_monitor_pane() {
    local session="${1}"
    local monitor_vars="${2}"
    local pane_option="${3:-0}"  # Default to first pane
    local refresh="${4:-1}"      # Default refresh rate: 1 second
    local env_vars="${5:-}"
    
    # Define the monitor function
    monitor_function() {
        # Variables to monitor (passed as a string)
        local vars="$1"
        local session="$2"
        local refresh_rate="$3"
        
        # Debug the received parameters
        echo "Monitor function started with:"
        echo "- Variables to monitor: ${vars}"
        echo "- Session: ${session}"
        echo "- Refresh rate: ${refresh_rate}"
        
        # Convert space-separated vars into array
        read -ra VAR_ARRAY <<< "$vars"
        
        # Validate refresh_rate (default to 1 if empty or invalid)
        if [[ -z "${refresh_rate}" || ! "${refresh_rate}" =~ ^[0-9]+$ ]]; then
            echo "WARNING: Invalid refresh rate '${refresh_rate}', using default of 1 second"
            refresh_rate=1
        fi
        
        echo "=== TMUX VARIABLE MONITOR ==="
        echo "Session: $session | Refresh: ${refresh_rate}s"
        echo "Press Ctrl+C to stop monitoring"
        echo "-------------------------------"
        
        # Main monitoring loop
        while true; do
            # Trace loop execution
            msg_debug "monitor_function: Starting loop iteration at $(date '+%H:%M:%S.%3N')"
            clear
            echo "=== TMUX VARIABLE MONITOR ==="
            echo "Session: $session | Refresh: ${refresh_rate}s | $(date '+%H:%M:%S')"
            echo "-------------------------------"
            
            # Display each variable with color based on name
            msg_debug "monitor_function: Processing ${#VAR_ARRAY[@]} variables"
            for var in "${VAR_ARRAY[@]}"; do
                local value=$(tmx_var_get "$var" "$session" 2>/dev/null || echo "N/A")
                msg_debug "monitor_function: Variable '$var' = '$value'"
                
                # Choose color based on variable name
                if [[ "$var" == *"green"* ]]; then
                    msg_green "$var: $value"
                elif [[ "$var" == *"blue"* ]]; then
                    msg_blue "$var: $value"
                elif [[ "$var" == *"red"* ]]; then
                    msg_red "$var: $value"
                elif [[ "$var" == *"yellow"* ]]; then
                    msg_yellow "$var: $value"
                else
                    echo "$var: $value"
                fi
            done
            
            msg_debug "monitor_function: Sleeping for ${refresh_rate}s"
            sleep "$refresh_rate"
        done
    }
    
    # Setup monitor in appropriate pane
    local pane_index
    
    # Explicitly prepare variables for the function with the session name
    msg_debug "Setting up monitor pane with refresh rate: ${refresh}"
    
    # Set refresh_rate variable in the session BEFORE creating the pane
    tmx_var_set "refresh_rate" "$refresh" "$session"
    
    # Use tmx_pane_function to handle pane creation and execution
    # Create a parameter string WITHOUT using quotes that would be preserved
    local params="${monitor_vars} ${session} ${refresh} ${env_vars}"
    pane_index=$(tmx_pane_function "$session" monitor_function "$pane_option" "$params")
    
    echo "$pane_index"
    return 0
}

# Create a control pane that can monitor variables and manage other panes
# Arguments:
#   $1: Session name
#   $2: Variables to monitor (space-separated list of tmux variable names)
#   $3: Panes to control (space-separated list of pane indices)
#   $4: Pane options (similar to tmx_pane_function)
#   $5: Refresh interval in seconds (optional, default: 1)
#   $6: Additional environment variables to pass (optional)
# Returns: The index of the control pane
tmx_control_pane() {
    local session="${1}"
    local monitor_vars="${2}"
    local control_panes="${3}"
    local pane_option="${4:-0}"  # Default to first pane
    local refresh="${5:-1}"      # Default refresh rate: 1 second
    local env_vars="${6:-}"
    
    # Setup control pane in appropriate pane
    local pane_index
    
    # Explicitly prepare variables for the function with the session name
    msg_debug "Setting up control pane with refresh rate: ${refresh} for panes: ${control_panes}"
    
    # Set refresh_rate variable in the session BEFORE creating the pane
    tmx_var_set "refresh_rate" "$refresh" "$session"

    # Call control_function directly, passing required arguments
    # Also pass TMUX variable via the 'vars' argument (arg 4)
    local vars_to_export=""
    [[ -n "${TMUX:-}" ]] && vars_to_export="TMUX" # Add TMUX if set
    pane_index=$(tmx_pane_function "$session" control_function "$pane_option" "${vars_to_export}" \
        "${monitor_vars}" "${control_panes}" "${session}" "${refresh}")

    echo "$pane_index"
    return 0
}

# Create a simple status bar pane showing session name and variables
# Arguments:
#   $1: Session name
#   $2: Variables to monitor (space-separated list of tmux variable names)
#   $3: Pane options (similar to tmx_pane_function)
#   $4: Refresh interval in seconds (optional, default: 1)
# Returns: The index of the status pane
tmx_status_pane() {
    local session="${1}"
    local monitor_vars="${2}"
    local pane_option="${3:-0}"  # Default to first pane
    local refresh="${4:-1}"      # Default refresh rate: 1 second
    
    # Define the status function
    status_function() {
        local vars="$1"
        local session="$2"
        local refresh_rate="$3"
        
        # Debug the received parameters
        echo "Status function started with:"
        echo "- Variables to monitor: ${vars}"
        echo "- Session: ${session}"
        echo "- Refresh rate: ${refresh_rate}"
        
        # Convert space-separated vars into array
        read -ra VAR_ARRAY <<< "$vars"
        
        # Validate refresh_rate (default to 1 if empty or invalid)
        if [[ -z "${refresh_rate}" || ! "${refresh_rate}" =~ ^[0-9]+$ ]]; then
            echo "WARNING: Invalid refresh rate '${refresh_rate}', using default of 1 second"
            refresh_rate=1
        fi
        
        # Main status loop
        while true; do
            # Trace loop execution
            msg_debug "status_function: Starting loop iteration at $(date '+%H:%M:%S.%3N')"
            clear
            echo -e "$(msg_bold "SESSION: ${session} | $(date '+%H:%M:%S')")"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            msg_debug "status_function: Processing ${#VAR_ARRAY[@]} variables for compact display"
            # Display each variable in a compact format
            local output=""
            for var in "${VAR_ARRAY[@]}"; do
                local value=$(tmx_var_get "$var" "$session" 2>/dev/null || echo "N/A")
                msg_debug "status_function: Variable '$var' = '$value'"
                output+="$(msg_bold "$var")=$value | "
            done
            
            # Remove trailing separator and print
            output="${output% | }"
            msg_debug "status_function: Output length: ${#output} characters"
            echo -e "$output"
            
            msg_debug "status_function: Sleeping for ${refresh_rate}s"
            sleep "$refresh_rate"
        done
    }
    
    # Setup status in appropriate pane
    local pane_index
    
    # Explicitly prepare variables for the function with the session name
    msg_debug "Setting up status pane with refresh rate: ${refresh}"
    
    # Set refresh_rate variable in the session BEFORE creating the pane
    tmx_var_set "refresh_rate" "$refresh" "$session"
    
    # Use tmx_pane_function to handle pane creation and execution
    # Create a parameter string WITHOUT using quotes that would be preserved
    local params="${monitor_vars} ${session} ${refresh}"
    pane_index=$(tmx_pane_function "$session" status_function "$pane_option" "$params")
    
    echo "$pane_index"
    return 0
}

# Create a simple unified management pane that handles monitoring and basic control
# Arguments:
#   $1: Session name
#   $2: Variables to monitor (space-separated list of tmux variable names)
#   $3: Pane options (similar to tmx_pane_function)
#   $4: Refresh interval in seconds (optional, default: 1)
# Returns: The index of the management pane
tmx_manage_pane() {
    local session="${1}"
    local monitor_vars="${2}"
    local pane_option="${3:-0}"  # Default to first pane
    local refresh="${4:-1}"      # Default refresh rate: 1 second
    
    # Define the management function
    manage_function() {
        # Get variables list as input parameter
        local vars="$1"
        
        # Get session name and refresh directly from tmux environment
        local session_name=$(tmux display-message -p '#S')
        local refresh_rate=1
        
        # Try to get refresh rate from tmux environment
        local tmx_refresh=$(tmux show-environment -t "$session_name" "TMX_REFRESH" 2>/dev/null | cut -d= -f2- || echo "1")
        if [[ -n "$tmx_refresh" ]]; then
            refresh_rate="$tmx_refresh"
        fi
        
        # Debug info
        echo "┌─ Management Pane Initialized ───────────"
        echo "│ Variables: $vars"
        echo "│ Session: $session_name"
        echo "│ Refresh: $refresh_rate seconds"
        echo "└────────────────────────────────────────"
        sleep 2
        
        # Convert space-separated vars into array for monitoring
        IFS=' ' read -ra VAR_ARRAY <<< "$vars"
        
        # Initialize session start time
        local start_time=$(date +%s)
        
        # Main management loop
        while true; do
            # Trace loop execution
            msg_debug "manage_function: Starting loop iteration at $(date '+%H:%M:%S.%3N')"
            # Update session time
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))
            msg_debug "manage_function: Session time elapsed: ${elapsed}s"
            tmx_var_set "session_time" "${elapsed}s" "$session_name"
            
            clear
            echo -e "=== TMUX MANAGER ==="
            echo -e "$(msg_bold "SESSION: ${session_name} | $(date '+%H:%M:%S')")"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Debug monitor vars and get their values
            msg_debug "manage_function: Processing ${#VAR_ARRAY[@]} variables"
            echo "= VARIABLES ="
            local empty_vars=1
            
            for var in "${VAR_ARRAY[@]}"; do
                # Skip empty variable names
                if [[ -z "$var" ]]; then
                    msg_debug "manage_function: Skipping empty variable name"
                    continue
                fi
                
                local value=$(tmux show-environment -t "$session_name" "$var" 2>/dev/null | cut -d= -f2- || echo "N/A")
                if [[ "$value" == "N/A" ]]; then
                    msg_debug "manage_function: Variable '$var' not found in environment, trying tmx_var_get"
                    # Try getting it with tmx_var_get as fallback
                    value=$(tmx_var_get "$var" "$session_name" 2>/dev/null || echo "N/A")
                fi
                msg_debug "manage_function: Variable '$var' = '$value'"
                
                empty_vars=0
                
                # Choose color based on variable name
                if [[ "$var" == *"green"* ]]; then
                    msg_green "$var: $value"
                elif [[ "$var" == *"blue"* ]]; then
                    msg_blue "$var: $value"
                elif [[ "$var" == *"red"* ]]; then
                    msg_red "$var: $value"
                elif [[ "$var" == *"yellow"* ]]; then
                    msg_yellow "$var: $value"
                elif [[ "$var" == *"time"* ]]; then
                    msg_cyan "$var: $value"
                else
                    echo "$var: $value"
                fi
            done
            
            # Show a message if no variables
            if [[ $empty_vars -eq 1 ]]; then
                msg_debug "manage_function: No variables to monitor"
                echo "No variables to monitor."
            fi
            
            echo ""
            echo "= CONTROLS ="
            echo "Press [q] to quit session | [h] for help"
            
            # Check for input (non-blocking)
            msg_debug "manage_function: Checking for user input"
            read -t 0.1 -n 1 input
            if [[ -n "$input" ]]; then
                msg_debug "manage_function: Received input: '$input'"
                case "$input" in
                    q)
                        msg_debug "manage_function: Quit command received"
                        echo "Closing session..."
                        tmux kill-session -t "$session_name" 2>/dev/null
                        break
                        ;;
                    h)
                        msg_debug "manage_function: Help command received"
                        clear
                        echo "=== TMUX MANAGER HELP ==="
                        echo "q - Quit session"
                        echo "h - Show this help"
                        echo ""
                        echo "Press any key to return..."
                        read -n 1
                        msg_debug "manage_function: Exiting help screen"
                        ;;
                    *)
                        # Ignore any other input
                        msg_debug "Ignoring input: $input"
                        ;;
                esac
            fi
            
            msg_debug "manage_function: Sleeping for ${refresh_rate}s"
            sleep "$refresh_rate"
        done
    }
    
    # Setup management pane
    local pane_index
    
    # Explicitly prepare variables for the function with the session name
    msg_debug "Setting up management pane with refresh rate: ${refresh} for session: ${session}"
    
    # Ensure session_time is in the variables list
    if [[ ! "$monitor_vars" == *"session_time"* ]]; then
        monitor_vars="$monitor_vars session_time"
    fi
    
    # Initialize all variables in session
    IFS=' ' read -ra VAR_ARRAY <<< "$monitor_vars"
    for var in "${VAR_ARRAY[@]}"; do
        if [[ -n "$var" ]]; then
            tmx_var_set "$var" "0" "$session"
        fi
    done
    
    # Set refresh rate directly in the tmux session environment
    tmux set-environment -t "$session" "TMX_REFRESH" "$refresh"
    
    # Pass only the monitor_vars as parameter - all other data is fetched directly from tmux
    pane_index=$(tmx_pane_function "$session" manage_function "$pane_option" "$monitor_vars")
    
    echo "$pane_index"
    return 0
}