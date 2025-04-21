#!/usr/bin/env bash
# tmux_visual_demo.sh - Visual demonstration of tmux panes sharing variables

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/sh-globals.sh"
# shellcheck source=../tmux_utils1.sh
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    export DEBUG=1
    sh-globals_init "$@"
fi

#========================================================
# Configuration and Global Variables
#========================================================

# Demo Settings
APP_NAME="Tmux Visual Demo"
APP_VERSION="1.0.0"
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
DEMO_DIR="/tmp/tmux_visual_${TIMESTAMP}"

# Demo config - just 3 workers with different colors
NUM_WORKERS=3
MAX_RUNS=20                   # Each worker will run this many updates
VAR_VALUES=()                 # Array to store values (shared via files)

# Color themes for workers
COLORS=("GREEN" "BLUE" "MAGENTA")
THEMES=("msg_bg_green" "msg_bg_blue" "msg_bg_magenta")

# Create shared directory
mkdir -p "${DEMO_DIR}"

# Initialize the shared variables
for i in $(seq 0 $((NUM_WORKERS-1))); do
    VAR_VALUES[$i]=0
    echo "0" > "${DEMO_DIR}/var_${i}.txt"
done

#========================================================
# Worker Functions
#========================================================

# Master function that monitors shared variables
master_monitor() {
    # Get session information
    local session_name=$(tmux display-message -p '#S')
    local pane_id=$(tmux display-message -p '#P')
    
    # Record start time for elapsed calculation
    START_TIME=$(date +%s)
    
    # Main monitoring loop
    local updates=0
    local all_complete=false
    
    while ! $all_complete; do
        # Clear screen and show header
        clear
        msg_header "${APP_NAME} v${APP_VERSION}"
        msg_info "SESSION: ${session_name} - PANE: ${pane_id}"
        echo "Monitoring shared variables across panes"
        echo ""
        
        # Calculate elapsed time
        local current_time=$(date +%s)
        local elapsed=$((current_time - START_TIME))
        local elapsed_formatted="$(printf "%02d:%02d" $((elapsed / 60)) $((elapsed % 60)))"
        
        echo "Time elapsed: ${elapsed_formatted}"
        echo "Updates: ${updates}"
        echo ""
        
        # Read all variable values from files
        local total_value=0
        local workers_complete=0
        local progress=""
        
        echo "┌──────────────────────────────────────────────────────────────┐"
        echo "│ WORKER    VALUE      PROGRESS                                │"
        echo "├──────────────────────────────────────────────────────────────┤"
        
        for i in $(seq 0 $((NUM_WORKERS-1))); do
            # Read file and update array
            VAR_VALUES[$i]=$(cat "${DEMO_DIR}/var_${i}.txt" 2>/dev/null || echo "0")
            
            # Calculate progress percentage
            local progress_pct=$((${VAR_VALUES[$i]} * 100 / MAX_RUNS))
            
            # Generate progress bar (20 chars wide)
            local bar_width=30
            local filled=$((${VAR_VALUES[$i]} * bar_width / MAX_RUNS))
            local bar=$(printf '%*s' "$filled" | tr ' ' '█')
            local empty=$(printf '%*s' "$((bar_width - filled))" | tr ' ' '░')
            
            # Get worker color and format line with color
            local color_var="${COLORS[$i]}"
            
            # Display worker info with colored progress bar
            echo -e "│ Worker $i   ${VAR_VALUES[$i]}/$(echo ${MAX_RUNS}) [ ${!color_var}${bar}${NC}${empty} ] ${progress_pct}% │"
            
            # Count completed workers
            if [[ ${VAR_VALUES[$i]} -ge ${MAX_RUNS} ]]; then
                ((workers_complete++))
            fi
            
            # Add to total
            ((total_value += ${VAR_VALUES[$i]}))
        done
        
        # Show total
        local total_progress=$((total_value * 100 / (MAX_RUNS * NUM_WORKERS)))
        echo "├──────────────────────────────────────────────────────────────┤"
        echo "│ TOTAL: ${total_value}/${MAX_RUNS * NUM_WORKERS} - Progress: ${total_progress}% │"
        
        if [[ ${workers_complete} -eq ${NUM_WORKERS} ]]; then
            echo "│ STATUS: ${GREEN}All workers complete${NC}                               │"
            all_complete=true
        else
            echo "│ STATUS: ${YELLOW}Running - ${workers_complete}/${NUM_WORKERS} workers complete${NC}                 │"
        fi
        echo "└──────────────────────────────────────────────────────────────┘"
        
        # Update counter
        ((updates++))
        
        # Short sleep or exit if complete
        if $all_complete; then
            break
        fi
        sleep 1
    done
    
    # Final message
    echo ""
    END_TIME=$(date +%s)
    TOTAL_TIME=$((END_TIME - START_TIME))
    local time_formatted="$(printf "%02d:%02d" $((TOTAL_TIME / 60)) $((TOTAL_TIME % 60)))"
    
    echo "${GREEN}Demo completed in ${time_formatted}${NC}"
    echo ""
    echo "Press Enter to close monitor pane..."
    read -r
}

