#!/usr/bin/env bash
#
# test_tmux_panes.sh
# Step through tmux pane creation, killing, and renumbering,
# pausing at each step so you can SEE the tmux UI.

set -euo pipefail
SESSION="test"
WINDOW=0
PAUSE_AFTER_STEPS=no

# Cleanup any old session --new-tab
tmux kill-session -t "${SESSION}" 2>/dev/null || true

# Open a Konsole tab first for viewing the tmux session
konsole  --workdir "$PWD" -e "bash -c 'echo Starting tmux viewer...; tmux attach -t \"${SESSION}\" || (echo Waiting for session...; while ! tmux has-session -t \"${SESSION}\" 2>/dev/null; do sleep 0.5; done; tmux attach -t \"${SESSION}\")'" &
KONSOLE_PID=$!
sleep 1

# Create a new, detached session with one pane
tmux new-session -d -s "${SESSION}" -n main
tmux rename-window -t "${SESSION}:${WINDOW}" "Pane Test Window"
tmux select-pane -t "${SESSION}:${WINDOW}.0" -T "Pane 0 Title"
tmux send-keys -t "${SESSION}:${WINDOW}.0" "echo 'Pane 0'" C-m

# Show session info
tmux list-sessions | grep "${SESSION}"
tmux list-windows -t "${SESSION}"
tmux list-panes -t "${SESSION}"

# Prompt user to continue (optional)
if [[ "${PAUSE_AFTER_STEPS:-yes}" == "yes" ]]; then
    read -p "Step 1: Initial pane created. Press Enter to continue... " dummy
fi

# Split pane 0 horizontally → creates pane 1
tmux split-window -h -t "${SESSION}:${WINDOW}.0"
tmux select-pane -t "${SESSION}:${WINDOW}.1" -T "Pane 1 Title"
tmux send-keys -t "${SESSION}:${WINDOW}.1" "echo 'Pane 1'" C-m
tmux list-panes -t "${SESSION}"

# Prompt user to continue (optional)
if [[ "${PAUSE_AFTER_STEPS:-yes}" == "yes" ]]; then
    read -p "Step 2: Horizontal split created pane 1. Press Enter to continue... " dummy
fi

# Split pane 1 vertically → creates pane 2
tmux split-window -v -t "${SESSION}:${WINDOW}.1"
tmux select-pane -t "${SESSION}:${WINDOW}.2" -T "Pane 2 Title"
tmux send-keys -t "${SESSION}:${WINDOW}.2" "echo 'Pane 2'" C-m
tmux list-panes -t "${SESSION}"

# Prompt user to continue (optional)
if [[ "${PAUSE_AFTER_STEPS:-yes}" == "yes" ]]; then
    read -p "Step 3: Vertical split created pane 2. Press Enter to continue... " dummy
fi

# Show session info
tmux list-sessions | grep "${SESSION}"
tmux list-windows -t "${SESSION}"
tmux list-panes -t "${SESSION}"

# Interactively kill panes
while true; do
    echo "-----------------------------------------------------"
    echo "Current Panes:"
    tmux list-sessions | grep "${SESSION}" || true
    tmux list-windows -t "${SESSION}" || true
    tmux list-panes -t "${SESSION}" || true
    echo "-----------------------------------------------------"

    read -p "Enter pane index to kill (e.g., 1) or 'x' to exit: " pane_index_to_kill

    # Convert to lowercase for case-insensitive comparison
    user_choice=$(echo "$pane_index_to_kill" | tr '[:upper:]' '[:lower:]')

    if [[ "$user_choice" == "x" ]]; then
        echo "Exiting kill loop."
        break
    fi

    # Basic validation: check if it's a number
    if ! [[ "$pane_index_to_kill" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a number or 'x'."
        continue
    fi

    echo "Attempting to kill pane ${pane_index_to_kill}..."
    tmux kill-pane -t "${SESSION}:${WINDOW}.${pane_index_to_kill}" || echo "Failed to kill pane ${pane_index_to_kill}. It might not exist."

    echo "Pane list after attempting kill:"
    tmux list-panes -t "${SESSION}" || true # Show panes even if window/session is gone
    sleep 1 # Pause briefly to see the result
done

# Prompt user to continue (optional)
if [[ "${PAUSE_AFTER_STEPS:-yes}" == "yes" ]]; then
    read -p "Step 4: Finished interactive pane killing. Press Enter to continue... " dummy
fi

# Final pause
if [[ "${PAUSE_AFTER_STEPS:-yes}" == "yes" ]]; then
    read -p "Step 5: Final state with only pane 0 remaining. Press Enter to finish... " dummy
fi

echo "Done. tmux session \"${SESSION}\" is still running."
echo "Run 'tmux attach -t \"${SESSION}\"' to view it again."
