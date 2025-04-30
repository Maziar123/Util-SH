#!/usr/bin/env bash

# tmux_script_generator.sh - Contains the function to generate scripts for tmux panes

# shellcheck source=./sh-globals.sh
# shellcheck disable=SC1091
source "sh-globals.sh" || { echo "ERROR: Failed to source sh-globals.sh in tmux_script_generator.sh"; exit 1; }
# shellcheck source=./tmux_base_utils.sh
source "tmux_base_utils.sh" || { echo "ERROR: Failed to source tmux_base_utils.sh in tmux_script_generator.sh"; exit 1; }

# Helper function to generate common script boilerplate
# Arguments:
#   $1: Script content (the actual commands to run after the boilerplate)
#   $2: Content description (for comments)
#   $3: Space-separated list of variables to export (optional)
#   $4: Extra helper functions to include (optional, typically function definitions)
# Returns: Complete script content as string
tmx_generate_script_boilerplate() {
    local content="${1}"
    local description="${2:-script}"
    local vars="${3:-}"
    local helper_functions="${4:-}" # e.g., function definitions needed by content
    msg_debug "Generating script boilerplate for: ${description} (vars: ${vars:-none})"

    # Get absolute path to the project directory (assuming this script is in the same dir as the others)
    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

    # Start building the script content
    local script_content
    script_content=$(cat <<EOF
#!/usr/bin/env bash

# Enable xtrace for detailed debugging within the pane if desired
# set -x

# Set up script environment
SCRIPT_DIR="$(printf '%q' "${script_dir}")"
export PATH="\${SCRIPT_DIR}:\${PATH}"
# Attempt to cd to script dir, continue if it fails
cd "\${SCRIPT_DIR}" || echo "WARNING: Could not cd to \${SCRIPT_DIR}"

# --- Sourcing Core Utilities ---
echo "--- Sourcing sh-globals --- "
if [[ -f "\${SCRIPT_DIR}/sh-globals.sh" ]]; then
    source "\${SCRIPT_DIR}/sh-globals.sh" || { echo "ERROR: Failed to source sh-globals.sh"; exit 1; }
else
    echo "ERROR: sh-globals.sh not found at \${SCRIPT_DIR}/sh-globals.sh"; exit 1;
fi
echo "--- Sourcing tmux_base_utils --- "
if [[ -f "\${SCRIPT_DIR}/tmux_base_utils.sh" ]]; then
    source "\${SCRIPT_DIR}/tmux_base_utils.sh" || { echo "ERROR: Failed to source tmux_base_utils.sh"; exit 1; }
else
    echo "ERROR: tmux_base_utils.sh not found at \${SCRIPT_DIR}/tmux_base_utils.sh"; exit 1;
fi
echo "--- Sourcing tmux_utils1 (for higher-level functions) ---"
if [[ -f "\${SCRIPT_DIR}/tmux_utils1.sh" ]]; then
    # Set the guard variable to prevent initialization code in tmux_utils1.sh
    export TMUX_UTILS1_SOURCED_IN_PANE=1
    source "\${SCRIPT_DIR}/tmux_utils1.sh" || { echo "ERROR: Failed to source tmux_utils1.sh"; exit 1; }
else
    echo "ERROR: tmux_utils1.sh not found at \${SCRIPT_DIR}/tmux_utils1.sh"; exit 1;
fi
echo "--- Core utilities sourced ---"

# Initialize sh-globals within the pane script
export DEBUG=$(printf '%q' "${DEBUG:-0}") # Capture parent DEBUG value, default 0 if unset in parent
sh-globals_init

EOF
    )

    # Add variable exports if any
    if [[ -n "${vars}" ]]; then
        script_content+=$'\n# Export variables from parent shell\n'
        for var in ${vars}; do
            # Get value and quote it properly for inclusion in the script
            local value="${!var}"
            script_content+=$(printf 'export %s=%q\n' "${var}" "${value}")
        done
        script_content+=$'\n'
    fi

    # Add any extra helper functions if provided (e.g., user-defined functions for tmx_execute_shell_function)
    if [[ -n "${helper_functions}" ]]; then
        script_content+=$'\n# Include specific helper functions for this script\n'
        # Replace any \n with actual newlines to ensure proper function formatting
        script_content+="$(echo -e "${helper_functions}")"
        script_content+=$'\n\n'
    fi

    # Add user content with description
    script_content+=$(cat <<EOF
# --- Main Script Content (${description}) Follows ---
echo "--- Executing main content (${description}) ---"
${content}

echo "--- Main content finished ---"
# Add explicit exit to ensure clean termination?
# exit 0 # Consider if an explicit exit is always desired, maybe let script finish naturally
EOF
    )

    # Return the generated script content
    msg_debug "Finished generating script boilerplate for: ${description}"
    echo "${script_content}"
}

