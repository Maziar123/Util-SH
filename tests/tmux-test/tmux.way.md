# tmux.way

Some useful special ways for me when working with tmux panes, focusing on using IDs and Titles instead of dynamic indexes.

---

## Getting Pane Index

You can retrieve the numerical index of a pane using its unique ID or its title.

### By Pane ID

Use the pane ID (e.g., `%0`, `%1`) to find its index:

```sh
# General command
tmux list-panes -F "#{pane_id}|#{pane_index}" | grep -m1 '^%ID|' | cut -d'|' -f2
# Replace "%ID" with the actual ID (e.g., "%1")

# Example: Get index for pane %2
tmux list-panes -F "#{pane_id}|#{pane_index}" | grep -m1 '^%2|' | cut -d'|' -f2
```

**Explanation:**

- `tmux list-panes -F "#{pane_id}|#{pane_index}"`: Lists all panes, outputting `pane_id|pane_index`.
- `grep -m1 '^%ID|'`: Filters for the line starting with the specific pane ID followed by `|`. `-m1` ensures only the first match is taken.
- `cut -d'|' -f2`: Extracts the second field (the pane index) using `|` as the delimiter.

### By Pane Title

Use the pane's exact title to find its index:

```sh
# General command
tmux list-panes -F "#{pane_title}|#{pane_index}" | grep -m1 '^TITLE|' | cut -d'|' -f2
# Replace "TITLE" with the exact pane title

# Example: Get index for pane titled "PANE 1 TITLE"
tmux list-panes -F "#{pane_title}|#{pane_index}" | grep -m1 '^PANE 1 TITLE|' | cut -d'|' -f2
```

**Explanation:**

- `tmux list-panes -F "#{pane_title}|#{pane_index}"`: Lists all panes, outputting `pane_title|pane_index`.
- `grep -m1 '^TITLE|'`: Filters for the line starting with the exact title followed by `|`.
- `cut -d'|' -f2`: Extracts the pane index.

---

## Setting Pane Title

You can assign a custom title to the currently selected pane:

```bash
tmux select-pane -T "NEW_TITLE"
# Replace "NEW_TITLE" with your desired title
```

---

## Kill a Pane by ID (from outside tmux)

This shell function finds a pane by its ID across all sessions and windows, then kills it. It can be run from outside a tmux session.

```sh
# Function to kill a tmux pane by its ID
# Usage: tmx_kill_pane_by_id %PANE_ID
# Example: tmx_kill_pane_by_id %3
tmx_kill_pane_by_id() {
    local pane_id="$1"
    local target_pane

    if [[ -z "$pane_id" ]]; then
        echo "Usage: tmx_kill_pane_by_id %PANE_ID" >&2
        return 1
    fi

    # Find the target pane specification (session:window.pane) using the pane ID
    # -a lists all sessions
    target_pane=$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_id}' | grep -m1 " ${pane_id}$" | cut -d' ' -f1)

    if [[ -n "$target_pane" ]]; then
        echo "Found pane ${pane_id} at target ${target_pane}. Killing it..."
        tmux kill-pane -t "$target_pane"
    else
        echo "Pane with ID ${pane_id} not found." >&2
        return 1
    fi
}

# Example usage:
# tmx_kill_pane_by_id %5
```

**Explanation:**

1. **`local pane_id="$1"`**: Stores the first argument (the pane ID) in a local variable.
2. **Input Validation**: Checks if a pane ID was provided.
3. **`tmux list-panes -a -F **'#{session_name}:#{window_index}.#{pane_index}** #{pane_id}'`**: Lists all panes across all sessions (`-a`). The format (`-F`) outputs the full target specifier (`session:window.pane`) followed by the pane ID.
4. **`grep -m1 " ${pane_id}$"`**: Filters the output to find the line that ends with the exact pane ID (space prefix ensures we don't match partial IDs like `%1` when searching for `%12`). `-m1` stops after the first match.
5. **`cut -d' ' -f1`**: Extracts the first field (the target specifier) using space as the delimiter.
6. **`if [[ -n "$target_pane" ]]`**: Checks if a target pane was found.
7. **`tmux kill-pane -t "$target_pane"`**: If found, kills the pane using its target specifier.
8. **Error Handling**: If no pane is found, prints an error message.

---

## Example Workflow & Notes

1. **List Panes**: To see current IDs, titles, and indexes:

    ```bash
    tmux list-panes -F 'ID: #{pane_id} | Title: #{pane_title} | Index: #{pane_index}'
    ```

2. **Get Index Example (ID)**: Get index for pane `%3`:

    ```bash
    tmux list-panes -F "#{pane_id}|#{pane_index}" | grep -m1 '^%3|' | cut -d'|' -f2
    ```

3. **Get Index Example (Title)**: Get index for title "logs":

    ```bash
    tmux list-panes -F "#{pane_title}|#{pane_index}" | grep -m1 '^logs|' | cut -d'|' -f2
    ```

### Important Notes

- Pane **indexes are dynamic** and **change** as panes are created or destroyed. Using IDs or titles provides a more stable way to reference panes.
- Use `-m1` in `grep` to match only the first occurrence if multiple panes might potentially match (though IDs should be unique).
- Pane titles can be empty or non-unique, which might affect lookup by title. IDs are always unique.
