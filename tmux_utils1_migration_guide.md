# tmux_utils1.sh Migration Guide

This guide explains the changes to the naming convention in `tmux_utils1.sh` and how to update your scripts to use the new names.

## New Naming Convention

All functions and variables in `tmux_utils1.sh` have been renamed to follow these rules:

1. All functions now use the `tmx_` prefix (indicates tmux functionality)
2. No "tmux" in function names after the prefix (removes redundancy)
3. Global variables now use `TMX_` prefix (uppercase for globals)

## Function Name Changes

| Old Name | New Name | Description |
|----------|----------|-------------|
| `detect_terminal_emulator` | `tmx_detect_terminal` | Detects available terminal emulator |
| `launch_tmux_terminal` | `tmx_launch_terminal` | Launches a terminal with a tmux session |
| `create_tmux_session` | `tmx_create_session` | Creates a new tmux session |
| `execute_in_pane` | `tmx_execute_in_pane` | Executes a command in a specific pane |
| `execute_script` | `tmx_execute_script` | Executes a multi-line script in a pane |
| `create_new_pane` | `tmx_create_pane` | Creates a new pane in a session |
| `list_tmux_sessions` | `tmx_list_sessions` | Lists active tmux sessions |
| `kill_tmux_session` | `tmx_kill_session` | Kills a tmux session |
| `send_text_to_pane` | `tmx_send_text` | Sends text to a pane without executing |
| `execute_in_all_panes` | `tmx_execute_all_panes` | Executes a command in all panes |
| `session_exists` | `tmx_session_exists` | Checks if a session exists |
| `create_new_window` | `tmx_create_window` | Creates a new window in a session |
| `close_tmux_session` | `tmx_close_session` | Closes a session and cleans up resources |
| `cleanup_all_tmux_sessions` | `tmx_cleanup_all` | Cleans up all sessions and resources |
| `execute_function` | `tmx_execute_function` | Executes a function that returns a script |
| `execute_file` | `tmx_execute_file` | Loads and executes a script from a file |
| `execute_shell_function` | `tmx_execute_shell_function` | Executes a shell function directly |
| `handle_duplicate_session` | `tmx_handle_duplicate_session` | Handles duplicate session names |
| `create_session_with_duplicate_handling` | `tmx_create_session_with_handling` | Creates a session with duplicate handling |
| `t_var_set` | `tmx_var_set` | Sets a tmux environment variable |
| `t_var_get` | `tmx_var_get` | Gets a tmux environment variable |
| `init_tmux_vars_array` | `tmx_init_vars_array` | Initializes multiple environment variables |
| `tmux_self_destruct` | `tmx_self_destruct` | Self-destructs a session (internal function) |

## Global Variable Changes

| Old Name | New Name | Description |
|----------|----------|-------------|
| `TMUX_TERM_EMULATOR` | `TMX_TERM_EMULATOR` | Terminal emulator for launching sessions |
| `TMUX_SESSION_TEMPS` | `TMX_SESSION_TEMPS` | Array to track temporary scripts for sessions |

## New Convenience Functions

| Function Name | Description |
|---------------|-------------|
| `tmx_pane_function` | Unified function to set up panes with functions (replaces multiple separate functions) |

## How to Update Your Scripts

### Basic Usage Update Examples

```bash
# Old code
s=$(create_tmux_session "my_session")
init_tmux_vars_array MY_VARS 0 "$s"
execute_shell_function "$s" 0 my_function "$s"

# New code
s=$(tmx_create_session "my_session")
tmx_init_vars_array MY_VARS 0 "$s"
tmx_execute_shell_function "$s" 0 my_function "$s"
```

### Using tmx_var_set/tmx_var_get

```bash
# Old code
t_var_set "counter" "0" "$session"
count=$(t_var_get "counter" "$session")

# New code
tmx_var_set "counter" "0" "$session"
count=$(tmx_var_get "counter" "$session")
```

### Using the New Unified Pane Function

```bash
# Old way for first pane (pane 0)
execute_shell_function "${s}" 0 monitor_function "$s"

# New way for first pane
p0=$(tmx_pane_function "${s}" monitor_function "0" "$s")

# Old way for new panes
p1=$(create_new_pane "${s}" "v")
execute_shell_function "${s}" "${p1}" counter_function "$s"

# New unified way for new panes
p1=$(tmx_pane_function "${s}" counter_function "v" "$s")
```

## Why These Changes?

1. **Consistency**: The `tmx_` prefix creates a clear namespace for all tmux-related functions.
2. **Clarity**: Removing redundant "tmux" from names makes them shorter and clearer.
3. **Organization**: Functions are now more logically organized with consistent naming.
4. **Simplicity**: The unified `tmx_pane_function` simplifies common operations.

## Additional Notes

- No backward compatibility wrappers are included in the latest version.
- If you need backward compatibility, consider adding your own wrapper functions.
- The sample scripts have been updated to use the new function names. 