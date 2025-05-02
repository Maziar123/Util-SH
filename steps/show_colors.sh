#!/usr/bin/env bash

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
echo "SCRIPT_DIR: ${SCRIPT_DIR}"

# Unset the loaded flag to ensure functions are defined in this script's context

#unset SH_GLOBALS_LOADED
# Source the globals script relative to this script's location
# shellcheck source=sh-globals.sh
#echo "DEBUG: Attempting to source ${SCRIPT_DIR}/sh-globals.sh"
source "${SCRIPT_DIR}/sh-globals.sh"
#source_exit_code=$?
#echo "DEBUG: source command exit code: ${source_exit_code}"

# Verify sourcing succeeded using type check
if type sh-globals_init &>/dev/null; then
    echo "DEBUG: sh-globals_init function found."
else
    echo "ERROR: sh-globals_init function NOT found after sourcing." >&2
    # Optionally exit here if needed, though the original check should handle it
    # exit 1
fi

# Original verification check (keep for consistency)
[[ "${SH_GLOBALS_LOADED:-0}" -eq 1 ]] || { echo "Error: Failed to source sh-globals.sh (SH_GLOBALS_LOADED not 1) from ${SCRIPT_DIR}/sh-globals.sh" >&2; exit 1; }

# Initialize globals (sets up traps, options, etc.)
sh-globals_init "$@"

echo "--- Foreground Colors ---"
msg_black   "msg_black: This is black text."
msg_red     "msg_red: This is red text."
msg_green   "msg_green: This is green text."
msg_yellow  "msg_yellow: This is yellow text."
msg_blue    "msg_blue: This is blue text."
msg_magenta "msg_magenta: This is magenta text."
msg_cyan    "msg_cyan: This is cyan text."
msg_white   "msg_white: This is white text."
msg_gray    "msg_gray: This is gray text."

echo -e "\n--- Background Colors ---"
msg_bg_black   "msg_bg_black: Black background."
msg_bg_red     "msg_bg_red: Red background."
msg_bg_green   "msg_bg_green: Green background."
msg_bg_yellow  "msg_bg_yellow: Yellow background."
msg_bg_blue    "msg_bg_blue: Blue background."
msg_bg_magenta "msg_bg_magenta: Magenta background."
msg_bg_cyan    "msg_bg_cyan: Cyan background."
# Use black text on white background for better visibility
msg_bg_white   "${BLACK}msg_bg_white: White background.${NC}"

echo -e "\n--- Text Formatting ---"
msg_bold      "msg_bold: This is bold text."
msg_dim       "msg_dim: This is dim text."
msg_underline "msg_underline: This is underlined text."
msg_blink     "msg_blink: This is blinking text (terminal support varies)."
msg_reverse   "msg_reverse: This is reversed text."
# msg_hidden is omitted as it would be invisible

echo -e "\n--- Semantic Messages ---"
msg_info      "msg_info: An informational message."
msg_success   "msg_success: A success message."
msg_warning   "msg_warning: A warning message (appears on stderr)."
msg_error     "msg_error: An error message (appears on stderr)."
msg_highlight "msg_highlight: A highlighted message."
msg_header    "msg_header: A header message."
msg_section   "Section Title Example"
msg_subtle    "msg_subtle: A subtle message."
msg_step      1 5 "msg_step: Processing step 1 of 5."
# msg_debug is omitted as it only appears if DEBUG=1 is set

echo -e "\n--- Combined Formatting Examples ---"
echo -e "${BOLD}${RED}This is bold red text.${NC}"
echo -e "${UNDERLINE}${BG_YELLOW}${BLUE}Underlined blue text on yellow background.${NC}"

echo -e "\n--- Plain Message ---"
msg "msg: This is a plain message without specific color."

echo -e "\nColor demo finished." 