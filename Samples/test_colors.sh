#!/usr/bin/env bash

# Source sh-globals.sh
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
source "${SCRIPT_DIR}/sh-globals.sh"

# Initialize sh-globals
sh-globals_init "$@"

# Regular message (no color)
msg "This is a regular message with no color"

# Info message (blue)
msg_info "This is an info message in blue"

# Success message (green)
msg_success "This is a success message in green"

# Warning message (yellow)
msg_warning "This is a warning message in yellow"

# Error message (red)
msg_error "This is an error message in red"

# Highlighted message (cyan)
msg_highlight "This is a highlighted message in cyan"

# Header message (bold magenta)
msg_header "This is a header message in bold magenta"

# Subtle/dim message (gray)
msg_subtle "This is a subtle message in gray"

# Section divider with text
msg_section "Section Title" 60 "="

# Debug message (only shows if DEBUG=1)
DEBUG=1
msg_debug "This is a debug message in cyan"

# Custom colored message
msg_color "This is a custom colored message" "${MAGENTA}" 