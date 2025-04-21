#!/usr/bin/env bash
# tmux_script_functions.sh - Library of tmux script functions

# Welcome script for the first pane
welcome_script() {
    cat <<EOF
# Welcome script from function
msg_header "\${APP_NAME} v\${APP_VERSION}"
msg_bg_blue "Welcome to \${SESSION_NAME}!"
msg_info "This is the main pane (0)"

# Display system information
echo "Host: \${HOSTNAME}"
echo "User: \${USER_NAME}"
echo "Date: \${CURRENT_DATE}"

msg_yellow "Wait 3 seconds for next pane creation..."
EOF
}

# Info script for system information display
info_script() {
    cat <<EOF
msg_bg_green "Hello from function-defined script!"
echo "-----------------------------------"
msg_info "System Information:"
echo "Current directory: \$(pwd)"
echo "TMUX Session: \$(tmux display-message -p '#S')"
echo "TMUX Pane: \$(tmux display-message -p '#P')"

# Demonstrate we can access variables from the parent script
echo "Session from parent script: \${SESSION_NAME}"

msg_yellow "Wait 3 seconds for next pane creation..."
EOF
}

# Countdown script with self-destruct capability
countdown_script() {
    cat <<EOF
msg_bg_magenta "Hello from function-defined script!"
msg_info "This pane demonstrates the self-destruct feature"
msg_warning "This session will self-destruct in 10 seconds..."
echo "To cancel, press Ctrl+C now"

# Countdown
for i in {10..1}; do
    echo "Self-destruct in \$i seconds..."
    sleep 1
done

msg_error "Initiating self-destruct!"
sleep 1
# Call the self-destruct function
tmux_self_destruct
EOF
}

# File monitoring script
file_monitor_script() {
    cat <<EOF
msg_bg_cyan "File Monitor"
msg_info "This pane will monitor file changes in the current directory"

# Set up monitoring loop
watch_dir="\${WATCH_DIR:-\$(pwd)}"
msg_info "Monitoring directory: \$watch_dir"
echo "Press Ctrl+C to stop monitoring"

while true; do
    echo "----------------------------------------"
    echo "Last modified files (last 5):"
    find "\$watch_dir" -type f -printf "%TY-%Tm-%Td %TH:%TM:%TS %p\n" | sort -r | head -5
    sleep 5
done
EOF
}

# Process monitor script
process_monitor_script() {
    cat <<EOF
msg_bg_yellow "Process Monitor"
msg_info "This pane will monitor system processes"

# Set up monitoring loop
watch_process="\${WATCH_PROCESS:-bash}"
msg_info "Monitoring processes matching: \$watch_process"
echo "Press Ctrl+C to stop monitoring"

while true; do
    echo "----------------------------------------"
    echo "Current processes:"
    ps aux | grep "\$watch_process" | grep -v grep
    sleep 3
done
EOF
}

# Help/usage script
help_script() {
    cat <<EOF
msg_header "TMUX Session Help"
msg_info "Available commands in this session:"
echo "- tmux_self_destruct    : Close this session"
echo "- pwd                   : Show current directory"
echo "- ls                    : List files"
echo "- cd DIR                : Change directory"
echo "- echo \$SESSION_NAME    : Show session name"
echo ""
msg_yellow "This session will remain active until closed."
EOF
} 