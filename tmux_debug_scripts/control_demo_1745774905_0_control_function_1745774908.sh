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
control_function () 
{ 
    local vars="$1";
    local panes="$2";
    local session="$3";
    local refresh_rate="$4";
    msg_debug "Control function started with:";
    msg_debug "- Variables to monitor: ${vars}";
    msg_debug "- Panes to control: ${panes}";
    msg_debug "- Session: ${session}";
    msg_debug "- Refresh rate: ${refresh_rate}";
    read -ra VAR_ARRAY <<< "$vars";
    read -ra PANE_ARRAY <<< "$panes";
    msg_debug "control_function: VAR_ARRAY size=${#VAR_ARRAY[@]}";
    msg_debug "control_function: PANE_ARRAY size=${#PANE_ARRAY[@]}";
    if [[ -z "${refresh_rate}" || ! "${refresh_rate}" =~ ^[0-9]+$ ]]; then
        msg_warning "WARNING: Invalid refresh rate '${refresh_rate}', using default of 1 second";
        refresh_rate=1;
    fi;
    msg "=== TMUX CONTROL PANE ===";
    msg "Session: $session | Refresh: ${refresh_rate}s";
    msg "Controls: [q] Quit all | [r] Restart pane | [number] Close pane";
    msg_section "" 50 "-";
    stty -echo;
    msg_debug "control_function: Entering main loop";
    while true; do
        msg_debug "control_function: Starting loop iteration at $(date '+%H:%M:%S.%3N')";
        clear;
        msg "=== TMUX CONTROL PANE ===";
        msg "Session: $session | Refresh: ${refresh_rate}s | $(date '+%H:%M:%S')";
        msg "Controls: [q] Quit all | [r] Restart pane | [number] Close pane";
        msg_section "" 50 "-";
        msg_debug "control_function: Processing ${#VAR_ARRAY[@]} variables";
        msg_bold "= Variables =";
        for var in "${VAR_ARRAY[@]}";
        do
            local value=$(tmx_var_get "$var" "$session" 2> /dev/null || echo "N/A");
            msg_debug "control_function: Variable '$var' = '$value'";
            if [[ "$var" == *"green"* ]]; then
                msg_green "$var: $value";
            else
                if [[ "$var" == *"blue"* ]]; then
                    msg_blue "$var: $value";
                else
                    if [[ "$var" == *"red"* ]]; then
                        msg_red "$var: $value";
                    else
                        if [[ "$var" == *"yellow"* ]]; then
                            msg_yellow "$var: $value";
                        else
                            msg "$var: $value";
                        fi;
                    fi;
                fi;
            fi;
        done;
        msg_debug "control_function: Checking status of ${#PANE_ARRAY[@]} panes";
        msg_bold "= Panes =";
        for pane in "${PANE_ARRAY[@]}";
        do
            local target_pane_id="${session}:0.${pane}";
            msg_debug "control_function: Checking pane existance for target: ${target_pane_id}";
            if tmux has-pane -t "${target_pane_id}" 2> /dev/null; then
                msg_debug "control_function: Pane ${pane} EXISTS (tmux has-pane SUCCEEDED)";
                msg_success "Pane ${pane}: Running - press ${pane} to close";
            else
                local exit_status=$?;
                msg_debug "control_function: Pane ${pane} DOES NOT EXIST (tmux has-pane FAILED with status ${exit_status})";
                msg_warning "Pane ${pane}: Not running";
            fi;
        done;
        msg_debug "control_function: Finished checking pane statuses";
        msg_debug "control_function: Preparing for non-blocking read...";
        input="";
        if { 
            IFS= read -r -t 0 -n 1 2> /dev/null || [[ $? -ge 128 ]]
        } < /dev/tty; then
            msg_debug "control_function: Reading one character";
            IFS= read -r -n 1 input < /dev/tty;
            msg_debug "control_function: Read completed, input: '${input}'";
        else
            msg_debug "control_function: No input available (check returned $?)";
        fi;
        if [[ -n "$input" ]]; then
            msg_debug "control_function: Received input: '$input'";
            case "$input" in 
                q)
                    msg_debug "control_function: Quit command received";
                    msg_warning "Closing all panes and exiting...";
                    for pane in "${PANE_ARRAY[@]}";
                    do
                        msg_debug "control_function: Killing pane ${pane}";
                        tmx_kill_pane "$session" "$pane" 2> /dev/null;
                    done;
                    msg_debug "control_function: Killing session ${session}";
                    tmux kill-session -t "$session" 2> /dev/null;
                    break
                ;;
                r)
                    msg_debug "control_function: Restart command received";
                    msg_yellow "Enter pane number to restart: ";
                    read -n 1 pane_num;
                    msg "";
                    msg_debug "control_function: Pane number to restart: '$pane_num'";
                    if [[ "$pane_num" =~ ^[0-9]+$ ]]; then
                        local pane_exists=0;
                        for p in "${PANE_ARRAY[@]}";
                        do
                            if [[ "$p" == "$pane_num" ]]; then
                                pane_exists=1;
                                break;
                            fi;
                        done;
                        if [[ "$pane_exists" -eq 1 ]]; then
                            msg_debug "control_function: Found pane ${pane_num} in managed panes";
                            msg_warning "Restart functionality requires customization";
                        else
                            msg_debug "control_function: Pane ${pane_num} not found in managed panes";
                            msg_error "Pane ${pane_num} is not managed by this control pane.";
                        fi;
                    else
                        msg_error "Invalid input: Enter a valid pane number.";
                    fi;
                    sleep 1
                ;;
                [0-9])
                    msg_debug "control_function: Close pane command received for pane: $input";
                    local pane_exists=0;
                    for p in "${PANE_ARRAY[@]}";
                    do
                        if [[ "$p" == "$input" ]]; then
                            pane_exists=1;
                            break;
                        fi;
                    done;
                    if [[ "$pane_exists" -eq 1 ]]; then
                        msg_debug "control_function: Closing pane $input";
                        msg_info "Closing pane $input...";
                        tmx_kill_pane "$session" "$input";
                    else
                        msg_debug "control_function: Pane $input not found in managed panes";
                        msg_error "Pane $input is not managed by this control pane.";
                    fi;
                    sleep 1
                ;;
                *)
                    msg_debug "Ignoring unexpected input: $input"
                ;;
            esac;
        fi;
        msg_debug "control_function: Sleeping for ${refresh_rate}s";
        sleep "$refresh_rate";
    done;
    stty echo;
    msg_debug "control_function: Exiting"
}

# Shell function 'control_function' follows
echo "--- Executing main content --- "
control_function counter_green\ counter_blue\ counter_yellow 1\ 2\ 3 control_demo_1745774905 1 

# Add explicit exit to ensure clean termination
# exit 0 # Removed unconditional exit
