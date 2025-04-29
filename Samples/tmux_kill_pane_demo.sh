#!/usr/bin/env bash
# ===================================================================
# tmux_kill_pane_demo.sh - Demonstrate precise pane killing in tmux
# ===================================================================
# DESCRIPTION:
#   This script demonstrates how to correctly kill specific panes
#   in a tmux session without affecting other panes.
#
# USAGE:
#   ./tmux_kill_pane_demo.sh [--headless]
#   Options:
#     --headless    Create session without launching a terminal
#
# FEATURES:
#   - Creates a test session with 3 colored panes
#   - Provides a control pane to test killing panes by index
#   - Shows status of each pane and confirms successful kills
# ===================================================================

SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"
source "${SCRIPT_DIR}/tmux_utils1.sh"
sh-globals_init "$@"

# Print header
msg_info "=== TMUX PANE KILL DEMO ==="
msg_info "This script will create a test session with 3 panes and let you kill them one by one."

# Create test session
SESSION_NAME="kill_demo_$(date +%s)"
if ! tmx_create_session "${SESSION_NAME}" "$1"; then
    msg_error "Failed to create test session"
    exit 1
fi

msg_success "Created test session: ${SESSION_NAME}"

# Create 3 test panes that just show numbers
create_test_pane() {
    local pane_num="$1"
    
    # Just display a number and update it
    local count=0
    while true; do
        clear
        echo -e "\033[1;3${pane_num}m=== PANE ${pane_num} ===\033[0m"
        echo "Count: $count"
        echo ""
        echo "This pane will be killed when requested"
        
        count=$((count + 1))
        sleep 1
    done
}

# Create the test panes
msg_info "Creating test panes..."

# Create first pane (vertical split)
P1=$(tmx_pane_function "${SESSION_NAME}" create_test_pane "v" "" "1")
msg_info "Created pane $P1 (vertical split)"

# Create second pane (horizontal split)
P2=$(tmx_pane_function "${SESSION_NAME}" create_test_pane "h" "" "2") 
msg_info "Created pane $P2 (horizontal split)"

# Create third pane (horizontal split)
P3=$(tmx_pane_function "${SESSION_NAME}" create_test_pane "h" "" "3")
msg_info "Created pane $P3 (horizontal split)"

# Control function that tests killing panes
control_test() {
    local session_name="$1"
    
    msg_info "Control pane active. Commands:"
    msg_info "1 - Kill pane 1"
    msg_info "2 - Kill pane 2" 
    msg_info "3 - Kill pane 3"
    msg_info "l - List active panes"
    msg_info "q - Quit test"
    
    # Define the kill_pane function locally
    local_kill_pane() {
        local session="$1"
        local pane="$2"
        
        if [[ -z "${session}" || -z "${pane}" ]]; then
            msg_error "Kill pane failed: Missing session name or pane index"
            return 1
        fi
        
        msg_info "Trying to kill pane ${pane} in session ${session}"
        
        # Get the exact pane ID for the specified pane index
        local target_pane_id=""
        # List panes with format: "pane_index pane_id" 
        local pane_list=$(tmux list-panes -t "${session}" -F "#{pane_index} #{pane_id}")
        
        # Extract the specific pane ID we want to kill
        while read -r index id; do
            if [[ "$index" == "$pane" ]]; then
                target_pane_id="$id"
                msg_info "Found target pane $pane with ID $target_pane_id"
                break
            fi
        done <<< "$pane_list"
        
        # If we found a specific pane ID, kill only that pane
        if [[ -n "$target_pane_id" ]]; then
            msg_info "Killing pane with ID $target_pane_id"
            if tmux kill-pane -t "$target_pane_id"; then
                msg_success "Killed pane ${pane} (ID: $target_pane_id)"
                return 0
            else
                msg_error "Failed to kill pane ${pane} using ID $target_pane_id"
            fi
        else
            msg_warning "Could not find pane ${pane} in session ${session}"
        fi
        
        # Fallback methods if we couldn't find the pane ID
        msg_info "Trying fallback methods for pane ${pane}"
        
        # Try fully-qualified target
        if tmux kill-pane -t "${session}:0.${pane}" 2>/dev/null; then
            msg_success "Killed pane ${pane} using fallback method"
            return 0
        fi
        
        # Try using % prefix (another way to specify panes)
        if tmux kill-pane -t "%${pane}" 2>/dev/null; then
            msg_success "Killed pane ${pane} using % prefix method"
            return 0
        fi
        
        msg_error "All methods failed to kill pane ${pane}"
        return 1
    }
    
    while true; do
        echo -n "Enter command: "
        read -r cmd
        
        case "$cmd" in
            1|2|3)
                msg_info "Attempting to kill pane $cmd..."
                if local_kill_pane "${session_name}" "$cmd"; then
                    msg_success "Successfully killed pane $cmd"
                else
                    msg_error "Failed to kill pane $cmd"
                fi
                ;;
            l)
                msg_info "Active panes:"
                tmux list-panes -t "${session_name}" -F "#{pane_index} #{pane_id}"
                ;;
            q)
                msg_warning "Exiting test. Killing session ${session_name}"
                tmux kill-session -t "${session_name}"
                exit 0
                ;;
            *)
                msg_error "Unknown command: $cmd"
                ;;
        esac
    done
}

# Run control function in pane 0
tmx_pane_function "${SESSION_NAME}" control_test "0" "" "${SESSION_NAME}"

# Keep script running
echo "Demo running in session: ${SESSION_NAME} - Press Ctrl+C to exit"
while true; do sleep 1; done 