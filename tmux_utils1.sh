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

# Global variable to hold the result of handle_duplicate_session
CHOSEN_SESSION_NAME=""

# Detect available terminal if not specified
detect_terminal_emulator() {
    # If already set and exists, use it
    if [[ -n "${TMUX_TERM_EMULATOR}" ]] && command -v "${TMUX_TERM_EMULATOR}" &>/dev/null; then
        msg_debug "Using pre-configured terminal: ${TMUX_TERM_EMULATOR}"
        return 0
    fi
    
    # Check for available terminals in preference order
    local terminals=("konsole" "xterm" "gnome-terminal" "xfce4-terminal" "terminator")
    
    for term in "${terminals[@]}"; do
        if command -v "${term}" &>/dev/null; then
            TMUX_TERM_EMULATOR="${term}"
            msg_debug "Detected terminal emulator: ${TMUX_TERM_EMULATOR}"
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
launch_tmux_terminal() {
    local session_name="${1}"
    
    # Detect terminal emulator if not already set
    detect_terminal_emulator || {
        msg_error "No terminal emulator available to launch session '${session_name}'"
        return 1
    }
    
    # Open terminal with tmux session if we have one
    if [[ -n "${TMUX_TERM_EMULATOR}" ]]; then
        msg_debug "Launching terminal '${TMUX_TERM_EMULATOR}' for session '${session_name}'"
        # Handle different terminal syntax
        case "${TMUX_TERM_EMULATOR}" in
            konsole)
                # Suppress Qt errors to stderr
                "${TMUX_TERM_EMULATOR}" --new-tab -e tmux attach-session -t "${session_name}" 2>/dev/null &
                ;;
            gnome-terminal|xfce4-terminal)
                "${TMUX_TERM_EMULATOR}" -- tmux attach-session -t "${session_name}" 2>/dev/null &
                ;;
            *)
                # Generic fallback
                "${TMUX_TERM_EMULATOR}" -e "tmux attach-session -t ${session_name}" 2>/dev/null &
                ;;
        esac
        
        # Check if terminal launch succeeded based on process status
        local terminal_pid=$!
        sleep 0.5
        if kill -0 $terminal_pid 2>/dev/null; then
            msg_debug "Terminal launch succeeded (PID: $terminal_pid)"
            return 0
        else
            msg_warning "Terminal launch may have failed for '${session_name}', but session was created."
            return 1 # Still indicate potential issue
        fi
    else
        msg_error "No terminal emulator available"
        return 1
    fi
}

