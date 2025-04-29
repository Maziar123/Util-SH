#!/usr/bin/env bash

# Enable xtrace for detailed debugging within the pane if desired
# set -x

# Set up script environment
SCRIPT_DIR="/mnt/N1/MZ/AMZ/Projects/linux/Util-Sh"
export PATH="${SCRIPT_DIR}:${PATH}"
# Attempt to cd to script dir, continue if it fails
cd "${SCRIPT_DIR}" || echo "WARNING: Could not cd to ${SCRIPT_DIR}"

# --- Sourcing Core Utilities ---
echo "--- Sourcing sh-globals --- "
if [[ -f "${SCRIPT_DIR}/sh-globals.sh" ]]; then
    source "${SCRIPT_DIR}/sh-globals.sh" || { echo "ERROR: Failed to source sh-globals.sh"; exit 1; }
else
    echo "ERROR: sh-globals.sh not found at ${SCRIPT_DIR}/sh-globals.sh"; exit 1;
fi
echo "--- Sourcing tmux_base_utils --- "
if [[ -f "${SCRIPT_DIR}/tmux_base_utils.sh" ]]; then
    source "${SCRIPT_DIR}/tmux_base_utils.sh" || { echo "ERROR: Failed to source tmux_base_utils.sh"; exit 1; }
else
    echo "ERROR: tmux_base_utils.sh not found at ${SCRIPT_DIR}/tmux_base_utils.sh"; exit 1;
fi
echo "--- Sourcing tmux_utils1 (for higher-level functions) ---"
if [[ -f "${SCRIPT_DIR}/tmux_utils1.sh" ]]; then
    # Set the guard variable to prevent initialization code in tmux_utils1.sh
    export TMUX_UTILS1_SOURCED_IN_PANE=1
    source "${SCRIPT_DIR}/tmux_utils1.sh" || { echo "ERROR: Failed to source tmux_utils1.sh"; exit 1; }
else
    echo "ERROR: tmux_utils1.sh not found at ${SCRIPT_DIR}/tmux_utils1.sh"; exit 1;
fi
echo "--- Core utilities sourced ---"

# Initialize sh-globals within the pane script
export DEBUG=1 # Capture parent DEBUG value, default 0 if unset in parent
sh-globals_init
# Include specific helper functions for this script
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
    msg_debug "Getting tmux env var: ${var_name} from session '${target_session:-global}'";
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
yellow () 
{ 
    local session="$1";
    while true; do
        local current_yellow=$(tmx_var_get "counter_yellow" "$session");
        local v=$((current_yellow + 5));
        tmx_var_set "counter_yellow" "$v" "$session";
        clear;
        msg_bg_yellow "YELLOW COUNTER (PANE 3)";
        msg_yellow "Value: ${v}";
        msg_yellow "Press '3' in control pane to close";
        sleep 3;
    done
}

# --- Main Script Content (Shell function 'yellow') Follows ---
echo "--- Executing main content (Shell function 'yellow') ---"
yellow control_demo_1745950122 

echo "--- Main content finished ---"
# Add explicit exit to ensure clean termination?
# exit 0 # Consider if an explicit exit is always desired, maybe let script finish naturally
