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
control_function () 
{ 
    local vars="$1";
    local panes="$2";
    local session="$3";
    local refresh_rate="$4";
    msg_debug "Control function started with:";
    msg_debug "- Variables to monitor: ${vars}";
    msg_debug "- Pane indices to control: ${panes}";
    msg_debug "- Session: ${session}";
    msg_debug "- Refresh rate: ${refresh_rate}";
    read -ra VAR_ARRAY <<< "$vars";
    read -ra PANE_ARRAY <<< "$panes";
    msg_debug "control_function: VAR_ARRAY size=${#VAR_ARRAY[@]}";
    msg_debug "control_function: PANE_ARRAY size=${#PANE_ARRAY[@]}";
    local -A PANE_ID_MAP=();
    for var in "${VAR_ARRAY[@]}";
    do
        if [[ "$var" == pane_id_* ]]; then
            local index="${var##pane_id_}";
            local id_value=$(tmx_var_get "$var" "$session" 2> /dev/null);
            if [[ -n "$id_value" ]]; then
                PANE_ID_MAP["$index"]="$id_value";
                msg_debug "control_function: Found pane ID mapping: $index -> $id_value";
            fi;
        fi;
    done;
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
        msg_debug "control_function: Clearing screen...";
        clear;
        echo -ne "\033c";
        echo -ne "\033[2J\033[H";
        msg "=== TMUX CONTROL PANE ===";
        msg "Session: $session | Refresh: ${refresh_rate}s | $(date '+%H:%M:%S')";
        msg "Controls: [q] Quit all | [r] Restart pane | [number] Close pane";
        msg_section "" 50 "-";
        msg_debug "control_function: Processing ${#VAR_ARRAY[@]} variables";
        msg_bold "= Variables =";
        for var in "${VAR_ARRAY[@]}";
        do
            if [[ "$var" == pane_id_* ]]; then
                continue;
            fi;
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
        local all_panes=$(tmux list-panes -t "${session}" -F "#{pane_index} #{pane_id}");
        msg_debug "control_function: Available panes in session: ${all_panes}";
        for pane_idx in "${PANE_ARRAY[@]}";
        do
            local pane_id="${PANE_ID_MAP[$pane_idx]:-}";
            local pane_exists=0;
            if [[ -n "$pane_id" ]]; then
                if tmux has-session -t "$pane_id" 2> /dev/null; then
                    pane_exists=1;
                    msg_debug "control_function: Pane $pane_idx ($pane_id) EXISTS via ID check";
                else
                    if echo "${all_panes}" | grep -q " ${pane_id}$"; then
                        pane_exists=1;
                        msg_debug "control_function: Pane $pane_idx ($pane_id) EXISTS via pane list grep";
                    fi;
                fi;
            else
                if echo "${all_panes}" | grep -q "^${pane_idx} %"; then
                    pane_exists=1;
                    pane_id=$(echo "${all_panes}" | grep "^${pane_idx} %" | awk '{print $2}');
                    PANE_ID_MAP["$pane_idx"]="$pane_id";
                    msg_debug "control_function: Pane $pane_idx EXISTS with newly retrieved ID $pane_id";
                fi;
            fi;
            if [[ $pane_exists -eq 1 ]]; then
                msg_success "Pane ${pane_idx}: Running - press ${pane_idx} to close";
            else
                msg_warning "Pane ${pane_idx}: Not running";
            fi;
        done;
        msg_debug "control_function: Finished checking pane statuses";
        msg_debug "control_function: Preparing for non-blocking read...";
        input="";
        read -t 0.1 -N 1 input < /dev/tty || true;
        if [[ -n "$input" ]]; then
            msg_debug "control_function: Received input: '$input'";
            case "$input" in 
                q)
                    msg_debug "control_function: Quit command received";
                    msg_warning "Closing all panes and exiting...";
                    for pane_idx in "${PANE_ARRAY[@]}";
                    do
                        local pane_id="${PANE_ID_MAP[$pane_idx]:-}";
                        if [[ -n "$pane_id" ]]; then
                            msg_debug "control_function: Killing pane $pane_idx using ID $pane_id";
                            if tmx_kill_pane_by_id "$pane_id"; then
                                msg_success "Closed pane $input using ID-based kill";
                                sleep 1;
                                continue;
                            else
                                msg_warning "ID-based kill failed for pane $input ($pane_id), checking if already closed...";
                            fi;
                        else
                            msg_warning "control_function: No mapped ID for pane index $pane_idx, attempting lookup";
                            local fallback_id=$(tmx_get_pane_id "$session" "$pane_idx");
                            if [[ -n "$fallback_id" ]]; then
                                msg_debug "control_function: Found fallback ID ${fallback_id}, killing...";
                                tmx_kill_pane_by_id "$fallback_id";
                            else
                                msg_error "control_function: Cannot find ID for pane index $pane_idx to kill it.";
                            fi;
                        fi;
                        sleep 0.1;
                    done;
                    msg_debug "control_function: Killing session ${session}";
                    ( tmux kill-session -t "$session" 2> /dev/null & );
                    msg_info "Exiting control function...";
                    trap '' INT TERM;
                    exit 0
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
                        msg_debug "control_function: Checking if pane '$p' matches target '$input'";
                        if [[ "$p" == "$input" ]]; then
                            pane_exists=1;
                            msg_debug "control_function: FOUND pane $input in managed panes";
                            break;
                        fi;
                    done;
                    if [[ "$pane_exists" -eq 1 ]]; then
                        local pane_id="${PANE_ID_MAP[$input]:-}";
                        msg_debug "control_function: Closing pane $input (ID: $pane_id)...";
                        msg_info "Closing pane $input...";
                        if [[ -n "$pane_id" ]]; then
                            msg_debug "control_function: Killing via pane ID: $pane_id";
                            if tmx_kill_pane_by_id "$pane_id"; then
                                msg_success "Closed pane $input using ID-based kill";
                                sleep 1;
                                continue;
                            else
                                msg_warning "ID-based kill failed for pane $input ($pane_id), checking if already closed...";
                            fi;
                        else
                            msg_debug "control_function: No ID found for pane $input";
                        fi;
                        msg_debug "control_function: Re-checking if pane index $input still exists...";
                        local current_panes=$(tmux list-panes -t "${session}" -F "#{pane_index}");
                        if echo "${current_panes}" | grep -q "^${input}$"; then
                            msg_error "Failed to close pane $input (index exists, but kill failed).";
                        else
                            msg_warning "Pane $input seems to be already closed (index not found).";
                            sleep 0.5;
                            continue;
                        fi;
                    else
                        msg_debug "control_function: Pane $input not found in managed panes";
                        msg_error "Pane $input is not managed by this control pane.";
                        sleep 1;
                    fi
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

# --- Main Script Content (Shell function 'control_function') Follows ---
echo "--- Executing main content (Shell function 'control_function') ---"
control_function counter_green\ counter_blue\ counter_yellow\ pane_id_1\ pane_id_2\ pane_id_3 1\ 2\ 3 control_demo_1745950122 1 

echo "--- Main content finished ---"
# Add explicit exit to ensure clean termination?
# exit 0 # Consider if an explicit exit is always desired, maybe let script finish naturally
