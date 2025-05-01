#!/usr/bin/env bash
# ===================================================================
# tmux_pane_id_demo.sh - Demonstrate using pane IDs within tmux scripts
# ===================================================================
# DESCRIPTION:
#   This script demonstrates how to use the new pane ID helper functions
#   that are included in the script boilerplate. It shows:
#     1. Getting the current pane's ID and index
#     2. Creating new panes and tracking them by ID
#     3. Converting between indices and IDs
#     4. Killing specific panes by ID
#
# USAGE:
#   ./tmux_pane_id_demo.sh [--headless]
#   Options:
#     --headless    Create session without launching a terminal
# ===================================================================

SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"
source "${SCRIPT_DIR}/tmux_utils1.sh"
sh-globals_init "$@"

# Check if the first argument is --headless
HEADLESS='' # Default to not headless
if [[ "$1" = "--headless" ]]; then
    HEADLESS=$1
fi

# === PANE FUNCTIONS ===

# Main control pane function
main_control() {
    local session="$1"
    
    # Clear and show intro
    clear
    msg_header "TMUX PANE ID DEMO"
    msg_info "This demo shows how to use pane IDs within tmux scripts."
    msg_info "Current pane information:"
    
    # Use the helper functions from boilerplate
    CURRENT_ID=$(tmx_get_current_pane_id)
    CURRENT_INDEX=$(tmx_get_current_pane_index)
    
    msg_success "Current Pane ID: ${CURRENT_ID}"
    msg_success "Current Pane Index: ${CURRENT_INDEX}"
    
    # Store our pane ID in a tmux variable for demonstration
    tmx_var_set "control_pane_id" "${CURRENT_ID}" "${session}"
    msg_info "Stored control pane ID in tmux variable: control_pane_id=${CURRENT_ID}"
    
    sleep 2
    
    # Create two demonstration panes
    msg_info "Creating two new panes..."
    
    # We'll use tmx_pane_function to create panes and get their IDs
    # But we'll also demonstrate the helper functions inside scripts
    P1=$(tmx_pane_function "${session}" demo_pane "v" "" "${session}" "1")
    P2=$(tmx_pane_function "${session}" demo_pane "h" "" "${session}" "2")
    
    msg_info "Created panes with IDs: ${P1}, ${P2}"
    
    # Store the IDs in tmux variables
    tmx_var_set "demo_pane_id_1" "${P1}" "${session}"
    tmx_var_set "demo_pane_id_2" "${P2}" "${session}"
    
    # Wait a bit to let the user see the demo panes
    sleep 5
    
    msg_info "Demonstrating pane ID usage from within this control script..."
    msg_info "Killing second pane (${P2}) by ID after 3 seconds..."
    sleep 3
    
    # Kill the second pane using our ID
    if tmx_kill_pane_by_id "${P2}"; then
        msg_success "Successfully killed pane ${P2}"
    else
        msg_error "Failed to kill pane ${P2}"
    fi
    
    # Demonstrate internal tmx_var_get
    msg_info "Getting the first pane ID from tmux variable..."
    local p1_id=$(tmx_var_get "demo_pane_id_1" "${session}")
    msg_success "Retrieved ID: ${p1_id}"
    
    # Final demo: kill the last pane and exit
    msg_info "Killing the first pane (${p1_id}) by ID after 3 seconds..."
    sleep 3
    
    if tmx_kill_pane_by_id "${p1_id}"; then
        msg_success "Successfully killed pane ${p1_id}"
    else
        msg_error "Failed to kill pane ${p1_id}"
    fi
    
    msg_header "DEMO COMPLETED"
    msg_info "This demonstrates how to work with pane IDs from within tmux scripts."
    msg_info "The new tmx_generate_script_boilerplate includes the following helper functions:"
    msg_info "- tmx_get_current_pane_id()"
    msg_info "- tmx_get_current_pane_index()"
    msg_info "- tmx_index_to_id()"
    msg_info "- tmx_id_to_index()"
    msg_info "- tmx_kill_pane_by_id()"
    
    sleep 5
    msg_info "Demo complete. Press Ctrl+C to exit."
    while true; do sleep 1; done
}

# Demo pane function
demo_pane() {
    local session="$1"
    local pane_num="$2"
    
    # Get our own pane information
    SELF_ID=$(tmx_get_current_pane_id)
    SELF_INDEX=$(tmx_get_current_pane_index)
    
    # Set a tmux variable from inside this pane
    tmx_var_set "self_set_id_${pane_num}" "${SELF_ID}" "${session}"
    
    # Show pane information
    while true; do
        clear
        msg_cyan "=== DEMO PANE ${pane_num} ==="
        msg_info "Pane ID: ${SELF_ID}"
        msg_info "Pane Index: ${SELF_INDEX}"
        
        # Get the control pane's ID from the tmux variable
        local control_id=$(tmx_var_get "control_pane_id" "${session}")
        
        if [[ -n "${control_id}" ]]; then
            # Convert the control pane ID to its current index
            local control_index=$(tmx_id_to_index "${control_id}")
            msg_success "Control Pane ID: ${control_id} (Index: ${control_index})"
        else
            msg_warning "Control pane ID not found"
        fi
        
        echo ""
        msg_info "This pane will be killed by the control pane as part of the demo"
        
        sleep 1
    done
}

# === MAIN SCRIPT ===
# Create a new tmux session with unique timestamp
session_name="pane_id_demo_$(date +%s)"

# Create the session
if ! tmx_create_session "${session_name}" "$HEADLESS"; then
    msg_error "Failed to create tmux session, exiting."
    exit 1
fi

msg_info "Created session: ${session_name}"

# Start the main control function in the first pane
tmx_first_pane_function "${session_name}" main_control "" "${session_name}"

# Keep parent process alive while the demo runs
echo "Running demo in session: ${session_name}" 
echo "Press Ctrl+C to stop the parent process"
while true; do sleep 1; done 