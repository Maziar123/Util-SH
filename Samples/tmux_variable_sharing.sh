#!/usr/bin/env bash
# tmux_variable_sharing.sh - Demo of variable sharing between host script and tmux sessions

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
echo "SCRIPT_DIR: ${SCRIPT_DIR}"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/sh-globals.sh"
# shellcheck source=../tmux_utils1.sh
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    # Enable debug logging
    export DEBUG=1
    sh-globals_init "$@"
fi

# ==================================================================
# PART 1: Define host script variables that we'll share with sessions
# ==================================================================

# Host script configuration - these will be shared with tmux sessions
HOST_SCRIPT_NAME="Variable Sharing Demo"
HOST_VERSION="1.0.0"
CURRENT_USER=$(whoami)
CURRENT_DIR=$(pwd)
SYSTEM_UPTIME=$(uptime -p)
TOTAL_MEMORY=$(free -h | awk '/^Mem:/ {print $2}')
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Array of directories to monitor
MONITORED_DIRS=("/tmp" "/var/log" "${HOME}")
# Current directory index to monitor (will be changed by sessions)
CURRENT_DIR_INDEX=0

# Create a temp file that both host and sessions can access
SHARED_FILE=$(mktemp)
echo "This file is created by the host script at ${TIMESTAMP}" > "${SHARED_FILE}"
echo "It can be accessed by all tmux sessions" >> "${SHARED_FILE}"

# Custom message function that will be available in all sessions
demo_message() {
    local message="$1"
    local source="$2"
    
    msg_bg_blue "=== ${source} ===" 
    msg_green "${message}"
    echo "Timestamp: $(date "+%Y-%m-%d %H:%M:%S")"
    echo "-------------------------------------"
}

# =================================================================
# PART 2: Create a tmux session and demonstrate variable sharing
# =================================================================

