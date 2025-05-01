#!/bin/bash
# tmux_pane_test.sh - A script to demonstrate tmux pane indexing behavior

# Function to show pane details
show_pane_details() {
  echo "=== STEP: \$1 ==="
  echo "Pane listing (tmux list-panes):"
  tmux list-panes
  echo ""
  echo "Pane details with indices (tmux list-panes -F '#{pane_index} #{pane_id}'):"
  tmux list-panes -F "#{pane_index} #{pane_id} - running: #{pane_current_command}"
  echo "-----------------------------------"
}

# Start a new tmux session if not already in one
if [ -z "$TMUX" ]; then
  echo "Starting a new tmux session for testing..."
  tmux new-session -d -s pane_test
  tmux send-keys -t pane_test "bash \$0" C-m
  tmux attach -t pane_test
  exit 0
fi

# Clear screen and explain test
clear
echo "TMUX PANE INDEX TEST"
echo "This script demonstrates what happens to pane indices when a pane is killed."
echo ""
echo "Press ENTER to start the test..."
read

# Initial state - one pane
show_pane_details "Initial state (one pane)"

# Split horizontally to create pane 1
tmux split-window -h
echo "Created pane 1 with horizontal split"
show_pane_details "After creating pane 1 (horizontal split)"

# Split vertically to create pane 2
tmux split-window -v
echo "Created pane 2 with vertical split"
show_pane_details "After creating pane 2 (vertical split)"

# Show which pane is active
active_pane=$(tmux display-message -p "#{pane_index}")
echo "Active pane is: $active_pane"
echo ""

# Pause for user to observe
echo "Press ENTER to kill pane 1..."
read

# Kill pane 1
tmux kill-pane -t 1
echo "Killed pane 1"
show_pane_details "After killing pane 1"

# Pause for user to observe
echo "Press ENTER to exit the script..."
read

# Clean up - only if we started the session
if [ "$(tmux display-message -p "#{session_name}")" = "pane_test" ]; then
  tmux kill-session -t pane_test
fi
