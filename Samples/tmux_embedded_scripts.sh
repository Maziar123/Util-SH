#!/usr/bin/env bash
# tmux_embedded_scripts.sh - Examples of embedded scripts for tmux

# This file contains script content but not the functions themselves.
# It's meant to be referenced as examples for inline scripts.

# =====================================================================
# EXAMPLE 1: Session-aware welcome script with heredoc
# Usage: execute_script "${SESSION_NAME}" 0 "APP_NAME APP_VERSION" <<'EOF'
#   [content below]
# EOF
# =====================================================================
WELCOME_SCRIPT=$(cat <<'EOSCRIPT'
# Get session and pane info directly
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#P')

# Clear screen and display header
clear
msg_header "${APP_NAME} v${APP_VERSION}"
msg_bg_blue "SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
msg_info "Welcome to the tmux session!"

# Show some basic information
echo "Current time: $(date)"
echo "Working directory: $(pwd)"
echo ""

# Display shared variables
echo "Variables shared from parent process:"
echo "- App: ${APP_NAME}"
echo "- Version: ${APP_VERSION}"
echo "- Session: ${SESSION_NAME}"
echo "- Pane: ${PANE_ID}"

msg_success "Script execution successful"
EOSCRIPT
)

# =====================================================================
# EXAMPLE 2: System information with shared data file
# Usage: execute_script "${SESSION_NAME}" 0 "SHARED_DIR" <<'EOF'
#   [content below]
# EOF
# =====================================================================
SYSTEM_INFO_SCRIPT=$(cat <<'EOSCRIPT'
# Get session and pane info
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#P')

# Clear screen and display header
clear
msg_bg_green "SYSTEM INFORMATION - SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
echo "-----------------------------------"

# Create shared info directory if it doesn't exist
mkdir -p "${SHARED_DIR}"
SYSTEM_INFO_FILE="${SHARED_DIR}/system_info.txt"

# Write system information to shared file
{
    echo "System Information collected at $(date)"
    echo "-----------------------------------"
    echo "Kernel: $(uname -r)"
    echo "Hostname: $(hostname)"
    echo "CPU Info: $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
    echo "Memory:"
    free -h | head -2
    echo ""
    echo "Disk usage:"
    df -h | grep -E '^/dev/' | sort
} > "${SYSTEM_INFO_FILE}"

# Display info and notify where it's stored
msg_info "System information collected:"
cat "${SYSTEM_INFO_FILE}"
echo ""
msg_success "Information saved to: ${SYSTEM_INFO_FILE}"
echo "Other tmux panes can access this information"
EOSCRIPT
)

# =====================================================================
# EXAMPLE 3: Counter that reads and increments shared variable
# Usage: execute_script "${SESSION_NAME}" 0 "SHARED_DIR" <<'EOF'
#   [content below]
# EOF
# =====================================================================
COUNTER_SCRIPT=$(cat <<'EOSCRIPT'
# Get session and pane info
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#P')

# Clear screen and display header
clear
msg_bg_yellow "SHARED COUNTER - SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
echo ""

# Create/access shared counter file
COUNTER_FILE="${SHARED_DIR}/counter.txt"
if [[ ! -f "${COUNTER_FILE}" ]]; then
    echo "0" > "${COUNTER_FILE}"
    chmod 666 "${COUNTER_FILE}"
fi

# Function to read current counter value
get_counter() {
    cat "${COUNTER_FILE}" 2>/dev/null || echo "0"
}

# Function to increment counter by specified amount
increment_counter() {
    local increment="${1:-1}"
    local current_value
    current_value=$(get_counter)
    local new_value=$((current_value + increment))
    echo "${new_value}" > "${COUNTER_FILE}"
    sync
    echo "${new_value}"
}

# Show initial value
echo "Initial counter value: $(get_counter)"
echo ""

# Increment a few times at random intervals
msg_info "Incrementing counter every second..."
for i in {1..5}; do
    # Sleep random time (0.5-2 seconds)
    sleep $(awk "BEGIN {print 0.5 + rand() * 1.5}")
    
    # Get current value then increment
    local current=$(get_counter)
    local increment=$((RANDOM % 5 + 1))
    local new_value=$(increment_counter $increment)
    
    # Show what happened
    msg_green "Counter: ${current} -> ${new_value} (+${increment})"
done

echo ""
msg_success "Final counter value: $(get_counter)"
echo "Check other panes to see if they've updated the counter too!"
EOSCRIPT
)

