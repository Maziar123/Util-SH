#!/usr/bin/env bash
# tmux_data_processing.sh - Practical example of multi-pane data processing with tmux

# Source utilities
SCRIPT_DIR="$(readlink -f "$(dirname "${0}")/../")"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/sh-globals.sh"
# shellcheck source=../tmux_utils1.sh
source "${SCRIPT_DIR}/tmux_utils1.sh"

# Initialize sh-globals if not already initialized
if [[ "${SH_GLOBALS_LOADED:-0}" -ne 1 ]]; then
    # Enable debug logging
    export DEBUG=1
    sh-globals_init "$@"
fi

#========================================================
# Configuration and Global Variables
#========================================================

# Job Settings
APP_NAME="Tmux Data Processor"
APP_VERSION="1.0.0"
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
RESULTS_DIR="/tmp/data_processing_${TIMESTAMP}"

# Worker settings
NUM_WORKERS=3           # Total number of worker panes
PROCESSING_DELAY=2      # Simulate processing time in seconds
ITEMS_PER_WORKER=5      # Number of items each worker will process

# Status files
STATUS_DIR="${RESULTS_DIR}/status"
MASTER_STATUS="${STATUS_DIR}/master.status"
FINAL_RESULTS="${RESULTS_DIR}/results.txt"

# No need to redefine colors - sh-globals.sh already has them:
# BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, GRAY, NC, etc.

#========================================================
# Data Processing Functions
#========================================================

# Generate some example data 
generate_data() {
    local data_dir="$1"
    local total_files="$2"
    
    msg_info "Generating ${total_files} data files in ${data_dir}"
    
    # Create data directory if it doesn't exist
    mkdir -p "${data_dir}"
    
    # Generate example data files
    for i in $(seq 1 "${total_files}"); do
        local file="${data_dir}/data_${i}.txt"
        echo "Data file ${i} - Created at $(date)" > "${file}"
        echo "Random values: $(( RANDOM % 100 )) $(( RANDOM % 100 )) $(( RANDOM % 100 ))" >> "${file}"
        echo "Hostname: $(hostname)" >> "${file}"
        echo "System uptime: $(uptime)" >> "${file}"
    done
    
    msg_success "Generated ${total_files} data files"
}

# Master function that monitors worker progress
master_monitor() {
    # This will run in the main pane
    clear
    msg_header "Master Monitor - ${APP_NAME} v${APP_VERSION}"
    msg_info "Monitoring ${NUM_WORKERS} workers processing data"
    echo "Results will be collected in: ${RESULTS_DIR}"
    echo ""
    
    # Initial status dashboard
    print_status_dashboard() {
        local total_items=$((NUM_WORKERS * ITEMS_PER_WORKER))
        local processed=0
        local workers_done=0
        
        echo -e "\n${CYAN}==== Processing Status ====${NC}\n"
        
        # Check each worker's status file
        for w in $(seq 1 "${NUM_WORKERS}"); do
            local status_file="${STATUS_DIR}/worker_${w}.status"
            
            if [[ -f "${status_file}" ]]; then
                # Source the status file to get variables
                # Add a slight delay to ensure file is fully written
                sleep 0.1
                # shellcheck disable=SC1090
                source "${status_file}"
                
                # Show worker status
                echo -n "Worker ${w}: "
                if [[ "${WORKER_STATUS:-PENDING}" == "COMPLETED" ]]; then
                    echo -e "${GREEN}Completed ${ITEMS_PROCESSED:-0}/${ITEMS_PER_WORKER} items${NC}"
                    ((workers_done++))
                elif [[ "${WORKER_STATUS:-PENDING}" == "RUNNING" ]]; then
                    echo -e "${YELLOW}Processing item ${CURRENT_ITEM:-0}/${ITEMS_PER_WORKER}${NC}"
                else
                    echo -e "${GRAY}Waiting to start${NC}"
                fi
                
                # Increment processed count with default value
                processed=$((processed + ${ITEMS_PROCESSED:-0}))
            else
                echo -e "Worker ${w}: ${RED}Not started${NC}"
            fi
        done
        
        # Overall progress
        local percent=$((processed * 100 / total_items))
        echo -e "\n${MAGENTA}Overall Progress: ${percent}% (${processed}/${total_items} items)${NC}"
        echo -e "${BLUE}Workers Complete: ${workers_done}/${NUM_WORKERS}${NC}"
        echo -e "\n${CYAN}==========================${NC}\n"
        
        # Ensure dashboard is displayed before continuing
        sleep 0.5
    }
    
    # Loop until all workers are done
    while true; do
        # Clear the screen for a fresh status update
        clear
        msg_header "Master Monitor - ${APP_NAME} v${APP_VERSION}"
        msg_info "Monitoring ${NUM_WORKERS} workers processing data"
        echo "Results will be collected in: ${RESULTS_DIR}"
        
        # Print the dashboard
        print_status_dashboard
        
        # Check if all workers are done
        local all_done=true
        for w in $(seq 1 "${NUM_WORKERS}"); do
            local status_file="${STATUS_DIR}/worker_${w}.status"
            
            if [[ ! -f "${status_file}" ]] || ! grep -q "WORKER_STATUS=COMPLETED" "${status_file}"; then
                all_done=false
                break
            fi
        done
        
        if $all_done; then
            msg_success "All workers have completed processing!"
            
            # Collect and summarize results
            echo "Collecting final results..."
            echo "==== ${APP_NAME} Final Results ====" > "${FINAL_RESULTS}"
            echo "Run timestamp: ${TIMESTAMP}" >> "${FINAL_RESULTS}"
            echo "Workers: ${NUM_WORKERS}" >> "${FINAL_RESULTS}"
            echo "Items per worker: ${ITEMS_PER_WORKER}" >> "${FINAL_RESULTS}"
            echo "Total items processed: $((NUM_WORKERS * ITEMS_PER_WORKER))" >> "${FINAL_RESULTS}"
            echo "" >> "${FINAL_RESULTS}"
            
            # Add individual worker results
            for w in $(seq 1 "${NUM_WORKERS}"); do
                echo "---- Worker ${w} Results ----" >> "${FINAL_RESULTS}"
                if [[ -f "${RESULTS_DIR}/worker_${w}_results.txt" ]]; then
                    cat "${RESULTS_DIR}/worker_${w}_results.txt" >> "${FINAL_RESULTS}"
                fi
                echo "" >> "${FINAL_RESULTS}"
            done
            
            # Update master status
            echo "MASTER_STATUS=COMPLETED" > "${MASTER_STATUS}"
            echo "END_TIME=$(date +%s)" >> "${MASTER_STATUS}"
            
            # Display results location
            echo -e "\nResults saved to: ${FINAL_RESULTS}"
            echo "You can view them with: cat ${FINAL_RESULTS}"
            
            # Signal completion to any watching processes
            touch "${RESULTS_DIR}/.processing_complete"
            break
        fi
        
        # Update master status
        echo "MASTER_STATUS=RUNNING" > "${MASTER_STATUS}"
        echo "LAST_CHECK=$(date +%s)" >> "${MASTER_STATUS}"
        
        # Sleep before next check - longer sleep to reduce flicker
        sleep 2
    done
    
    msg_info "Monitor complete. See ${FINAL_RESULTS} for results."
}

