#!/usr/bin/bash
# param_handler.sh - Reusable library for handling mixed named and positional parameters
# Requires getoptions.sh to be sourced before this library

# VERSION: 1.1.0

# Color definitions
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
MAGENTA="\e[35m"
NC="\e[0m"  # No Color (reset)

# Disable colors if running under ShellSpec or NO_COLOR is set
if [[ -n "${SHELLSPEC_RUNNING:-}" || -n "${NO_COLOR:-}" ]]; then
    BLUE=""
    GREEN=""
    YELLOW=""
    CYAN=""
    RED=""
    MAGENTA=""
    NC=""
fi

# Check if getoptions command exists
if type -t getoptions &>/dev/null; then
    # Check if getoptions.sh exists in the same directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [[ -f "${SCRIPT_DIR}/getoptions.sh" ]]; then
        # Both exist, source getoptions.sh
        # shellcheck disable=SC1091
        source "${SCRIPT_DIR}/getoptions.sh"
    else
        # getoptions command exists but file doesn't
        echo "Error: getoptions.sh not found. This is a fatal error." >&2
        # shellcheck disable=SC2317
        return 1 2>/dev/null || exit 1  # Return if sourced, exit if executed directly
    fi
else
    # getoptions command doesn't exist
    echo "Error: getoptions command not found. This is a fatal error." >&2
    exit 1
fi

# Array to store parameter definitions
declare -gA PARAM_HANDLER_CONFIG
declare -ga PARAM_HANDLER_PARAM_NAMES=()
declare -ga PARAM_HANDLER_SET_BY_NAME=()
declare -ga PARAM_HANDLER_SET_BY_POSITION=()
declare -gi PARAM_HANDLER_NAMED_COUNT=0
declare -gi PARAM_HANDLER_POSITIONAL_COUNT=0

# Initialize the parameter handler
# Usage: param_handler::init
param_handler::init() {
    PARAM_HANDLER_CONFIG=()
    PARAM_HANDLER_PARAM_NAMES=()
    PARAM_HANDLER_SET_BY_NAME=()
    PARAM_HANDLER_SET_BY_POSITION=()
    PARAM_HANDLER_NAMED_COUNT=0
    PARAM_HANDLER_POSITIONAL_COUNT=0
}

# Register a parameter
# Usage: param_handler::register_param "param_name" "var_name" "option_name" "description" ["required"] ["getter_func"]
param_handler::register_param() {
    local param_name="$1"
    local var_name="$2"
    local option_name="$3"
    local description="$4"
    local required="${5:-}"
    local getter_func="${6:-}"
    
    PARAM_HANDLER_CONFIG["${param_name}_var"]="${var_name}"
    PARAM_HANDLER_CONFIG["${param_name}_opt"]="${option_name}"
    PARAM_HANDLER_CONFIG["${param_name}_desc"]="${description}"
    PARAM_HANDLER_CONFIG["${param_name}_required"]="${required}"
    PARAM_HANDLER_CONFIG["${param_name}_getter"]="${getter_func}"
    
    # Add to param names array
    PARAM_HANDLER_PARAM_NAMES+=("${param_name}")
}

# Generate parser definition for getoptions
# Usage: param_handler::generate_parser_definition [parser_func_name]
# @param parser_func_name Optional name for the parser function (default: param_handler::parser_definition)
param_handler::generate_parser_definition() {
    local func_name="${1:-param_handler::parser_definition}"
    
    echo "${func_name}() {"
    echo "    setup REST help:usage -- \"Usage: \${0##*/} [OPTIONS] [POSITIONAL_PARAMS]\" ''"
    echo "    msg -- 'Options:'"
    echo "    flag help -h --help -- \"Show help message\""
    
    # Add each registered parameter
    for param_name in "${PARAM_HANDLER_PARAM_NAMES[@]}"; do
        local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
        local opt_name="${PARAM_HANDLER_CONFIG["${param_name}_opt"]}"
        local description="${PARAM_HANDLER_CONFIG["${param_name}_desc"]}"
        local required="${PARAM_HANDLER_CONFIG["${param_name}_required"]}"
        
        if [[ "$required" == "REQUIRE" ]]; then
            echo "    param ${var_name} --${opt_name} -- \"${description} (REQUIRED)\""
        else
            echo "    param ${var_name} --${opt_name} -- \"${description}\""
        fi
    done
    
    echo "    disp :usage -h --help"
    echo "}"
}

