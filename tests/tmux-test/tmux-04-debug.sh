#!/usr/bin/env bash
#
# Modified version of tmux-04.sh for debugging
# Skips the tmux attach commands that would block the debugger

set -euo pipefail
SESSION="test"
WINDOW=0

# 1) Clean up any old session
echo; echo ">> Killing existing session '${SESSION}' (if any)…"
tmux kill-session -t "${SESSION}" 2>/dev/null || true

# 2) Create a new, detached session with one pane
echo; echo ">> Creating new session '${SESSION}' (detached)…"
tmux new-session -d -s "${SESSION}" -n main

echo "   - list-sessions: $(tmux list-sessions)"
echo "   - list-windows: $(tmux list-windows -t "${SESSION}")"
echo "   - list-panes:   $(tmux list-panes   -t "${SESSION}")"

echo
echo "1) INITIAL: Created single pane (pane 0)."
echo "   [DEBUGGING: Skipped tmux attach]"
# Removed: tmux attach -t "${SESSION}"

# 3) Split pane 0 horizontally → creates pane 1
echo; echo "2) Splitting pane 0 horizontally…"
tmux split-window -h -t "${SESSION}:${WINDOW}.0"

echo "   - list-windows: $(tmux list-windows -t "${SESSION}")"
echo "   - list-panes:   $(tmux list-panes   -t "${SESSION}")"

echo
echo "2) AFTER H-SPLIT: Created panes 0 & 1."
echo "   [DEBUGGING: Skipped tmux attach]"
# Removed: tmux attach -t "${SESSION}"

# 4) Split pane 1 vertically → creates pane 2
echo; echo "3) Splitting pane 1 vertically…"
tmux split-window -v -t "${SESSION}:${WINDOW}.1"

echo "   - list-windows: $(tmux list-windows -t "${SESSION}")"
echo "   - list-panes:   $(tmux list-panes   -t "${SESSION}")"

echo
echo "3) AFTER V-SPLIT: Created panes 0, 1 & 2."
echo "   [DEBUGGING: Skipped tmux attach]"
# Removed: tmux attach -t "${SESSION}"

# 5) Kill pane 2
echo; echo "4) Killing pane 2…"
tmux kill-pane -t "${SESSION}:${WINDOW}.2"

echo "   - list-panes:   $(tmux list-panes   -t "${SESSION}")"

echo
echo "4) AFTER KILL PANE 2: Remaining panes 0 & 1 renumbered."
echo "   [DEBUGGING: Skipped tmux attach]"
# Removed: tmux attach -t "${SESSION}"

# 6) Kill pane 1
echo; echo "5) Killing pane 1…"
tmux kill-pane -t "${SESSION}:${WINDOW}.1"

echo "   - list-panes:   $(tmux list-panes   -t "${SESSION}")"

echo
echo "5) FINAL: Only pane 0 remains."
echo "   [DEBUGGING: Skipped tmux attach]"
# Removed: tmux attach -t "${SESSION}" 

# Add a command to show the final tmux session (without attaching)
echo; echo "Final tmux session state:"
tmux display-message -t "${SESSION}" -p "#{session_name} with #{window_panes} pane(s)"

# Add an option to clean up
echo; echo "Do you want to kill the tmux session? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    tmux kill-session -t "${SESSION}"
    echo "Session killed."
else
    echo "Session '${SESSION}' is still running. Kill it manually when done."
fi 