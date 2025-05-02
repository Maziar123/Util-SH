#!/usr/bin/env bash
# Test script to verify key input handling

SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"
source "${SCRIPT_DIR}/tmux_utils1.sh"
sh-globals_init "$@"

echo "Starting key input test..."
echo "Press keys to test input handling:"
echo "- Press 'q' to quit"
echo "- Press number keys (1-9) to test digit handling"
echo "- Press any other key to see its value"

# Set up terminal for raw input
stty -echo

try_count=0
while true; do
  try_count=$((try_count + 1))
  echo -n "Try #${try_count}: Waiting for key... "
  
  # Use simple, direct non-blocking read with proper error handling
  key=""
  if ! read -t 0.1 -N 1 key </dev/tty; then
    # This is the timeout case
    echo "No key detected (timeout)"
  else
    # Key was pressed
    echo "Got key: '${key}' (ASCII: $(printf "%d" "'$key"))"
    
    # Demonstrate handling different key types
    case "$key" in
      q)
        echo "Quitting as requested"
        break
        ;;
      [0-9])
        echo "Digit key pressed: $key - would handle pane $key"
        ;;
      *)
        echo "Other key pressed: $key"
        ;;
    esac
  fi
  
  sleep 1
done

# Restore terminal settings
stty echo
echo "Test complete" 