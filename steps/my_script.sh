#!/usr/bin/bash

# Include the getoptions library
# Make sure getoptions.sh is in the same directory or provide the correct path
. ./getoptions.sh

# Define the parser specification
parser_definition() {
  setup REST help:usage abbr:true -- \
    "Usage: $0 [options]... [arguments]..." \
    "Example script using getoptions.sh library."
  flag    VERBOSE   -v --verbose                -- "Enable verbose output"
  param   LOGFILE   -l --log file               -- "Specify log file (mandatory)" var:logfile
  option  OUTPUT    -o --output file[=out.txt]  -- "Specify output file (optional)" var:outfile
  disp    :usage    -h --help                   -- "Display this help message"
}

# Optional: Store original arguments if needed elsewhere
# original_args=("$@")

# Store arguments in a bash array
script_args=("$@")

# Generate and evaluate the parser function (named 'parse')
# The name 'parse' is conventional but can be changed.
eval "$(getoptions parser_definition parse)"

# Call the parser function to parse the stored arguments using bash array expansion
# It will modify variables defined in parser_definition (VERBOSE, logfile, outfile)
# and collect remaining arguments in REST.
parse "${script_args[@]}"

# Assign remaining arguments (collected in REST) back to positional parameters
eval "set -- $REST"

# --- Script logic starts here ---

# Access parsed options/parameters via the defined variables
echo "--- Options ---"
if [ "$VERBOSE" = 1 ]; then
  echo "Verbose mode: ON"
else
  echo "Verbose mode: OFF"
fi

# Note: We check if the variable is set for mandatory parameters
if [ -z "${logfile-}" ]; then
  echo "Error: Log file was not specified." >&2
  # usage # Call the generated usage function
  exit 1
else
  echo "Log file: $logfile"
fi

# For optional parameters, you might check if it was set or rely on default
echo "Output file: ${outfile:-"Default (out.txt)"}" # Uses default if outfile is empty/unset

echo ""
echo "--- Remaining Arguments ---"
# Access remaining arguments
if [ $# -gt 0 ]; then
  echo "Arguments found: $#"
  i=1
  for arg in "$@"; do
    echo "Arg $i: $arg"
    i=$((i + 1))
  done
else
  echo "No remaining arguments."
fi

echo ""
echo "--- Original Arguments (if stored) ---"
# If you stored original_args uncomment the line below
# echo "Original arguments were: ${original_args[*]}"

exit 0 