# Parse parameters using getoptions and handle positional parameters
# Usage: param_handler::parse_args "$@"
param_handler::parse_args() {
    # Copy args for later processing
    local orig_args=("$@")
    
    # Run the parser to handle named parameters
    parse "$@"
    
    # Track which parameters were set by name
    for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
        local param_name="${PARAM_HANDLER_PARAM_NAMES[$i]}"
        local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
        
        # Fix: Use indirect reference instead of eval
        local value="${!var_name}"
        
        if [[ -n "$value" ]]; then
            PARAM_HANDLER_SET_BY_NAME[i]=1
            ((PARAM_HANDLER_NAMED_COUNT++))
        else
            PARAM_HANDLER_SET_BY_NAME[i]=0
        fi
        
        PARAM_HANDLER_SET_BY_POSITION[i]=0
    done
    
    # Collect positional arguments
    local skip_next=false
    local pos_args=()
    
    for ((i=0; i<${#orig_args[@]}; i++)); do
        if $skip_next; then
            skip_next=false
            continue
        fi
        
        local is_option=false
        # Check if current arg is an option name
        for param_name in "${PARAM_HANDLER_PARAM_NAMES[@]}"; do
            local opt_name="${PARAM_HANDLER_CONFIG["${param_name}_opt"]}"
            if [[ "${orig_args[i]}" == "--${opt_name}" ]]; then
                is_option=true
                skip_next=true
                break
            fi
        done
        
        if ! $is_option && [[ "${orig_args[i]}" != --* ]]; then
            pos_args+=("${orig_args[i]}")
        fi
    done
    
    # Assign positional arguments to parameters not set by name
    local pos_index=0
    for arg in "${pos_args[@]}"; do
        # Skip positions already filled by named parameters
        while [[ $pos_index -lt ${#PARAM_HANDLER_PARAM_NAMES[@]} && 
                 ${PARAM_HANDLER_SET_BY_NAME[$pos_index]} -eq 1 ]]; do
            ((pos_index++))
        done
        
        if [[ $pos_index -lt ${#PARAM_HANDLER_PARAM_NAMES[@]} ]]; then
            local param_name="${PARAM_HANDLER_PARAM_NAMES[$pos_index]}"
            local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
            
            # Fix: Use declare instead of eval for setting the variable
            declare -g "${var_name}=${arg}"
            PARAM_HANDLER_SET_BY_POSITION[pos_index]=1
            ((PARAM_HANDLER_POSITIONAL_COUNT++))
            ((pos_index++))
        fi
    done
    
    return 0
}

# Handle required parameters with function references
# Usage: param_handler::handle_required_params
param_handler::handle_required_params() {
    local missing_required=0
    
    for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
        local param_name="${PARAM_HANDLER_PARAM_NAMES[$i]}"
        local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
        local required="${PARAM_HANDLER_CONFIG["${param_name}_required"]}"
        local getter_func="${PARAM_HANDLER_CONFIG["${param_name}_getter"]}"
        local description="${PARAM_HANDLER_CONFIG["${param_name}_desc"]}"
        local opt_name="${PARAM_HANDLER_CONFIG["${param_name}_opt"]}"
        
        # Fix: Use indirect reference instead of eval
        local value="${!var_name}"
        
        # Skip if not required or already has a value
        if [[ "$required" != "REQUIRE" || -n "$value" ]]; then
            continue
        fi
        
        # If no getter function, mark as missing required
        if [[ -z "$getter_func" ]]; then
            log_error "Missing required parameter: --${opt_name} (${description})"
            missing_required=1
            continue
        fi
        
        # Call getter function to prompt for value
        echo -e "${YELLOW}Missing required parameter:${NC} ${description}"
        local new_value
        
        # Call get_value function with the getter function as validator
        new_value=$(get_value "${description}" "" "$getter_func" "Invalid input for ${description}")
        
        # Set the variable with the new value
        declare -g "${var_name}=${new_value}"
        
        # Update parameter tracking
        PARAM_HANDLER_SET_BY_NAME[i]=1
        ((PARAM_HANDLER_NAMED_COUNT++))
    done
    
    return $missing_required
}

# Process all parameters (setup parser, parse args, optionally handle help)
# Usage: param_handler::process_params [--handle-help] "$@"
param_handler::process_params() {
    local handle_help=false
    if [[ "$1" == "--handle-help" ]]; then
        handle_help=true
        shift
    fi
    
    # Create a temporary file for parser definition
    local tmp_file
    tmp_file=$(mktemp)
    
    # Generate parser definition to temporary file
    param_handler::generate_parser_definition "param_handler::parser_definition" > "$tmp_file"
    
    # Source the temporary file to define parser_definition function
    # shellcheck disable=SC1090
    source "$tmp_file"
    
    # Use getoptions to create parse function
    eval "$(getoptions param_handler::parser_definition parse)"
    
    # Clean up temporary file
    rm -f "$tmp_file"
    
    # Parse arguments
    param_handler::parse_args "$@"
    
    # Check if help was requested and handle it if requested
    if $handle_help && [[ -n "$help" ]]; then
        param_handler::print_help
        return 1  # Signal that help was displayed
    fi
    
    # Handle required parameters
    if ! param_handler::handle_required_params; then
        return 2  # Signal that required parameters are missing
    fi
    
    return 0
}

# Get parameter value
# Usage: value=$(param_handler::get_param "param_name")
param_handler::get_param() {
    local param_name="$1"
    local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
    
    # Fix: Use indirect reference to avoid eval with dashes
    printf '%s' "${!var_name}"
}

# Check if parameter was set by name
# Usage: if param_handler::was_set_by_name "param_name"; then ...
param_handler::was_set_by_name() {
    local param_name="$1"
    local index=-1
    
    for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
        if [[ "${PARAM_HANDLER_PARAM_NAMES[$i]}" == "$param_name" ]]; then
            index=$i
            break
        fi
    done
    
    [[ $index -ge 0 && ${PARAM_HANDLER_SET_BY_NAME[$index]} -eq 1 ]]
}

# Check if parameter was set by position
# Usage: if param_handler::was_set_by_position "param_name"; then ...
param_handler::was_set_by_position() {
    local param_name="$1"
    local index=-1
    
    for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
        if [[ "${PARAM_HANDLER_PARAM_NAMES[$i]}" == "$param_name" ]]; then
            index=$i
            break
        fi
    done
    
    [[ $index -ge 0 && ${PARAM_HANDLER_SET_BY_POSITION[$index]} -eq 1 ]]
}

# Get count of named parameters
# Usage: named_count=$(param_handler::get_named_count)
param_handler::get_named_count() {
    echo "$PARAM_HANDLER_NAMED_COUNT"
}

# Get count of positional parameters
# Usage: positional_count=$(param_handler::get_positional_count)
param_handler::get_positional_count() {
    echo "$PARAM_HANDLER_POSITIONAL_COUNT"
}

# Print parameter values and state
# Usage: param_handler::print_params
param_handler::print_params() {
    echo -e "${CYAN}Parameter Values:${NC}"
    for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
        local param_name="${PARAM_HANDLER_PARAM_NAMES[$i]}"
        local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
        local required="${PARAM_HANDLER_CONFIG["${param_name}_required"]}"
        
        # Fix: Use indirect reference to avoid eval with dashes
        local value="${!var_name}"
        
        local source="unset"
        local color="$RED"
        if [[ ${PARAM_HANDLER_SET_BY_NAME[$i]} -eq 1 ]]; then
            source="named"
            color="$GREEN"
        elif [[ ${PARAM_HANDLER_SET_BY_POSITION[$i]} -eq 1 ]]; then
            source="positional"
            color="$YELLOW"
        fi
        
        if [[ "$required" == "REQUIRE" ]]; then
            echo -e "${BLUE}${var_name}:${NC} ${color}${value}${NC} (${source}) ${MAGENTA}[REQUIRED]${NC}"
        else
            echo -e "${BLUE}${var_name}:${NC} ${color}${value}${NC} (${source})"
        fi
    done
    
    echo -e "${BLUE}Named parameters:${NC} ${GREEN}$PARAM_HANDLER_NAMED_COUNT${NC}"
    echo -e "${BLUE}Positional parameters:${NC} ${GREEN}$PARAM_HANDLER_POSITIONAL_COUNT${NC}"
}

# Print help message
# Usage: param_handler::print_help
param_handler::print_help() {
    echo -e "${CYAN}Usage:${NC} ${YELLOW}${0##*/}${NC} [OPTIONS] [POSITIONAL_PARAMS]"
    echo -e "${CYAN}Options:${NC}"
    echo -e "  ${GREEN}-h, --help${NC}            Show this help message"
    
    for param_name in "${PARAM_HANDLER_PARAM_NAMES[@]}"; do
        local opt_name="${PARAM_HANDLER_CONFIG["${param_name}_opt"]}"
        local description="${PARAM_HANDLER_CONFIG["${param_name}_desc"]}"
        local required="${PARAM_HANDLER_CONFIG["${param_name}_required"]}"
        
        if [[ "$required" == "REQUIRE" ]]; then
            printf "  ${GREEN}--%-18s${NC} %s ${RED}[REQUIRED]${NC}\n" "${opt_name}" "${description}"
        else
            printf "  ${GREEN}--%-18s${NC} %s\n" "${opt_name}" "${description}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}Positional parameters are accepted in the following order:${NC}"
    
    for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
        local param_name="${PARAM_HANDLER_PARAM_NAMES[$i]}"
        local description="${PARAM_HANDLER_CONFIG["${param_name}_desc"]}"
        local required="${PARAM_HANDLER_CONFIG["${param_name}_required"]}"
        
        if [[ "$required" == "REQUIRE" ]]; then
            echo -e "  ${YELLOW}$((i+1)).${NC} ${description} ${RED}[REQUIRED]${NC}"
        else
            echo -e "  ${YELLOW}$((i+1)).${NC} ${description}"
        fi
    done
}

# Ultra-simplified all-in-one function to define, process, and handle parameters
# Usage: declare -A PARAMS=(["name:NAME"]="Person's name" ["age:AGE:REQUIRE:validate_age"]="Person's age")
#        param_handler::simple_handle PARAMS "$@"
param_handler::simple_handle() {
    local param_config_name="$1"
    shift
    
    # Initialize
    param_handler::init
    
    # Get the associative array with parameter definitions
    local -n param_config="$param_config_name"
    
    # Register parameters from the config array
    for key in "${!param_config[@]}"; do
        # Key format is "internal_name:VAR_NAME:option_name:REQUIRE:getter_func" 
        # or "internal_name:VAR_NAME:option_name:REQUIRE" 
        # or "internal_name:VAR_NAME:option_name" 
        # or "internal_name:VAR_NAME"
        # If option_name is omitted, internal_name is used
        local internal_name=""
        local var_name=""
        local option_name=""
        local required=""
        local getter_func=""
        local description="${param_config[$key]}"
        
        # Split by colon into array parts
        IFS=':' read -ra parts <<< "$key"
        
        # Extract the parts based on how many were provided
        internal_name="${parts[0]}"
        var_name="${parts[1]}"
        
        if [[ ${#parts[@]} -gt 2 ]]; then
            option_name="${parts[2]}"
        fi
        
        if [[ ${#parts[@]} -gt 3 ]]; then
            required="${parts[3]}"
        fi
        
        if [[ ${#parts[@]} -gt 4 ]]; then
            getter_func="${parts[4]}"
        fi
        
        # Apply defaults
        if [[ -z "$option_name" ]]; then
            option_name="$internal_name"
        fi
        
        # Create the variable if it doesn't exist
        if ! declare -p "$var_name" &>/dev/null; then
            declare -g "$var_name"=""
        fi
        
        # Register the parameter
        param_handler::register_param "$internal_name" "$var_name" "$option_name" "$description" "$required" "$getter_func"
    done
    
    # Process the parameters with help handling
    local result
    param_handler::process_params --handle-help "$@"
    result=$?
    
    if [[ $result -eq 1 ]]; then
        return 1  # Help was displayed
    elif [[ $result -eq 2 ]]; then
        echo -e "${RED}Error: Required parameters missing${NC}" >&2
        return 2  # Required parameters missing
    fi
    
    return 0
}

# Export parameters to environment variables or other formats
# Usage: param_handler::export_params [--prefix PREFIX] [--format FORMAT]
param_handler::export_params() {
    local prefix=""
    local format="export"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prefix)
                prefix="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}" >&2
                return 1
                ;;
        esac
    done
    
    case "$format" in
        export)
            echo -e "${CYAN}Exporting parameters:${NC}"
            for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
                local param_name="${PARAM_HANDLER_PARAM_NAMES[$i]}"
                local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
                
                # Fix: Use indirect reference
                local value="${!var_name}"
                
                if [[ -n "$value" ]]; then
                    echo -e "${GREEN}export ${prefix}${var_name}=\"$value\"${NC}"
                    export "${prefix}${var_name}"="$value"
                fi
            done
            ;;
        json)
            echo -e "${CYAN}JSON output:${NC}"
            echo "{"
            local first=true
            for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
                local param_name="${PARAM_HANDLER_PARAM_NAMES[$i]}"
                local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
                
                # Fix: Use indirect reference
                local value="${!var_name}"
                
                if ! $first; then
                    echo ","
                fi
                
                echo -e -n "  ${BLUE}\"${prefix}${param_name}\"${NC}: ${GREEN}\"$value\"${NC}"
                first=false
            done
            echo ""
            echo "}"
            ;;
        *)
            echo -e "${RED}Unknown format: $format${NC}" >&2
            return 1
            ;;
    esac
    
    return 0
}

# Display a colorful parameter summary
# Usage: param_handler::print_summary
param_handler::print_summary() {
    local named=$(param_handler::get_named_count)
    local positional=$(param_handler::get_positional_count)
    local total=$((named + positional))
    
    echo -e "${CYAN}Parameter Summary:${NC}"
    echo -e "${BLUE}Named parameters:${NC} ${GREEN}$named${NC}"
    echo -e "${BLUE}Positional parameters:${NC} ${GREEN}$positional${NC}"
    echo -e "${BLUE}Total parameters:${NC} ${YELLOW}$total${NC}"
}

# Extended print function with colors and summary
# Usage: param_handler::print_params_extended
param_handler::print_params_extended() {
    echo -e "${CYAN}Parameter Values:${NC}"
    for i in "${!PARAM_HANDLER_PARAM_NAMES[@]}"; do
        local param_name="${PARAM_HANDLER_PARAM_NAMES[$i]}"
        local var_name="${PARAM_HANDLER_CONFIG["${param_name}_var"]}"
        local required="${PARAM_HANDLER_CONFIG["${param_name}_required"]}"
        
        # Use indirect reference to avoid eval with dashes
        local value="${!var_name}"
        
        local source="unset"
        local color="$RED"
        if [[ ${PARAM_HANDLER_SET_BY_NAME[$i]} -eq 1 ]]; then
            source="named"
            color="$GREEN"
        elif [[ ${PARAM_HANDLER_SET_BY_POSITION[$i]} -eq 1 ]]; then
            source="positional"
            color="$YELLOW"
        fi
        
        if [[ "$required" == "REQUIRE" ]]; then
            echo -e "${BLUE}${var_name}:${NC} ${color}${value}${NC} (${source}) ${MAGENTA}[REQUIRED]${NC}"
        else
            echo -e "${BLUE}${var_name}:${NC} ${color}${value}${NC} (${source})"
        fi
    done
    
    echo ""
    param_handler::print_summary
} 