# Create a new tmux session and open it in a terminal
# Arguments:
#   $1: Session name (optional)
#   $2: Launch terminal flag (optional, default: true)
# Returns the session name on success, empty string on failure
create_tmux_session() {
    # Check if a session name was provided, otherwise generate one
    local session_name="${1:-tmux_session_$(date +%Y%m%d_%H%M%S)}"
    local launch_terminal="${2:-true}"
    
    msg_debug "Attempting to create session: ${session_name}"
    
    # Create detached session
    if ! tmux new-session -d -s "${session_name}"; then
        msg_error "Failed to create tmux session '${session_name}'"
        return 1
    fi
    
    # Launch terminal if requested
    if [[ "${launch_terminal}" == "true" ]]; then
        if ! launch_tmux_terminal "${session_name}"; then
            msg_warning "Terminal launch failed for '${session_name}', but session created."
            # Continue as the session was still created successfully
        fi
    else
        msg_info "Terminal launch skipped. Use 'tmux attach-session -t ${session_name}' to connect."
    fi
    
    # Give tmux a moment to initialize
    sleep 0.5
    
    # Check if session was created successfully
    if ! tmux has-session -t "${session_name}" 2>/dev/null; then
        msg_error "Session verification failed for '${session_name}'"
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
    
    msg_debug "Exec in ${session}:${pane}: ${cmd}"
    
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
        echo "  msg_info \"Closing session \${session_name}...\""
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
    
    # Use msg_debug for internal operation details
    msg_debug "Execute script in ${session}:0.${pane} (vars: ${vars:-none})"
    
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
        echo "  msg_info \"Closing session \${session_name}...\""
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
list_tmux_sessions() {
    if ! tmux list-sessions 2>/dev/null; then
        msg_info "No active tmux sessions"
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
        msg_error "Failed to create new window in session '${session}'"
        return 1
    fi
}

# Close a tmux session and clean up its resources
close_tmux_session() {
    local session="${1}"
    
    if [[ -z "${session}" ]]; then
        msg_error "Close session failed: No session name provided"
        return 1
    fi
    
    # Clean up temp scripts associated with this session
    if [[ -n "${TMUX_SESSION_TEMPS[${session}]:-}" ]]; then
        msg_debug "Cleaning up temp files for session ${session}"
        for tmp_file in ${TMUX_SESSION_TEMPS[${session}]}; do
            if [[ -f "${tmp_file}" ]]; then
                rm -f "${tmp_file}"
                msg_debug "Removed temp file: ${tmp_file}"
            fi
        done
        unset TMUX_SESSION_TEMPS[${session}]
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
cleanup_all_tmux_sessions() {
    msg_debug "Cleaning up all tracked tmux sessions and resources"
    
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
                msg_debug "Removed orphaned temp file: ${tmp_file}"
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
        echo "  msg_info \"Closing session \${session_name}...\""
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
        echo "  msg_info \"Closing session \${session_name}...\""
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
execute_shell_function() {
    local session="${1}"
    local pane="${2}"
    local func_name="${3}"
    local vars="${4:-}"
    
    # Use msg_debug for internal operation details
    msg_debug "Execute shell function '${func_name}' in ${session}:0.${pane} (vars: ${vars:-none})"
    
    # Check if function exists
    if ! declare -f "${func_name}" > /dev/null; then
        msg_error "Shell function '${func_name}' not found"
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
    
    # Get absolute path to the project directory (still needed for PATH)
    local script_dir
    # Use a more robust way to find the directory of tmux_utils1.sh itself
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    
    # Write the script that will run the function
    {
        echo '#!/usr/bin/env bash'
        # Removed set -x for cleaner output now
        echo ""
        echo "# Set up script environment"
        echo "SCRIPT_DIR=\"$(printf '%q' "${script_dir}")\"" # Use printf %q for robust quoting
        echo 'export PATH="${SCRIPT_DIR}:${PATH}"' # Keep script dir in PATH
        echo '# Attempt to cd to script dir, continue if it fails'
        echo 'cd "${SCRIPT_DIR}" || msg_warning "Could not cd to ${SCRIPT_DIR}"' 
        
        # Export specified variables from parent shell
        if [[ -n "${vars}" ]]; then
            echo "# Export variables from parent shell"
            for var in ${vars}; do
                # Get value and quote it properly for inclusion in the script
                printf 'export %s=%q\n' "${var}" "${!var}" # Use printf %q for robust quoting
            done
        fi
        
        # ADDED back direct sourcing of sh-globals.sh and init
        echo ""
        echo "# Source sh-globals.sh (essential for colors/msg functions)"
        # Use the known location relative to this script (tmux_utils1.sh)
        echo "if [[ -f \"${script_dir}/sh-globals.sh\" ]]; then"
        echo "    source \"${script_dir}/sh-globals.sh\" || { msg_error 'Failed to source sh-globals.sh'; exit 1; }"
        echo "else"
        echo "    msg_error \"sh-globals.sh not found at ${script_dir}/sh-globals.sh\"; exit 1;"
        echo "fi"
        echo ""
        echo "# Initialize globals (optional, but good practice)"
        echo "export DEBUG=\"$(printf '%q' "${DEBUG:-0}")\"" # Inherit DEBUG or default to 0, quoted
        # Pass any arguments from the parent script if needed, though usually not for functions
        # echo "sh-globals_init \"$@\"" 
        echo "sh-globals_init" # Basic init should be sufficient

        echo ""
        echo "# Define the shell function"
        echo "${func_def}"
        echo ""
        echo "# Execute the function"
        # Pass any arguments originally intended for the function if needed
        # This example assumes no extra args are passed via execute_shell_function
        echo "${func_name}" 
        echo ""
        echo "# Exit after function completes (optional, prevents pane staying open)"
        echo "# exit 0" 

    } > "${tmp_script}"
    
    # Make script executable
    chmod +x "${tmp_script}"
    
    # Execute temporary script
    # Use bash explicitly to ensure consistent environment
    # Quote the script path robustly
    tmux send-keys -t "${session}:0.${pane}" "bash $(printf '%q' "${tmp_script}")" C-m 
    
    return $?
}

# Handle duplicate session names
# Arguments:
#   $1: Session name
# Sets global variable CHOSEN_SESSION_NAME:
#   - Original session name if user chooses to force close existing session or if it didn't exist
#   - New incremented session name if user chooses to use a new name
#   - Empty string if user chooses to exit
handle_duplicate_session() {
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
create_session_with_duplicate_handling() {
    local base_session_name="${1}"
    local launch_terminal="${2:-true}"
    
    # Handle duplicate session name interactively
    handle_duplicate_session "${base_session_name}"

    # Use the session name chosen by the user (stored in global variable)
    local session_name="${CHOSEN_SESSION_NAME}"
    
    # Check if user decided to exit (empty global variable)
    if [[ -z "${session_name}" ]]; then
        return 1 # User chose to exit
    fi
    
    # Create the session. create_tmux_session sets the global SESSION_NAME
    if ! create_tmux_session "${session_name}" "${launch_terminal}"; then
        msg_debug "Session creation failed in create_tmux_session"
        return 1 # Creation failed
    fi
    
    # Session created successfully, SESSION_NAME is set globally
    return 0
}