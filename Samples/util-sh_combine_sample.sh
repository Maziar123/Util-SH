#!/usr/bin/env bash
# util-sh_combine_sample.sh - Combined example of utilities
# Demonstrates param handling and tmux session control
# shellcheck disable=SC1091,SC2317,SC2155,SC2034,SC2250,SC2162,SC2312

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the libraries (in the correct order)
source "${SCRIPT_DIR}/sh-globals.sh"
source "${SCRIPT_DIR}/param_handler.sh"
source "${SCRIPT_DIR}/tmux_base_utils.sh"
source "${SCRIPT_DIR}/tmux_script_generator.sh" 
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals with script arguments - this sets _MAIN_SCRIPT_NAME
sh-globals_init "$@"

# Initialize logging if not already initialized
[[ $_LOG_INITIALIZED -eq 0 ]] && log_init "" 0

# Set up logging - now get_script_name will return the correct script name
log_info "Starting script: $(get_script_name)"

# Print a header for the script
msg_header "TMUX CONTROL DEMO (Combined Example)"
msg_section "Environment Setup" 60 "-"

# Check dependencies
msg_info "Checking dependencies..."
if ! check_dependencies tmux; then
  msg_error "Missing required dependency: tmux"
  exit 1
fi

# Define parameters with param_handler
declare -a PARAMS=(
  "name:SESSION_NAME:session:Tmux session name (default: control_demo_TIMESTAMP)"
  "headless:HEADLESS:Run in headless mode (no terminal launch)"
)

# Process parameters
if ! param_handler::simple_handle PARAMS "$@"; then
  exit 1  # Help was shown or parameter validation failed
fi

# Set defaults for optional parameters
SESSION_NAME="${SESSION_NAME:-control_demo_$(date +%s)}"
LAUNCH_TERMINAL="true"
[[ -n "$HEADLESS" ]] && LAUNCH_TERMINAL="false"

# === Counter pane functions ===
# Green counter: Increments by 2 every second
Green() {
    local session="$1"
    while true; do
        local current_green=$(tmx_var_get "counter_green" "$session" 2>/dev/null || echo 0)
        local v=$((current_green + 2))
        tmx_var_set "counter_green" "$v" "$session"
        clear
        msg_bg_green "GREEN COUNTER (PANE 1)"
        msg_green "Value: ${v}"
        msg_green "Press '1' in control pane to close"
        sleep 1
    done
}

# Blue counter: Increments by 3 every 2 seconds
Blue() {
    local session="$1"
    while true; do
        local current_blue=$(tmx_var_get "counter_blue" "$session" 2>/dev/null || echo 0)
        local v=$((current_blue + 3))
        tmx_var_set "counter_blue" "$v" "$session"
        clear
        msg_bg_blue "BLUE COUNTER (PANE 2)"
        msg_blue "Value: ${v}"
        msg_blue "Press '2' in control pane to close"
        sleep 2
    done
}

# Yellow counter: Increments by 5 every 3 seconds
Yellow() {
    local session="$1"
    while true; do
        local current_yellow=$(tmx_var_get "counter_yellow" "$session" 2>/dev/null || echo 0)
        local v=$((current_yellow + 5))
        tmx_var_set "counter_yellow" "$v" "$session"
        clear
        msg_bg_yellow "YELLOW COUNTER (PANE 3)"
        msg_yellow "Value: ${v}"
        msg_yellow "Press '3' in control pane to close"
        sleep 3
    done
}

# === Shared variables ===
# Define which variables to initialize and track
COUNTER_VARS=("counter_green" "counter_blue" "counter_yellow")

# === Main function ===
main() {
  msg_section "Creating Tmux Session" 60 "-"
  
  # Create the session and initialize counter variables to 0
  msg_info "Creating tmux session: $SESSION_NAME"
  if ! tmx_create_session_with_vars "$SESSION_NAME" COUNTER_VARS 0 "$LAUNCH_TERMINAL"; then
    msg_error "Failed to create tmux session '$SESSION_NAME'"
    exit 1
  fi
  
  # Get the actual session name used (might be different if handled duplicates)
  local actual_session_name="${TMX_SESSION_NAME}"
  msg_success "Tmux session '$actual_session_name' created"

  # Create panes and run counter functions in them with auto-registration
  msg_info "Creating counter panes..."
  local p1_id=$(tmx_new_pane_func Green "$actual_session_name" "Green Counter")
  local p2_id=$(tmx_new_pane_func Blue "$actual_session_name" "Blue Counter")
  local p3_id=$(tmx_new_pane_func Yellow "$actual_session_name" "Yellow Counter")
  
  # Use pane 0 (the first pane) as the control pane
  msg_info "Creating monitoring control pane..."
  local p0_id=$(tmx_create_monitoring_control "$actual_session_name" COUNTER_VARS "PANE" "1" "0")
  
  # Make sure titles are enabled
  tmx_enable_pane_titles "$actual_session_name"
  
  # Display session information
  tmx_display_info "$actual_session_name"
  
  # Monitor the session until it terminates
  tmx_monitor_session "$actual_session_name" 0.5 "Monitoring session '$actual_session_name'... Press Ctrl+C to exit."
  
  msg_success "Session closed. Goodbye!"
}

# Run the main function
main
exit $? 