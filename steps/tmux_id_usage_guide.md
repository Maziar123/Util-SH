# Tmux Pane ID Reference Guide

## Why Use Pane IDs?

Tmux uniquely identifies panes with stable IDs in the format `%N` (where N is a number). Unlike pane indices, these IDs:

1. **Remain stable** when other panes are created or deleted
2. **Prevent confusion** when referencing panes that have been reindexed
3. **Allow precise targeting** of specific panes across sessions

## Key Functions for Working with Pane IDs

The `tmux_utils1.sh` library now fully supports pane IDs throughout:

### Core Functions

- `tmx_create_pane`: Creates a new pane and returns its ID
- `tmx_get_pane_id`: Converts a pane index to its stable ID
- `tmx_kill_pane_by_id`: Kills a pane by its ID (most reliable method)

### Execution Functions

All execution functions now accept either pane indices (for backward compatibility) or pane IDs:

- `tmx_execute_script`: Execute a script in a pane
- `tmx_execute_function`: Execute a function-defined script in a pane
- `tmx_execute_file`: Execute a script file in a pane
- `tmx_execute_shell_function`: Execute a shell function in a pane
- `tmx_execute_in_pane`: Execute a command in a pane
- `tmx_send_text`: Send text to a pane without executing
- `tmx_execute_all_panes`: Execute a command in all panes, with option to skip specific pane IDs

### Pane Management

- `tmx_pane_function`: Create or reuse a pane for a shell function (combined function)

## In-Script Helper Functions

The `tmx_generate_script_boilerplate` function now includes the following helper functions that are available in all generated scripts:

- `tmx_get_current_pane_id()`: Get the ID of the current pane
- `tmx_get_current_pane_index()`: Get the index of the current pane  
- `tmx_index_to_id(pane_index)`: Convert a pane index to its ID
- `tmx_id_to_index(pane_id)`: Convert a pane ID to its current index
- `tmx_kill_pane_by_id(pane_id)`: Kill a pane by its ID

These functions enable scripts running within tmux panes to work with pane IDs directly.

## Usage Examples

### Creating and Using Panes

```bash
# Create a session
session_name="test_session"
tmx_create_session "${session_name}"

# Create a pane and remember its ID
pane1_id=$(tmx_create_pane "${session_name}" "v")  # Vertical split
echo "Created pane with ID: ${pane1_id}"

# Create another pane
pane2_id=$(tmx_create_pane "${session_name}" "h")  # Horizontal split

# Execute a command in the first pane using its ID
tmx_execute_script "${session_name}" "${pane1_id}" <<EOF
echo "This is pane ${pane1_id}"
date

# We can use the helper functions included in the script boilerplate
MY_ID=\$(tmx_get_current_pane_id)
MY_INDEX=\$(tmx_get_current_pane_index)
echo "Confirmed ID: \${MY_ID}, Current index: \${MY_INDEX}"
EOF

# Kill the second pane by ID
tmx_kill_pane_by_id "${pane2_id}"

# The first pane's ID remains valid even after the second is deleted
tmx_execute_script "${session_name}" "${pane1_id}" <<EOF
echo "Still here after the other pane was deleted!"
EOF
```

### Using tmx_pane_function

The recommended way to create and execute functions in panes:

```bash
# Define a function
my_counter() {
    local session="$1"
    local count=0
    
    # Get our own pane information using the helper functions
    local self_id=$(tmx_get_current_pane_id)
    local self_index=$(tmx_get_current_pane_index)
    
    echo "Running in pane ID: ${self_id}, index: ${self_index}"
    
    while [ $count -lt 10 ]; do
        echo "Count: $count"
        count=$((count + 1))
        sleep 1
    done
}

# Create a session
session_name="demo_session"
tmx_create_session "${session_name}"

# Create a pane and run the function in it - returns the pane ID
pane_id=$(tmx_pane_function "${session_name}" my_counter "v" "" "${session_name}")

# Later, you can run another function in the same pane by ID
another_function() {
    echo "Running in the same pane by ID"
    
    # We can kill ourselves using the helper function
    echo "This pane will self-destruct in 3 seconds..."
    sleep 3
    tmx_kill_pane_by_id "$(tmx_get_current_pane_id)"
}
tmx_pane_function "${session_name}" another_function "${pane_id}" ""
```

### Executing in All Panes Except Specific Ones

```bash
# Create session and panes
session_name="multi_pane_demo"
tmx_create_session "${session_name}"

# Create some panes and get their IDs
control_id=$(tmx_get_current_pane_id)  # Current pane ID
pane1_id=$(tmx_create_pane "${session_name}" "v")
pane2_id=$(tmx_create_pane "${session_name}" "h")
pane3_id=$(tmx_create_pane "${session_name}" "h")

# Execute a command in all panes EXCEPT the control pane
tmx_execute_all_panes "${session_name}" 0 "echo 'This runs in all panes except the control'" "${control_id}"

# Execute in all panes except panes 1 and 3
tmx_execute_all_panes "${session_name}" 0 "echo 'Not in panes 1 or 3'" "${pane1_id} ${pane3_id}"
```

### Control Pane with IDs

The control pane now tracks panes by ID, making it resilient to pane deletion:

```bash
# Store pane IDs in session variables for the control pane
tmx_var_set "pane_id_1" "${pane1_id}" "${session_name}"
tmx_var_set "pane_id_2" "${pane2_id}" "${session_name}"

# Create a control pane that can monitor and manage these panes
tmx_control_pane "${session_name}" "counter1 counter2 pane_id_1 pane_id_2" "1 2" "h" "1"
```

## Debugging Tips

When working with pane IDs, these commands can help understand the current state:

```bash
# List all panes with their IDs and indices
tmux list-panes -F "#{pane_index} #{pane_id}"

# Find a pane's index from its ID
tmux list-panes -F "#{pane_id}:#{pane_index}" | grep "^%123:" | cut -d: -f2

# List all panes in all sessions with their IDs
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_id}"

# Inside scripts, use the helper functions
CURRENT_ID=$(tmx_get_current_pane_id)
CURRENT_INDEX=$(tmx_get_current_pane_index)
```

## Best Practices

1. **Always store pane IDs** rather than indices when they'll be used later
2. **Use tmx_kill_pane_by_id** when killing panes for reliability
3. **Pass pane IDs with %** prefix (e.g., %0, %1) to make the ID format explicit
4. **Use tmx_var_set with pane_id_N** naming convention to store IDs for control panes
5. **Use the in-script helper functions** to make your scripts more resilient
6. **Skip specific panes by ID** with the enhanced tmx_execute_all_panes function 