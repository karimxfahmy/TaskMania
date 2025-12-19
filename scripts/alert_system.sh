#!/bin/bash

################################################################################
# Alert System Script
# Monitors metrics and triggers alerts for critical events
# No external dependencies required
################################################################################

set -euo pipefail

# Configuration
DATA_DIR="${DATA_DIR:-/app/data}"
LOG_DIR="${LOG_DIR:-/app/logs}"
ALERT_LOG="$LOG_DIR/alerts.log"
CONFIG_FILE="${ALERT_CONFIG:-/app/config/alert_config.conf}"

# Default thresholds (can be overridden by config file)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
SWAP_THRESHOLD=70
LOAD_THRESHOLD=4.0
TEMP_THRESHOLD=80.0

# Alert cooldown (seconds) - prevent alert spam
ALERT_COOLDOWN=300
LAST_ALERT_FILE="$DATA_DIR/last_alerts.state"

# Ensure directories exist
mkdir -p "$DATA_DIR" "$LOG_DIR"

################################################################################
# Load Configuration
################################################################################
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Loading config from $CONFIG_FILE" >> "$ALERT_LOG"
        source "$CONFIG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Config file not found, using defaults" >> "$ALERT_LOG"
    fi
}

################################################################################
# Alert Cooldown Check
################################################################################
should_alert() {
    local alert_type="$1"
    local current_time=$(date +%s)
    
    if [ ! -f "$LAST_ALERT_FILE" ]; then
        return 0
    fi
    
    local last_alert_time=$(grep "^${alert_type}=" "$LAST_ALERT_FILE" 2>/dev/null | cut -d= -f2 || echo "0")
    local time_diff=$((current_time - last_alert_time))
    
    if [ "$time_diff" -gt "$ALERT_COOLDOWN" ]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Record Alert Time
################################################################################
record_alert() {
    local alert_type="$1"
    local current_time=$(date +%s)
    
    # Update or add alert time
    if [ -f "$LAST_ALERT_FILE" ]; then
        grep -v "^${alert_type}=" "$LAST_ALERT_FILE" > "${LAST_ALERT_FILE}.tmp" 2>/dev/null || true
        mv "${LAST_ALERT_FILE}.tmp" "$LAST_ALERT_FILE"
    fi
    
    echo "${alert_type}=${current_time}" >> "$LAST_ALERT_FILE"
}

################################################################################
# Send Alert
################################################################################
send_alert() {
    local severity="$1"
    local title="$2"
    local message="$3"
    local alert_type="$4"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local alert_json="{\"timestamp\":\"$timestamp\",\"severity\":\"$severity\",\"title\":\"$title\",\"message\":\"$message\"}"
    
    # Log alert
    echo "[$timestamp] [$severity] $title: $message" >> "$ALERT_LOG"
    
    # Save alert to file for web display
    echo "$alert_json" >> "$DATA_DIR/alerts.jsonl"
    
    # Keep only last 1000 alerts
    if [ -f "$DATA_DIR/alerts.jsonl" ]; then
        local line_count=$(wc -l < "$DATA_DIR/alerts.jsonl")
        if [ "$line_count" -gt 1000 ]; then
            tail -1000 "$DATA_DIR/alerts.jsonl" > "$DATA_DIR/alerts.jsonl.tmp"
            mv "$DATA_DIR/alerts.jsonl.tmp" "$DATA_DIR/alerts.jsonl"
        fi
    fi
    
    # Record alert time
    record_alert "$alert_type"
    
    # Output to console
    echo "[$timestamp] ALERT [$severity]: $title - $message"
}

################################################################################
# Check CPU Metrics
################################################################################
check_cpu() {
    local metrics_file="$1"
    
    # Extract CPU metrics
    local load_1min=$(grep -o '"load_1min": [0-9.]*' "$metrics_file" | awk '{print $2}')
    local core_count=$(grep -o '"core_count": [0-9]*' "$metrics_file" | awk '{print $2}')
    local temperature=$(grep -o '"temperature_celsius": [0-9.]*' "$metrics_file" | awk '{print $2}')
    
    # Calculate CPU usage percentage from load
    if [ -n "$load_1min" ] && [ -n "$core_count" ] && [ "$core_count" -gt 0 ]; then
        local cpu_percent=$(awk "BEGIN {printf \"%.0f\", ($load_1min / $core_count) * 100}")
        
        if [ "$cpu_percent" -ge "$CPU_THRESHOLD" ]; then
            if should_alert "cpu_high"; then
                send_alert "WARNING" "High CPU Usage" "CPU usage is ${cpu_percent}% (threshold: ${CPU_THRESHOLD}%)" "cpu_high"
            fi
        fi
        
        # Check load average
        local load_threshold_cores=$(awk "BEGIN {printf \"%.2f\", $core_count * $LOAD_THRESHOLD}")
        if (( $(awk "BEGIN {print ($load_1min > $load_threshold_cores)}") )); then
            if should_alert "cpu_load"; then
                send_alert "WARNING" "High System Load" "Load average ${load_1min} exceeds threshold ${load_threshold_cores}" "cpu_load"
            fi
        fi
    fi
    
    # Check temperature
    if [ "$temperature" != "null" ] && [ -n "$temperature" ]; then
        if (( $(awk "BEGIN {print ($temperature > $TEMP_THRESHOLD)}") )); then
            if should_alert "cpu_temp"; then
                send_alert "CRITICAL" "High CPU Temperature" "CPU temperature is ${temperature}°C (threshold: ${TEMP_THRESHOLD}°C)" "cpu_temp"
            fi
        fi
    fi
}

################################################################################
# Check Memory Metrics
################################################################################
check_memory() {
    local metrics_file="$1"
    
    # Extract memory metrics
    local mem_total=$(grep -o '"total_kb": [0-9]*' "$metrics_file" | awk '{print $2}')
    local mem_available=$(grep -o '"available_kb": [0-9]*' "$metrics_file" | awk '{print $2}')
    local swap_total=$(grep -o '"swap_total_kb": [0-9]*' "$metrics_file" | head -1 | awk '{print $2}')
    local swap_used=$(grep -o '"swap_used_kb": [0-9]*' "$metrics_file" | awk '{print $2}')
    
    # Calculate memory usage percentage
    if [ -n "$mem_total" ] && [ "$mem_total" -gt 0 ] && [ -n "$mem_available" ]; then
        local mem_used=$((mem_total - mem_available))
        local mem_percent=$(awk "BEGIN {printf \"%.0f\", ($mem_used / $mem_total) * 100}")
        
        if [ "$mem_percent" -ge "$MEMORY_THRESHOLD" ]; then
            if should_alert "memory_high"; then
                send_alert "WARNING" "High Memory Usage" "Memory usage is ${mem_percent}% (threshold: ${MEMORY_THRESHOLD}%)" "memory_high"
            fi
        fi
    fi
    
    # Check swap usage
    if [ -n "$swap_total" ] && [ "$swap_total" -gt 0 ] && [ -n "$swap_used" ]; then
        local swap_percent=$(awk "BEGIN {printf \"%.0f\", ($swap_used / $swap_total) * 100}")
        
        if [ "$swap_percent" -ge "$SWAP_THRESHOLD" ]; then
            if should_alert "swap_high"; then
                send_alert "WARNING" "High Swap Usage" "Swap usage is ${swap_percent}% (threshold: ${SWAP_THRESHOLD}%)" "swap_high"
            fi
        fi
    fi
}

################################################################################
# Check Disk Metrics
################################################################################
check_disk() {
    local metrics_file="$1"
    
    # Extract disk usage percentages
    while IFS= read -r line; do
        local mount_point=$(echo "$line" | grep -o '"mount_point": "[^"]*"' | cut -d'"' -f4)
        local use_percent=$(echo "$line" | grep -o '"use_percent": [0-9]*' | awk '{print $2}')
        
        if [ -n "$use_percent" ] && [ "$use_percent" -ge "$DISK_THRESHOLD" ]; then
            if should_alert "disk_${mount_point}"; then
                send_alert "WARNING" "High Disk Usage" "Disk ${mount_point} is ${use_percent}% full (threshold: ${DISK_THRESHOLD}%)" "disk_${mount_point}"
            fi
        fi
    done < <(grep -A 4 '"filesystems"' "$metrics_file" | grep -A 4 '{')
}

################################################################################
# Check Network Metrics
################################################################################
check_network() {
    local metrics_file="$1"
    
    # Check for network errors
    while IFS= read -r interface; do
        local rx_errors=$(echo "$interface" | grep -o '"rx_errors": [0-9]*' | awk '{print $2}')
        local tx_errors=$(echo "$interface" | grep -o '"tx_errors": [0-9]*' | awk '{print $2}')
        local if_name=$(echo "$interface" | grep -o '"interface": "[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$rx_errors" ] && [ "$rx_errors" -gt 100 ]; then
            if should_alert "network_${if_name}_rx"; then
                send_alert "WARNING" "Network RX Errors" "Interface ${if_name} has ${rx_errors} receive errors" "network_${if_name}_rx"
            fi
        fi
        
        if [ -n "$tx_errors" ] && [ "$tx_errors" -gt 100 ]; then
            if should_alert "network_${if_name}_tx"; then
                send_alert "WARNING" "Network TX Errors" "Interface ${if_name} has ${tx_errors} transmit errors" "network_${if_name}_tx"
            fi
        fi
    done < <(grep -A 10 '"interfaces"' "$metrics_file" | grep -A 10 '{')
}

################################################################################
# Check System Health
################################################################################
check_system_health() {
    local metrics_file="$1"
    
    # Check if metrics file is valid
    if ! grep -q '"collection_status": "success"' "$metrics_file"; then
        if should_alert "collection_failed"; then
            send_alert "CRITICAL" "Metrics Collection Failed" "Failed to collect system metrics" "collection_failed"
        fi
        return 1
    fi
    
    return 0
}

################################################################################
# Monitor Loop
################################################################################
monitor_loop() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting alert monitoring..." | tee -a "$ALERT_LOG"
    
    load_config
    
    while true; do
        # Check if latest metrics exist
        if [ -f "$DATA_DIR/latest_metrics.json" ]; then
            local metrics_file="$DATA_DIR/latest_metrics.json"
            
            # Run health checks
            if check_system_health "$metrics_file"; then
                check_cpu "$metrics_file"
                check_memory "$metrics_file"
                check_disk "$metrics_file"
                check_network "$metrics_file"
            fi
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] No metrics file found yet" >> "$ALERT_LOG"
        fi
        
        # Check every 30 seconds
        sleep 30
    done
}

################################################################################
# Test Alerts
################################################################################
test_alerts() {
    echo "Testing alert system..."
    send_alert "INFO" "Test Alert" "This is a test alert from the monitoring system" "test"
    send_alert "WARNING" "Test Warning" "This is a test warning alert" "test_warning"
    send_alert "CRITICAL" "Test Critical" "This is a test critical alert" "test_critical"
    echo "Test alerts sent. Check $ALERT_LOG and $DATA_DIR/alerts.jsonl"
}

################################################################################
# Main
################################################################################
case "${1:-monitor}" in
    monitor)
        monitor_loop
        ;;
    test)
        test_alerts
        ;;
    *)
        echo "Usage: $0 {monitor|test}"
        exit 1
        ;;
esac