# Generic worker function with different colors
worker_function() {
    # Get session and ID info
    local session_name=$(tmux display-message -p '#S')
    local pane_id=$(tmux display-message -p '#P')
    local worker_id="${WORKER_ID}"
    
    # Get color theme from ID
    local theme_func="${THEMES[$worker_id]}"
    local color_var="${COLORS[$worker_id]}"
    
    # Variable file is unique to this worker
    local var_file="${DEMO_DIR}/var_${worker_id}.txt"
    local value=0
    
    # Initialize status file with current value
    echo "${value}" > "${var_file}"
    
    # Each worker has different characteristics
    local delay=0
    local increment=0
    local message=""
    
    # Configure worker based on ID
    case $worker_id in
        0)  # Green worker: Fast but small increments
            delay=1
            increment=1
            message="Fast worker (+1 every ${delay}s)"
            ;;
        1)  # Blue worker: Medium speed, medium increments
            delay=2
            increment=2
            message="Medium worker (+${increment} every ${delay}s)"
            ;;
        2)  # Magenta worker: Slow but large increments
            delay=3
            increment=3
            message="Slow worker (+${increment} every ${delay}s)"
            ;;
        *)  # Default fallback
            delay=2
            increment=1
            message="Generic worker"
            ;;
    esac
    
    # Main processing loop
    clear
    $theme_func "SESSION: ${session_name} - PANE: ${pane_id}"
    echo "Worker ${worker_id}: ${message}"
    echo "Target: ${MAX_RUNS}"
    echo ""
    
    # Progress loop
    while [[ $value -lt $MAX_RUNS ]]; do
        # Clear screen each iteration
        clear
        $theme_func "SESSION: ${session_name} - PANE: ${pane_id}"
        echo "Worker ${worker_id}: ${message}"
        echo ""
        
        # Update value 
        value=$((value + increment))
        if [[ $value -gt $MAX_RUNS ]]; then
            value=$MAX_RUNS  # Cap at max
        fi
        
        # Calculate progress percentage and bar
        local progress_pct=$((value * 100 / MAX_RUNS))
        local bar_width=40
        local filled=$((value * bar_width / MAX_RUNS))
        local bar=$(printf '%*s' "$filled" | tr ' ' '#')
        
        # Show progress
        echo -e "Progress: ${value}/${MAX_RUNS} (${progress_pct}%)"
        echo -e "${!color_var}[${bar}${NC}${!color_var}]${NC}"
        echo ""
        
        # Show variable values from other workers
        echo "Values from all workers:"
        for i in $(seq 0 $((NUM_WORKERS-1))); do
            if [[ $i -eq $worker_id ]]; then
                # Current worker (us)
                echo "  Worker $i (${COLORS[$i]}, this pane): ${value}"
            else
                # Read value from other workers
                local other_value=$(cat "${DEMO_DIR}/var_${i}.txt" 2>/dev/null || echo "?")
                echo "  Worker $i (${COLORS[$i]}): ${other_value}"
            fi
        done
        
        # Write current value to shared file
        echo "${value}" > "${var_file}"
        sync
        
        # Wait before next update
        sleep $delay
    done
    
    # Final message when complete
    clear
    $theme_func "SESSION: ${session_name} - PANE: ${pane_id}"
    echo "Worker ${worker_id}: ${message}"
    echo ""
    echo "COMPLETE: ${value}/${MAX_RUNS} (100%)"
    
    # Print full progress bar
    local bar_width=40
    local bar=$(printf '%*s' "$bar_width" | tr ' ' '#')
    echo -e "${!color_var}[${bar}${NC}${!color_var}]${NC}"
    
    echo ""
    echo "Press Enter to close pane..."
    read -r
}

#========================================================
# Main Program Function
#========================================================

main() {
    clear
    msg_header "${APP_NAME} v${APP_VERSION}"
    msg_info "Starting visual demonstration with ${NUM_WORKERS} tmux panes"
    msg_info "Each worker will update a shared variable with different rates"
    echo ""
    
    # Create a new tmux session
    local session_name
    session_name=$(create_tmux_session "visual_demo")
    if [[ -z "${session_name}" ]]; then
        msg_error "Failed to create tmux session. Exiting."
        exit 1
    fi
    msg_success "Created tmux session: ${session_name}"
    sleep 1
    
    # Start the master monitor in the first pane
    msg_info "Starting master monitor in pane 0"
    execute_shell_function "${session_name}" 0 master_monitor "SH_GLOBALS_LOADED APP_NAME APP_VERSION NUM_WORKERS MAX_RUNS DEMO_DIR START_TIME COLORS GREEN YELLOW NC"
    sleep 1
    
    # Start workers in new panes
    for worker_id in $(seq 0 $((NUM_WORKERS-1))); do
        msg_info "Starting worker ${worker_id}"
        
        # Create new pane
        local pane_idx
        if [[ ${worker_id} -eq 0 ]]; then
            # First worker gets a vertical split
            pane_idx=$(create_new_pane "${session_name}" "v")
        else
            # Other workers get horizontal splits from the last pane
            pane_idx=$(create_new_pane "${session_name}")
        fi
        
        if [[ -n "${pane_idx}" ]]; then
            msg_success "Created pane ${pane_idx} for worker ${worker_id}"
            
            # Start worker with shared variables
            WORKER_ID="${worker_id}"
            execute_shell_function "${session_name}" "${pane_idx}" worker_function "SH_GLOBALS_LOADED WORKER_ID MAX_RUNS DEMO_DIR THEMES COLORS GREEN NC"
            sleep 0.5
        else
            msg_error "Failed to create pane for worker ${worker_id}"
        fi
    done
    
    msg_info "Visual demonstration started in tmux session: ${session_name}"
    msg_info "Watch the monitor to see variable updates from all workers"
    msg_info "Demo automatically ends when all workers complete"
    echo ""
    
    # Wait for user to press Ctrl+C
    echo "Press Ctrl+C to end the demonstration..."
    
    # Keep script running until killed
    trap 'echo -e "\nDemonstration ended by user"; exit 0' INT
    while true; do
        sleep 1
    done
}

# Run the main function
main "$@" 