# =====================================================================
# EXAMPLE 4: Interactive menu with shared file operations
# Usage: execute_script "${SESSION_NAME}" 0 "SHARED_DIR" <<'EOF'
#   [content below]
# EOF
# =====================================================================
INTERACTIVE_MENU_SCRIPT=$(cat <<'EOSCRIPT'
# Get session and pane info
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#P')

# Clear screen and display header
clear
msg_bg_magenta "INTERACTIVE MENU - SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
echo ""

# Create directory for shared files
mkdir -p "${SHARED_DIR}"
STATUS_FILE="${SHARED_DIR}/menu_status.txt"
echo "MENU_PANE=${PANE_ID}" > "${STATUS_FILE}"
echo "LAST_ACTION=Started" >> "${STATUS_FILE}"
echo "TIMESTAMP=$(date +%s)" >> "${STATUS_FILE}"

# Menu handler function
select_option() {
    msg_header "Interactive Menu"
    msg_info "Select an option:"
    
    select choice in "Check System" "Set Message" "Show Message" "View Status" "Exit"; do
        case $choice in
            "Check System")
                # Write system info to shared file
                uptime > "${SHARED_DIR}/uptime.txt"
                free -h > "${SHARED_DIR}/memory.txt"
                
                echo "System check complete"
                echo "- Uptime: $(cat "${SHARED_DIR}/uptime.txt")"
                echo "- Memory: $(head -2 "${SHARED_DIR}/memory.txt" | tail -1)"
                
                # Update status
                echo "LAST_ACTION=System Check" >> "${STATUS_FILE}"
                echo "TIMESTAMP=$(date +%s)" >> "${STATUS_FILE}"
                ;;
                
            "Set Message")
                # Prompt for message and save to shared file
                msg_info "Enter a message to share with other panes:"
                read -r user_message
                echo "${user_message}" > "${SHARED_DIR}/shared_message.txt"
                
                msg_success "Message saved!"
                
                # Update status
                echo "LAST_ACTION=Set Message" >> "${STATUS_FILE}"
                echo "TIMESTAMP=$(date +%s)" >> "${STATUS_FILE}"
                echo "MESSAGE=${user_message}" >> "${STATUS_FILE}"
                ;;
                
            "Show Message")
                # Read and display shared message
                if [[ -f "${SHARED_DIR}/shared_message.txt" ]]; then
                    msg_info "Shared message:"
                    msg_bg_cyan "$(cat "${SHARED_DIR}/shared_message.txt")"
                else
                    msg_warning "No message has been set yet"
                fi
                
                # Update status
                echo "LAST_ACTION=Show Message" >> "${STATUS_FILE}"
                echo "TIMESTAMP=$(date +%s)" >> "${STATUS_FILE}"
                ;;
                
            "View Status")
                # Show status of other panes
                msg_info "Current Status:"
                
                if [[ -f "${STATUS_FILE}" ]]; then
                    echo "Menu Status:"
                    cat "${STATUS_FILE}"
                    
                    # Find counter if it exists
                    if [[ -f "${SHARED_DIR}/counter.txt" ]]; then
                        echo ""
                        echo "Shared Counter: $(cat "${SHARED_DIR}/counter.txt")"
                    fi
                else
                    echo "No status information available"
                fi
                
                # Update own status
                echo "LAST_ACTION=View Status" >> "${STATUS_FILE}"
                echo "TIMESTAMP=$(date +%s)" >> "${STATUS_FILE}"
                ;;
                
            "Exit")
                echo "Exiting menu..."
                echo "LAST_ACTION=Exit" >> "${STATUS_FILE}"
                echo "TIMESTAMP=$(date +%s)" >> "${STATUS_FILE}"
                return 1
                ;;
                
            *)
                msg_error "Invalid option"
                ;;
        esac
        
        echo ""
        echo "Press Enter to continue..."
        read -r
        clear
        msg_bg_magenta "INTERACTIVE MENU - SESSION: ${SESSION_NAME} - PANE: ${PANE_ID}"
        msg_header "Interactive Menu"
        msg_info "Select an option:"
    done
    
    return 0
}

# Run the menu
select_option

msg_success "Menu closed"
EOSCRIPT
)

# =====================================================================
# EXAMPLE 5: Self-destruct countdown (shows session name)
# Usage: execute_script "${SESSION_NAME}" 0 <<'EOF'
#   [content below]
# EOF
# =====================================================================
SELF_DESTRUCT_SCRIPT=$(cat <<'EOSCRIPT'
# Get session name directly
SESSION_NAME=$(tmux display-message -p '#S')
PANE_ID=$(tmux display-message -p '#P')

clear
msg_bg_red "SESSION SELF-DESTRUCT - ${SESSION_NAME}"
msg_warning "This session (${SESSION_NAME}) will self-destruct in 5 seconds"
echo "Press Ctrl+C to abort"

# Create a marker file
MARKER_FILE="/tmp/tmux_${SESSION_NAME}_selfdestruct"
echo "Session: ${SESSION_NAME}" > "${MARKER_FILE}"
echo "Started at: $(date)" >> "${MARKER_FILE}"
echo "Initiated by pane: ${PANE_ID}" >> "${MARKER_FILE}"

# Countdown
for i in {5..1}; do
    msg_error "Self-destruct in $i seconds..."
    sleep 1
done

msg_error "INITIATING SELF-DESTRUCT SEQUENCE"
echo "Destroying session: ${SESSION_NAME}" >> "${MARKER_FILE}"
echo "Completed at: $(date)" >> "${MARKER_FILE}"
sleep 1

# Call the self-destruct function
tmux_self_destruct
EOSCRIPT
) 