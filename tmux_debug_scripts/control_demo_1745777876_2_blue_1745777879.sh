#!/usr/bin/env bash

# Enable xtrace for detailed debugging within the pane
# set -x  # Removed as per user request

# Set up script environment
SCRIPT_DIR="/mnt/N1/MZ/AMZ/Projects/linux/Util-Sh"
export PATH="${SCRIPT_DIR}:${PATH}"
# Attempt to cd to script dir, continue if it fails
cd "${SCRIPT_DIR}" || echo "WARNING: Could not cd to ${SCRIPT_DIR}"
echo "--- Sourcing sh-globals ---"
# Source sh-globals.sh (essential for colors/msg functions)
if [[ -f "/mnt/N1/MZ/AMZ/Projects/linux/Util-Sh/sh-globals.sh" ]]; then
    source "/mnt/N1/MZ/AMZ/Projects/linux/Util-Sh/sh-globals.sh" || { echo "ERROR: Failed to source sh-globals.sh"; exit 1; }
else
    echo "ERROR: sh-globals.sh not found at /mnt/N1/MZ/AMZ/Projects/linux/Util-Sh/sh-globals.sh"; exit 1;
fi
echo "--- sh-globals sourced ---"

# Initialize globals
export DEBUG="${DEBUG}"
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
    local output;
    if [[ -z "${var_name}" ]]; then
        msg_error "tmx_var_set: Variable name cannot be empty.";
        return 1;
    fi;
    msg_debug "Setting tmux env var: ${var_name}=${var_value} in session '${target_session:-global}'";
    if [[ -n "${target_session}" ]]; then
        if ! output=$(tmux set-environment -t "${target_session}" "${var_name}" "${var_value}" 2>&1); then
            msg_error "tmx_var_set FAILED for '${var_name}=${var_value}' in session '${target_session}'. tmux output: ${output}";
            return 1;
        fi;
    else
        if ! output=$(tmux set-environment -g "${var_name}" "${var_value}" 2>&1); then
            msg_error "tmx_var_set FAILED for global '${var_name}=${var_value}'. tmux output: ${output}";
            return 1;
        fi;
    fi;
    return 0
}
tmx_var_get () 
{ 
    local var_name="${1}";
    local target_session="${2:-}";
    local value="";
    local output;
    if [[ -z "${var_name}" ]]; then
        msg_error "tmx_var_get: Variable name cannot be empty.";
        return 1;
    fi;
    if [[ -n "${target_session}" ]]; then
        if ! output=$(tmux show-environment -t "${target_session}" "${var_name}" 2>&1); then
            if [[ "${output}" == *"unknown variable"* ]]; then
                msg_debug "tmx_var_get: Variable '${var_name}' not found/unset in session '${target_session}'";
                echo "";
                return 0;
            else
                msg_error "tmx_var_get FAILED for '${var_name}' in session '${target_session}'. tmux output: ${output}";
                return 1;
            fi;
        fi;
        if [[ "${output}" == -* ]]; then
            msg_debug "tmx_var_get: Variable '${var_name}' explicitly unset (-) in session '${target_session}'";
            echo "";
            return 0;
        fi;
    else
        if ! output=$(tmux show-environment -g "${var_name}" 2>&1); then
            if [[ "${output}" == *"unknown variable"* ]]; then
                msg_debug "tmx_var_get: Global variable '${var_name}' not found/unset";
                echo "";
                return 0;
            else
                msg_error "tmx_var_get FAILED for global '${var_name}'. tmux output: ${output}";
                return 1;
            fi;
        fi;
        if [[ "${output}" == -* ]]; then
            msg_debug "tmx_var_get: Global variable '${var_name}' explicitly unset (-)";
            echo "";
            return 0;
        fi;
    fi;
    value=$(echo "${output}" | cut -d= -f2-);
    echo "${value}";
    return 0
}
blue () 
{ 
    local session="$1";
    while true; do
        local current_blue=$(tmx_var_get "counter_blue" "$session");
        local v=$((current_blue + 3));
        tmx_var_set "counter_blue" "$v" "$session";
        clear;
        msg_bg_blue "BLUE COUNTER (PANE 2)";
        msg_blue "Value: ${v}";
        msg_blue "Press '2' in control pane to close";
        sleep 2;
    done
}

# Shell function 'blue' follows
echo "--- Executing main content --- "
blue control_demo_1745777876 

# Add explicit exit to ensure clean termination
# exit 0 # Removed unconditional exit
