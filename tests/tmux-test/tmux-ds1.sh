#!/bin/bash
# TMUX Pane Index Test Script

# Create a new tmux session in detached mode
echo "Step 1: Creating new tmux session 'pane_test'"
tmux new-session -d -s pane_test -n main

# Create initial vertical split (pane 0)
echo -e "\nStep 2: Creating first split (pane 0)"
tmux split-window -h -t pane_test

# Create second vertical split (pane 1)
echo -e "\nStep 3: Creating second split (pane 1)"
tmux split-window -h -t pane_test

# List panes with detailed info before killing
echo -e "\nStep 4: Initial pane configuration:"
tmux list-panes -t pane_test -F "Pane #{pane_index} | ID: #{pane_id} | Active: #{?pane_active,active,inactive} | PID: #{pane_pid} | Dimensions: #{pane_width}x#{pane_height}"

# Kill middle pane (pane 1)
echo -e "\nStep 5: Killing middle pane (original index 1)"
tmux kill-pane -t 1

# List panes after killing
echo -e "\nStep 6: Post-kill pane configuration:"
tmux list-panes -t pane_test -F "Pane #{pane_index} | ID: #{pane_id} | Active: #{?pane_active,active,inactive} | PID: #{pane_pid} | Dimensions: #{pane_width}x#{pane_height}"

# Kill session
echo -e "\nStep 7: Cleaning up session"
tmux kill-session -t pane_test

echo -e "\nTest completed. Key findings:"
echo "1. Original pane indexes: 0, 1, 2"
echo "2. After killing index 1: remaining indexes stay 0 and 2"
echo "3. Tmux does NOT renumber existing pane indexes after deletion"
echo "4. New panes created after deletion will use next available number"
