#!/usr/bin/env bash

# Set up script environment
SCRIPT_DIR="/mnt/N1/MZ/AMZ/Projects/linux/Util-Sh"
export PATH="${SCRIPT_DIR}:${PATH}"
# Attempt to cd to script dir, continue if it fails
cd "${SCRIPT_DIR}" || echo "WARNING: Could not cd to ${SCRIPT_DIR}"
# Export variables from parent shell
export counter_green=''export counter_blue=''export session_time=''export status_demo_1745436504=''export 1=status_function
# Source sh-globals.sh (essential for colors/msg functions)
if [[ -f "/mnt/N1/MZ/AMZ/Projects/linux/Util-Sh/sh-globals.sh" ]]; then
    source "/mnt/N1/MZ/AMZ/Projects/linux/Util-Sh/sh-globals.sh" || { echo "ERROR: Failed to source sh-globals.sh"; exit 1; }
else
    echo "ERROR: sh-globals.sh not found at /mnt/N1/MZ/AMZ/Projects/linux/Util-Sh/sh-globals.sh"; exit 1;
fi

# Initialize globals
export DEBUG="1"
sh-globals_init

# Define session self-destruct function
tmx_self_destruct() {
  local session_name=$(tmux display-message -p '#S')
  msg_info "Closing session ${session_name}..."
  ( sleep 0.5; tmux kill-session -t "${session_name}" ) &
}
# Include helper functions
tmx_var_set () 
{ 
    local var_name="${1}";
    local var_value="${2}";
    local target_session="${3:-}";
    if [[ -z "${var_name}" ]]; then
        msg_error "tmx_var_set: Variable name cannot be empty.";
        return 1;
    fi;
    msg_debug "Setting tmux env var: ${var_name}=${var_value} in session '${target_session:-global}'";
    if [[ -n "${target_session}" ]]; then
        tmux set-environment -t "${target_session}" "${var_name}" "${var_value}" 2> /dev/null || { 
            msg_warning "Failed to set tmux variable ${var_name} for session ${target_session}";
            return 1
        };
    else
        tmux set-environment -g "${var_name}" "${var_value}" 2> /dev/null || { 
            msg_warning "Failed to set global tmux variable ${var_name}";
            return 1
        };
    fi;
    return 0
}
tmx_var_get () 
{ 
    local var_name="${1}";
    local target_session="${2:-}";
    local value="";
    if [[ -z "${var_name}" ]]; then
        msg_error "tmx_var_get: Variable name cannot be empty.";
        return 1;
    fi;
    if [[ -n "${target_session}" ]]; then
        if ! value=$(tmux show-environment -t "${target_session}" "${var_name}" 2> /dev/null | cut -d= -f2-); then
            msg_debug "Variable '${var_name}' not found in session ${target_session}";
            return 1;
        fi;
    else
        if ! value=$(tmux show-environment -g "${var_name}" 2> /dev/null | cut -d= -f2-); then
            msg_debug "Variable '${var_name}' not found in global environment";
            return 1;
        fi;
    fi;
    echo "${value}";
    return 0
}
status_function () 
{ 
    local vars="$1";
    local session="$2";
    local refresh_rate="$3";
    echo "Status function started with:";
    echo "- Variables to monitor: ${vars}";
    echo "- Session: ${session}";
    echo "- Refresh rate: ${refresh_rate}";
    read -ra VAR_ARRAY <<< "$vars";
    if [[ -z "${refresh_rate}" || ! "${refresh_rate}" =~ ^[0-9]+$ ]]; then
        echo "WARNING: Invalid refresh rate '${refresh_rate}', using default of 1 second";
        refresh_rate=1;
    fi;
    while true; do
        clear;
        echo -e "$(msg_bold "SESSION: ${session} | $(date '+%H:%M:%S')")";
        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        local output="";
        for var in "${VAR_ARRAY[@]}";
        do
            local value=$(tmx_var_get "$var" "$session" 2> /dev/null || echo "N/A");
            output+="$(msg_bold "$var")=$value | ";
        done;
        output="${output% | }";
        echo -e "$output";
        sleep "$refresh_rate";
    done
}

# Shell function 'status_function' follows
status_function

# Add explicit exit to ensure clean termination
exit 0