main() {
    msg_header "${HOST_SCRIPT_NAME} v${HOST_VERSION}"
    msg_info "Starting variable sharing demo"
    
    # Create a new tmux session
    local session_name
    session_name=$(create_tmux_session "var_sharing_demo")
    if [[ -z "${session_name}" ]]; then
        msg_error "Failed to create tmux session. Exiting."
        exit 1
    fi
    msg_success "Created new tmux session: ${session_name}"
    sleep 2  # Give time for session to initialize
    
    # --------------------------------------------------------------
    # Method 1: Sharing variables with execute_script (heredoc)
    # --------------------------------------------------------------
    msg_info "DEMO 1: Sharing variables with execute_script"
    
    # Share a set of variables with the first pane
    execute_script "${session_name}" 0 "HOST_SCRIPT_NAME HOST_VERSION CURRENT_USER CURRENT_DIR TIMESTAMP SHARED_FILE" <<'EOF'
    # This script can access the shared variables
    msg_header "${HOST_SCRIPT_NAME} v${HOST_VERSION}"
    msg_info "Hello from tmux session! This is the main pane."
    
    echo "Variables shared from host script:"
    echo "- Current user: ${CURRENT_USER}"
    echo "- Current directory: ${CURRENT_DIR}"
    echo "- Timestamp: ${TIMESTAMP}"
    
    # Access the shared file created by host script
    if [[ -f "${SHARED_FILE}" ]]; then
        echo ""
        echo "Contents of shared file:"
        echo "------------------------"
        cat "${SHARED_FILE}"
        
        # Append data to the shared file
        echo "" >> "${SHARED_FILE}"
        echo "This line was added by the first pane at $(date)" >> "${SHARED_FILE}"
    else
        echo "Shared file not found: ${SHARED_FILE}"
    fi
    
    echo ""
    echo "Wait for next pane demo..."
EOF
    sleep 3
    
    # --------------------------------------------------------------
    # Method 2: Sharing variables with execute_function
    # --------------------------------------------------------------
    msg_info "DEMO 2: Sharing variables with execute_function"
    
    # Define a script generator function
    system_info_script() {
        cat <<EOF
    # This script-generating function uses variables with \${VAR} syntax
    msg_bg_green "System Information"
    echo "System uptime: \${SYSTEM_UPTIME}"
    echo "Total memory: \${TOTAL_MEMORY}"
    echo "Timestamp from host: \${TIMESTAMP}"
    echo "Current directory: \${CURRENT_DIR}"
    
    # Access the shared file
    if [[ -f "\${SHARED_FILE}" ]]; then
        echo ""
        echo "Updated contents of shared file:"
        echo "-------------------------------"
        cat "\${SHARED_FILE}"
        
        # Append data to the shared file
        echo "" >> "\${SHARED_FILE}"
        echo "This line was added by the function-generated script at \$(date)" >> "\${SHARED_FILE}"
    fi
    
    echo ""
    echo "Wait for next pane demo..."
EOF
    }
    
    # Create a new pane and execute the generated script
    local pane_idx
    pane_idx=$(create_new_pane "${session_name}")
    if [[ -n "${pane_idx}" ]]; then
        msg_success "Created new pane with index: ${pane_idx}"
        
        # Share system variables with this pane
        execute_function "${session_name}" "${pane_idx}" system_info_script "SYSTEM_UPTIME TOTAL_MEMORY TIMESTAMP CURRENT_DIR SHARED_FILE"
        sleep 3
    fi
    
    # --------------------------------------------------------------
    # Method 3: Sharing variables with execute_shell_function
    # --------------------------------------------------------------
    msg_info "DEMO 3: Sharing variables with execute_shell_function"
    
    # Define a real shell function (not a script generator)
    directory_monitor() {
        # This is a real shell function that will execute directly in the tmux pane
        msg_bg_yellow "Directory Monitor"
        
        # Print the monitored directories from the array that was shared
        echo "Monitored directories:"
        local i=0
        for dir in "${MONITORED_DIRS[@]}"; do
            if [[ $i -eq $CURRENT_DIR_INDEX ]]; then
                echo "=> $i: $dir (CURRENT)"
            else
                echo "   $i: $dir"
            fi
            ((i++))
        done
        
        # Monitor the current selected directory
        local watch_dir="${MONITORED_DIRS[$CURRENT_DIR_INDEX]}"
        echo ""
        echo "Monitoring directory: $watch_dir"
        echo "Files recently modified:"
        echo "-----------------------"
        find "$watch_dir" -type f -mtime -1 -ls 2>/dev/null | head -5 | awk '{print $11}' || echo "No recent files found"
        
        # Read from and write to the shared file
        if [[ -f "${SHARED_FILE}" ]]; then
            echo ""
            echo "Final contents of shared file:"
            echo "-----------------------------"
            cat "${SHARED_FILE}"
            
            echo "" >> "${SHARED_FILE}"
            echo "This line was added by the direct shell function at $(date)" >> "${SHARED_FILE}"
            echo "Monitoring directory: $watch_dir" >> "${SHARED_FILE}"
        fi
        
        # Use the custom function defined in the host script
        echo ""
        demo_message "Direct shell function complete!" "PANE ${PANE_NUM}"
    }
    
    # Create a new vertical pane and execute the shell function
    local pane_idx2
    pane_idx2=$(create_new_pane "${session_name}" "v")
    if [[ -n "${pane_idx2}" ]]; then
        msg_success "Created vertical pane with index: ${pane_idx2}"
        
        # Share a rich set of variables including an array
        PANE_NUM="${pane_idx2}"  # This var is specifically for this pane
        execute_shell_function "${session_name}" "${pane_idx2}" directory_monitor "MONITORED_DIRS CURRENT_DIR_INDEX SHARED_FILE PANE_NUM"
        sleep 3
    fi
    
    # --------------------------------------------------------------
    # Method 4: Two-way communication via shared files
    # --------------------------------------------------------------
    msg_info "DEMO 4: Two-way communication via shared files"
    
    # Create a new pane for the final demo
    local pane_idx3
    pane_idx3=$(create_new_pane "${session_name}" "h")
    if [[ -n "${pane_idx3}" ]]; then
        msg_success "Created pane with index: ${pane_idx3}"
        
        # Share variables for two-way communication
        execute_script "${session_name}" "${pane_idx3}" "HOST_SCRIPT_NAME SHARED_FILE" <<'EOF'
        msg_bg_magenta "Two-way Communication Demo"
        echo "This pane demonstrates reading from and writing to shared resources"
        
        # Create a control file that signals back to the host script
        CONTROL_FILE="${SHARED_FILE}.control"
        echo "STATUS=RUNNING" > "${CONTROL_FILE}"
        echo "PANE_ID=$(tmux display-message -p '#P')" >> "${CONTROL_FILE}"
        echo "START_TIME=$(date +%s)" >> "${CONTROL_FILE}"
        
        # Show progress and update the control file
        for i in {1..5}; do
            echo "Processing step $i of 5..."
            echo "PROGRESS=$((i*20))" >> "${CONTROL_FILE}"
            echo "STEP=$i" >> "${CONTROL_FILE}"
            echo "TIMESTAMP=$(date +%s)" >> "${CONTROL_FILE}"
            sleep 1
        done
        
        # Final update to the control file
        echo "STATUS=COMPLETED" >> "${CONTROL_FILE}"
        echo "END_TIME=$(date +%s)" >> "${CONTROL_FILE}"
        
        msg_success "Processing complete! Check ${CONTROL_FILE} for status."
EOF
        
        # Wait for the pane to finish processing by monitoring the control file
        CONTROL_FILE="${SHARED_FILE}.control"
        msg_info "Monitoring control file for pane ${pane_idx3}: ${CONTROL_FILE}"
        
        while true; do
            if [[ -f "${CONTROL_FILE}" ]]; then
                # Source the control file to get variables
                # shellcheck disable=SC1090
                source "${CONTROL_FILE}"
                
                # Show progress
                if [[ -n "${PROGRESS}" ]]; then
                    echo -ne "Progress: ${PROGRESS}%\r"
                fi
                
                # Check if processing is complete
                if [[ "${STATUS}" == "COMPLETED" ]]; then
                    echo ""
                    msg_success "Pane ${pane_idx3} has completed processing!"
                    
                    # Calculate duration
                    if [[ -n "${START_TIME}" && -n "${END_TIME}" ]]; then
                        DURATION=$((END_TIME - START_TIME))
                        echo "Processing took ${DURATION} seconds"
                    fi
                    break
                fi
                
                sleep 0.5
            else
                echo -ne "Waiting for control file...\r"
                sleep 0.5
            fi
        done
    fi
    
    # --------------------------------------------------------------
    # Finalize the demo
    # --------------------------------------------------------------
    msg_info "All panes have been set up with shared variables."
    msg_info "Final contents of the shared file:"
    echo "-------------------------------------"
    cat "${SHARED_FILE}"
    
    msg_info "Demo is complete. The tmux session '${session_name}' remains active."
    msg_info "You can attach to it with: tmux attach-session -t ${session_name}"
    
    # Clean up the shared file when done
    rm -f "${SHARED_FILE}" "${CONTROL_FILE}"
    
    return 0
}

# Run the main function
main 