# Worker function that processes data
worker_process() {
    # Each worker will process a portion of the data
    local worker_id="${WORKER_ID}"
    local items_to_process="${ITEMS_PER_WORKER}"
    local data_dir="${DATA_DIR}"
    local results_dir="${RESULTS_DIR}"
    local status_file="${STATUS_DIR}/worker_${worker_id}.status"
    local results_file="${results_dir}/worker_${worker_id}_results.txt"
    
    # Clear the screen for a clean start
    clear
    
    # Initialize status file
    mkdir -p "$(dirname "${status_file}")"
    echo "WORKER_ID=${worker_id}" > "${status_file}"
    echo "WORKER_STATUS=RUNNING" >> "${status_file}"
    echo "START_TIME=$(date +%s)" >> "${status_file}"
    echo "ITEMS_PROCESSED=0" >> "${status_file}"
    echo "ITEMS_PER_WORKER=${items_to_process}" >> "${status_file}"
    echo "CURRENT_ITEM=0" >> "${status_file}"
    
    # Initialize results file
    echo "Worker ${worker_id} Results" > "${results_file}"
    echo "Started at: $(date)" >> "${results_file}"
    echo "-------------------" >> "${results_file}"
    
    msg_bg_blue "Worker ${worker_id} Started"
    msg_info "Processing ${items_to_process} items from ${data_dir}"
    echo "Results will be saved to ${results_file}"
    echo ""
    
    # Calculate which files this worker should process
    local start_item=$(( (worker_id - 1) * items_to_process + 1 ))
    local end_item=$(( start_item + items_to_process - 1 ))
    
    # Process files
    local items_processed=0
    for i in $(seq "${start_item}" "${end_item}"); do
        local data_file="${data_dir}/data_${i}.txt"
        
        # Update status file first
        echo "CURRENT_ITEM=${i}" >> "${status_file}"
        echo "CURRENT_FILE=${data_file}" >> "${status_file}"
        # Ensure status is written before master reads it
        sync
        
        echo "Processing item ${i}: ${data_file}"
        
        if [[ -f "${data_file}" ]]; then
            # Simulate processing
            echo "Processing data file ${i}..." 
            sleep "${PROCESSING_DELAY}"
            
            # Extract some data from the file (simple example)
            local random_values=$(grep "Random values:" "${data_file}" | cut -d':' -f2)
            local created_time=$(grep "Created at" "${data_file}" | cut -d':' -f2- | xargs)
            
            # Add results
            echo "Item ${i} processed at $(date)" >> "${results_file}"
            echo "  Source file: ${data_file}" >> "${results_file}"
            echo "  Created: ${created_time}" >> "${results_file}"
            echo "  Random values: ${random_values}" >> "${results_file}"
            
            # Calculate an average (simple example of processing)
            local sum=0
            for val in ${random_values}; do
                ((sum += val))
            done
            local count=$(echo "${random_values}" | wc -w)
            local avg=$(( sum / count ))
            
            echo "  Average value: ${avg}" >> "${results_file}"
            echo "" >> "${results_file}"
            
            # Update processed count
            ((items_processed++))
            echo "ITEMS_PROCESSED=${items_processed}" >> "${status_file}"
            # Ensure status is written
            sync
        else
            echo "  File not found!" >> "${results_file}"
        fi
    done
    
    # Update final status
    echo "WORKER_STATUS=COMPLETED" >> "${status_file}"
    echo "END_TIME=$(date +%s)" >> "${status_file}"
    echo "ITEMS_PROCESSED=${items_processed}" >> "${status_file}"
    # Ensure status is written
    sync
    
    msg_success "Worker ${worker_id} completed processing ${items_processed} items"
    echo "Results saved to ${results_file}"
    
    # Keep pane open to show results
    echo ""
    echo "Press Enter to close this pane..."
    read -r
}

