#!/bin/bash

# Script to demonstrate tmux pane re-indexing after killing a pane

SESSION_NAME="pane_test_$$" # Use PID to make session name unique
INITIAL_PANE_TARGET="${SESSION_NAME}:0.0" # Target format: session:window.pane

echo "--- Starting Test ---"
echo "INFO: Creating a new detached tmux session named '${SESSION_NAME}'"
tmux new-session -d -s "$SESSION_NAME" -x 100 -y 20 # Create small detached session

echo "INFO: Session created. Initial state (1 pane):"
tmux list-panes -t "${SESSION_NAME}:0" -F '#{session_name}:#{window_index}.#{pane_index} Active:#{pane_active} PID:#{pane_pid}'
echo "---------------------"
sleep 1 # Small pause for clarity

echo "INFO: Splitting window 0 horizontally (Pane 0 -> Pane 0 + Pane 1)"
tmux split-window -h -t "$INITIAL_PANE_TARGET"

echo "INFO: State after first split (2 panes):"
tmux list-panes -t "${SESSION_NAME}:0" -F '#{session_name}:#{window_index}.#{pane_index} Active:#{pane_active} PID:#{pane_pid}'
echo "---------------------"
sleep 1

# The new pane (1) becomes the active one by default after split-window
# Let's split the *second* pane (index 1) vertically
SECOND_PANE_TARGET="${SESSION_NAME}:0.1"
echo "INFO: Splitting the second pane (index 1) vertically (Pane 1 -> Pane 1 + Pane 2)"
tmux split-window -v -t "$SECOND_PANE_TARGET"

echo "INFO: State after second split (3 panes - should be 0, 1, 2):"
tmux list-panes -t "${SESSION_NAME}:0" -F '#{session_name}:#{window_index}.#{pane_index} Active:#{pane_active} PID:#{pane_pid}'
echo "---------------------"
sleep 1

# Target the middle pane (index 1) for killing
PANE_TO_KILL="${SESSION_NAME}:0.1"
echo "INFO: Killing the middle pane (index 1) -> Target: ${PANE_TO_KILL}"
tmux kill-pane -t "$PANE_TO_KILL"

echo "INFO: State after killing pane 1:"
tmux list-panes -t "${SESSION_NAME}:0" -F '#{session_name}:#{window_index}.#{pane_index} Active:#{pane_active} PID:#{pane_pid}'
echo "OBSERVE: The original pane 2 should now be pane 1."
echo "---------------------"
sleep 1

echo "INFO: Cleaning up: Killing session '${SESSION_NAME}'"
tmux kill-session -t "$SESSION_NAME"

echo "--- Test Complete ---"