#========================================================
# Main Program Function
#========================================================

main() {
    clear
    msg_header "${APP_NAME} v${APP_VERSION}"
    msg_info "Starting distributed data processing demo with tmux"
    
    # Create directories
    mkdir -p "${RESULTS_DIR}" "${STATUS_DIR}"
    
    # Generate test data
    DATA_DIR="${RESULTS_DIR}/data"
    TOTAL_DATA_FILES=$((NUM_WORKERS * ITEMS_PER_WORKER))
    generate_data "${DATA_DIR}" "${TOTAL_DATA_FILES}"
    
    # Create a new tmux session for data processing
    local session_name
    session_name=$(create_tmux_session "data_processor")
    if [[ -z "${session_name}" ]]; then
        msg_error "Failed to create tmux session. Exiting."
        exit 1
    fi
    msg_success "Created tmux session: ${session_name}"
    sleep 1
    
    # Start the master monitor in the first pane
    msg_info "Starting master monitor in pane 0"
    # Use the SH_GLOBALS_LOADED variable to ensure proper initialization in subshells
    execute_shell_function "${session_name}" 0 master_monitor "SH_GLOBALS_LOADED APP_NAME APP_VERSION NUM_WORKERS ITEMS_PER_WORKER RESULTS_DIR STATUS_DIR MASTER_STATUS FINAL_RESULTS TIMESTAMP"
    sleep 1  # Give master time to initialize
    
    # Create worker panes and start processing
    for worker_id in $(seq 1 "${NUM_WORKERS}"); do
        msg_info "Starting worker ${worker_id}"
        
        # Create a new pane
        local pane_idx
        if [[ ${worker_id} -eq 1 ]]; then
            # First worker gets a vertical split
            pane_idx=$(create_new_pane "${session_name}" "v")
        else
            # Other workers get horizontal splits from the last pane
            pane_idx=$(create_new_pane "${session_name}")
        fi
        
        if [[ -n "${pane_idx}" ]]; then
            msg_success "Created pane ${pane_idx} for worker ${worker_id}"
            
            # Start worker with shared variables
            WORKER_ID="${worker_id}"  # Set worker-specific ID
            # Use the SH_GLOBALS_LOADED variable to ensure proper initialization in subshells
            execute_shell_function "${session_name}" "${pane_idx}" worker_process "SH_GLOBALS_LOADED WORKER_ID ITEMS_PER_WORKER DATA_DIR RESULTS_DIR STATUS_DIR PROCESSING_DELAY"
            sleep 0.5  # Give each worker a moment to initialize
        else
            msg_error "Failed to create pane for worker ${worker_id}"
        fi
    done
    
    msg_info "Data processing job started in tmux session: ${session_name}"
    msg_info "All workers are running. Master is monitoring progress."
    msg_info "Results will be saved to: ${FINAL_RESULTS}"
    
    # Wait for processing to complete by checking for completion flag
    echo -e "\nWaiting for processing to complete..."
    while [[ ! -f "${RESULTS_DIR}/.processing_complete" ]]; do
        echo -ne "Processing in progress...\r"
        sleep 1
    done
    
    msg_success "Processing complete!"
    echo "You can view results at: ${FINAL_RESULTS}"
    echo "To reattach to the tmux session: tmux attach-session -t ${session_name}"
    
    return 0
}

# Run the main function
main "$@" 