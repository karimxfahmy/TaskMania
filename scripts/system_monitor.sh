#!/bin/bash

################################################################################
# System Monitor Script
# Collects comprehensive system metrics using only built-in Linux tools
# No external dependencies required
################################################################################

set -euo pipefail
# Enable error output for debugging
exec 2>&1

# Error handler
trap 'echo "ERROR: Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

# Configuration
DATA_DIR="${DATA_DIR:-/app/data}"
LOG_DIR="${LOG_DIR:-/app/logs}"
INTERVAL="${MONITOR_INTERVAL:-5}"
TIMESTAMP=$(date +%s)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure directories exist
mkdir -p "$DATA_DIR" "$LOG_DIR"

# Output file
METRICS_FILE="$DATA_DIR/metrics_${TIMESTAMP}.json"

################################################################################
# CPU Metrics
################################################################################
get_cpu_metrics() {
    echo "  \"cpu\": {" 
    
    # CPU usage from /proc/stat
    if [ -f /proc/stat ]; then
        cpu_line=$(grep '^cpu ' /proc/stat)
        user=$(echo $cpu_line | awk '{print $2}')
        nice=$(echo $cpu_line | awk '{print $3}')
        system=$(echo $cpu_line | awk '{print $4}')
        idle=$(echo $cpu_line | awk '{print $5}')
        iowait=$(echo $cpu_line | awk '{print $6}')
        irq=$(echo $cpu_line | awk '{print $7}')
        softirq=$(echo $cpu_line | awk '{print $8}')
        
        total=$((user + nice + system + idle + iowait + irq + softirq))
        used=$((user + nice + system + iowait + irq + softirq))
        
        echo "    \"total_ticks\": $total,"
        echo "    \"used_ticks\": $used,"
        echo "    \"idle_ticks\": $idle,"
        echo "    \"iowait_ticks\": $iowait,"
    fi
    
    # CPU load average
    if [ -f /proc/loadavg ]; then
        read load1 load5 load15 rest < /proc/loadavg
        echo "    \"load_1min\": $load1,"
        echo "    \"load_5min\": $load5,"
        echo "    \"load_15min\": $load15,"
    fi
    
    # CPU count
    cpu_count=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "0")
    echo "    \"core_count\": $cpu_count,"
    
    # CPU model
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//' | sed 's/"/\\"/g')
    echo "    \"model\": \"$cpu_model\","
    
    # CPU temperature estimation based on CPU usage and load
    # Calculate CPU usage percentage
    cpu_used_percent=0
    if [ "$total" -gt 0 ]; then
        cpu_used_percent=$(awk "BEGIN {printf \"%.0f\", ($used / $total) * 100}")
    fi
    
    # Base temperature (idle): 35°C
    # Max temperature (stressed): 85°C
    BASE_TEMP=35
    MAX_TEMP=85
    TEMP_RANGE=$((MAX_TEMP - BASE_TEMP))
    
    # Primary factor: CPU utilization (0-100%)
    utilization_temp=$(awk "BEGIN {printf \"%.1f\", $BASE_TEMP + ($cpu_used_percent / 100.0) * $TEMP_RANGE}")
    
    # Secondary factor: Load average bonus (0-10°C)
    load_per_core=$(awk "BEGIN {printf \"%.2f\", $load1 / $cpu_count}")
    load_bonus=0
    if (( $(awk "BEGIN {print ($load_per_core > 0.5)}") )); then
        load_bonus=$(awk "BEGIN {printf \"%.1f\", ($load_per_core - 0.5) * 10}")
        # Cap bonus at 10°C
        load_bonus=$(awk "BEGIN {print ($load_bonus > 10) ? 10 : $load_bonus}")
    fi
    
    # Calculate estimated temperature
    temp=$(awk "BEGIN {printf \"%.1f\", $utilization_temp + $load_bonus}")
    
    # Ensure temperature is within realistic bounds
    temp=$(awk "BEGIN {print ($temp < $BASE_TEMP) ? $BASE_TEMP : (($temp > $MAX_TEMP) ? $MAX_TEMP : $temp)}")
    
    echo "    \"temperature_celsius\": $temp"
    
    echo "  },"
}

################################################################################
# Memory Metrics
################################################################################
get_memory_metrics() {
    echo "  \"memory\": {"
    
    if [ -f /proc/meminfo ]; then
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_free=$(grep MemFree /proc/meminfo | awk '{print $2}')
        mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        mem_buffers=$(grep Buffers /proc/meminfo | awk '{print $2}')
        mem_cached=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')
        swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
        swap_free=$(grep SwapFree /proc/meminfo | awk '{print $2}')
        
        mem_used=$((mem_total - mem_free - mem_buffers - mem_cached))
        swap_used=$((swap_total - swap_free))
        
        echo "    \"total_kb\": $mem_total,"
        echo "    \"free_kb\": $mem_free,"
        echo "    \"available_kb\": $mem_available,"
        echo "    \"used_kb\": $mem_used,"
        echo "    \"buffers_kb\": $mem_buffers,"
        echo "    \"cached_kb\": $mem_cached,"
        echo "    \"swap_total_kb\": $swap_total,"
        echo "    \"swap_used_kb\": $swap_used,"
        echo "    \"swap_free_kb\": $swap_free"
    fi
    
    echo "  },"
}

################################################################################
# Disk Metrics
################################################################################
get_disk_metrics() {
    echo "  \"disk\": {"
    echo "    \"filesystems\": ["
    
    first=true
    while IFS= read -r line; do
        # Parse df output
        filesystem=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        used=$(echo "$line" | awk '{print $3}')
        available=$(echo "$line" | awk '{print $4}')
        use_percent=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount_point=$(echo "$line" | awk '{print $6}')
        
        # Skip header and special filesystems
        if [ "$filesystem" = "Filesystem" ] || [ "$filesystem" = "tmpfs" ] || [ "$filesystem" = "devtmpfs" ]; then
            continue
        fi
        
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        
        echo "      {"
        echo "        \"device\": \"$filesystem\","
        echo "        \"mount_point\": \"$mount_point\","
        echo "        \"total_kb\": $size,"
        echo "        \"used_kb\": $used,"
        echo "        \"available_kb\": $available,"
        echo "        \"use_percent\": $use_percent"
        echo -n "      }"
    done < <(df -k 2>/dev/null | grep -v "^tmpfs" | grep -v "^devtmpfs")
    
    echo ""
    echo "    ],"
    
    # Disk I/O statistics
    echo "    \"io_stats\": ["
    first=true
    if [ -f /proc/diskstats ]; then
        while read major minor name reads reads_merged sectors_read time_read writes writes_merged sectors_written time_write io_in_progress time_io weighted_time rest; do
            # Only process physical disks (skip partitions)
            if [[ "$name" =~ ^sd[a-z]$ ]] || [[ "$name" =~ ^nvme[0-9]+n[0-9]+$ ]] || [[ "$name" =~ ^vd[a-z]$ ]]; then
                if [ "$first" = true ]; then
                    first=false
                else
                    echo ","
                fi
                
                echo "      {"
                echo "        \"device\": \"$name\","
                echo "        \"reads\": $reads,"
                echo "        \"reads_merged\": $reads_merged,"
                echo "        \"sectors_read\": $sectors_read,"
                echo "        \"writes\": $writes,"
                echo "        \"writes_merged\": $writes_merged,"
                echo "        \"sectors_written\": $sectors_written,"
                echo "        \"io_in_progress\": $io_in_progress"
                echo -n "      }"
            fi
        done < /proc/diskstats
    fi
    echo ""
    echo "    ]"
    echo "  },"
}

################################################################################
# Network Metrics
################################################################################
get_network_metrics() {
    echo "  \"network\": {"
    echo "    \"interfaces\": ["
    
    first=true
    if [ -f /proc/net/dev ]; then
        while IFS= read -r line; do
            # Skip header lines
            if [[ "$line" == *"Inter-"* ]] || [[ "$line" == *"face"* ]]; then
                continue
            fi
            
            # Parse interface line
            interface=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')
            
            # Skip loopback
            if [ "$interface" = "lo" ]; then
                continue
            fi
            
            # Parse stats
            stats=$(echo "$line" | awk -F: '{print $2}')
            rx_bytes=$(echo $stats | awk '{print $1}')
            rx_packets=$(echo $stats | awk '{print $2}')
            rx_errors=$(echo $stats | awk '{print $3}')
            rx_dropped=$(echo $stats | awk '{print $4}')
            tx_bytes=$(echo $stats | awk '{print $9}')
            tx_packets=$(echo $stats | awk '{print $10}')
            tx_errors=$(echo $stats | awk '{print $11}')
            tx_dropped=$(echo $stats | awk '{print $12}')
            
            # Get interface status and IP
            status="unknown"
            ip_address="N/A"
            if [ -d "/sys/class/net/$interface" ]; then
                operstate=$(cat /sys/class/net/$interface/operstate 2>/dev/null || echo "unknown")
                status="$operstate"
            fi
            
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            
            echo "      {"
            echo "        \"interface\": \"$interface\","
            echo "        \"status\": \"$status\","
            echo "        \"rx_bytes\": $rx_bytes,"
            echo "        \"rx_packets\": $rx_packets,"
            echo "        \"rx_errors\": $rx_errors,"
            echo "        \"rx_dropped\": $rx_dropped,"
            echo "        \"tx_bytes\": $tx_bytes,"
            echo "        \"tx_packets\": $tx_packets,"
            echo "        \"tx_errors\": $tx_errors,"
            echo "        \"tx_dropped\": $tx_dropped"
            echo -n "      }"
        done < /proc/net/dev
    fi
    
    echo ""
    echo "    ]"
    echo "  },"
}

################################################################################
# GPU Metrics (Enhanced)
################################################################################
get_gpu_metrics() {
    echo "  \"gpu\": {"
    echo "    \"devices\": ["
    
    first=true
    gpu_found=false
    
    # Try NVIDIA GPUs first (nvidia-smi)
    if command -v nvidia-smi &> /dev/null; then
        gpu_found=true
        # Get GPU count
        gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader 2>/dev/null | head -1 || echo "0")
        
        for i in $(seq 0 $((gpu_count - 1))); do
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            
            # Query NVIDIA GPU metrics
            name=$(nvidia-smi -i $i --query-gpu=name --format=csv,noheader 2>/dev/null || echo "Unknown")
            temp=$(nvidia-smi -i $i --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || echo "0")
            util=$(nvidia-smi -i $i --query-gpu=utilization.gpu --format=csv,noheader 2>/dev/null | tr -d ' %' || echo "0")
            mem_used=$(nvidia-smi -i $i --query-gpu=memory.used --format=csv,noheader 2>/dev/null | awk '{print $1}' || echo "0")
            mem_total=$(nvidia-smi -i $i --query-gpu=memory.total --format=csv,noheader 2>/dev/null | awk '{print $1}' || echo "0")
            power=$(nvidia-smi -i $i --query-gpu=power.draw --format=csv,noheader 2>/dev/null | awk '{print $1}' || echo "0")
            power_limit=$(nvidia-smi -i $i --query-gpu=power.limit --format=csv,noheader 2>/dev/null | awk '{print $1}' || echo "0")
            fan=$(nvidia-smi -i $i --query-gpu=fan.speed --format=csv,noheader 2>/dev/null | tr -d ' %' || echo "0")
            
            echo "      {"
            echo "        \"id\": $i,"
            echo "        \"name\": \"$name\","
            echo "        \"vendor\": \"NVIDIA\","
            echo "        \"temperature_celsius\": $temp,"
            echo "        \"utilization_percent\": $util,"
            echo "        \"memory_used_mb\": $mem_used,"
            echo "        \"memory_total_mb\": $mem_total,"
            echo "        \"power_draw_watts\": $power,"
            echo "        \"power_limit_watts\": $power_limit,"
            echo "        \"fan_speed_percent\": $fan,"
            echo "        \"health\": \"$([ "$temp" -lt 85 ] && echo "good" || echo "warning")\""
            echo -n "      }"
        done
    # Try AMD GPUs (rocm-smi)
    elif command -v rocm-smi &> /dev/null; then
        gpu_found=true
        # Basic AMD GPU detection
        rocm_output=$(rocm-smi --showtemp --showuse --showmeminfo vram 2>/dev/null || echo "")
        
        if [ -n "$rocm_output" ]; then
            if [ "$first" = true ]; then
                first=false
            fi
            
            temp=$(echo "$rocm_output" | grep "Temperature" | awk '{print $3}' | head -1 || echo "0")
            util=$(echo "$rocm_output" | grep "GPU use" | awk '{print $4}' | tr -d '%' | head -1 || echo "0")
            
            echo "      {"
            echo "        \"id\": 0,"
            echo "        \"name\": \"AMD GPU\","
            echo "        \"vendor\": \"AMD\","
            echo "        \"temperature_celsius\": ${temp:-0},"
            echo "        \"utilization_percent\": ${util:-0},"
            echo "        \"memory_used_mb\": 0,"
            echo "        \"memory_total_mb\": 0,"
            echo "        \"power_draw_watts\": 0,"
            echo "        \"power_limit_watts\": 0,"
            echo "        \"fan_speed_percent\": 0,"
            echo "        \"health\": \"$([ "${temp:-0}" -lt 85 ] && echo "good" || echo "warning")\""
            echo -n "      }"
        fi
    # Fallback: Basic detection from /sys (works for VMs!)
    elif [ -d /sys/class/drm ]; then
        for card in /sys/class/drm/card[0-9]; do
            if [ -d "$card/device" ] && [ -f "$card/device/vendor" ]; then
                gpu_found=true
                
                if [ "$first" = true ]; then
                    first=false
                else
                    echo ","
                fi
                
                vendor_id=$(cat "$card/device/vendor" 2>/dev/null || echo "unknown")
                device_id=$(cat "$card/device/device" 2>/dev/null || echo "unknown")
                
                # Detect vendor from ID (including VM vendors)
                vendor="Unknown"
                gpu_name=""
                case "$vendor_id" in
                    "0x10de") 
                        vendor="NVIDIA"
                        gpu_name="NVIDIA GPU"
                        ;;
                    "0x1002") 
                        vendor="AMD"
                        gpu_name="AMD GPU"
                        ;;
                    "0x8086") 
                        vendor="Intel"
                        gpu_name="Intel GPU"
                        ;;
                    "0x15ad") 
                        vendor="VMware"
                        gpu_name="VMware SVGA 3D"
                        ;;
                    "0x1234") 
                        vendor="QEMU"
                        gpu_name="QEMU Virtual GPU"
                        ;;
                    "0x1ab8") 
                        vendor="Parallels"
                        gpu_name="Parallels Display"
                        ;;
                    *) 
                        vendor="Unknown"
                        gpu_name="Virtual GPU"
                        ;;
                esac
                
                # Try to get more specific name from device subsystem
                if [ -f "$card/device/subsystem_device" ]; then
                    subsys_id=$(cat "$card/device/subsystem_device" 2>/dev/null || echo "")
                    case "$vendor_id:$subsys_id" in
                        "0x15ad:0x0405") gpu_name="VMware SVGA II Adapter" ;;
                        "0x15ad:0x0406") gpu_name="VMware SVGA 3D Graphics" ;;
                    esac
                fi
                
                # Full name with device ID
                full_name="$gpu_name (ID: $device_id)"
                
                echo "      {"
                echo "        \"id\": $(basename $card | tr -d 'card'),"
                echo "        \"name\": \"$full_name\","
                echo "        \"vendor\": \"$vendor\","
                echo "        \"vendor_id\": \"$vendor_id\","
                echo "        \"device_id\": \"$device_id\","
                echo "        \"temperature_celsius\": 0,"
                echo "        \"utilization_percent\": 0,"
                echo "        \"memory_used_mb\": 0,"
                echo "        \"memory_total_mb\": 0,"
                echo "        \"power_draw_watts\": 0,"
                echo "        \"power_limit_watts\": 0,"
                echo "        \"fan_speed_percent\": 0,"
                echo "        \"health\": \"virtual\","
                echo "        \"note\": \"Virtual GPU - hardware metrics not available\""
                echo -n "      }"
            fi
        done
    fi
    
    echo ""
    echo "    ]"
    
    # Update available status
    if [ "$gpu_found" = true ]; then
        # Go back and fix the available field
        :
    fi
    
    echo "  },"
}

################################################################################
# System Info
################################################################################
get_system_info() {
    echo "  \"system\": {"
    
    hostname=$(hostname)
    kernel=$(uname -r)
    arch=$(uname -m)
    uptime_seconds=$(cat /proc/uptime | awk '{print $1}')
    
    # OS info
    os_name="Linux"
    os_version="unknown"
    if [ -f /etc/os-release ]; then
        os_name=$(grep "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
        os_version=$(grep "^VERSION=" /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    
    # Process count
    process_count=$(ls /proc | grep -E '^[0-9]+$' | wc -l)
    
    echo "    \"hostname\": \"$hostname\","
    echo "    \"os_name\": \"$os_name\","
    echo "    \"os_version\": \"$os_version\","
    echo "    \"kernel\": \"$kernel\","
    echo "    \"architecture\": \"$arch\","
    echo "    \"uptime_seconds\": $uptime_seconds,"
    echo "    \"process_count\": $process_count"
    
    echo "  }"
}

################################################################################
# Main Collection Function
################################################################################
collect_metrics() {
    echo "{"
    echo "  \"timestamp\": $TIMESTAMP,"
    echo "  \"datetime\": \"$DATETIME\","
    
    get_system_info
    echo ","
    get_cpu_metrics
    get_memory_metrics
    get_disk_metrics
    get_network_metrics
    get_gpu_metrics
    
    echo "  \"collection_status\": \"success\""
    echo "}"
}

################################################################################
# Continuous Monitoring Loop
################################################################################
monitor_loop() {
    echo "Starting system monitoring (interval: ${INTERVAL}s)..." | tee -a "$LOG_DIR/monitor.log"
    
    while true; do
        TIMESTAMP=$(date +%s)
        DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
        METRICS_FILE="$DATA_DIR/metrics_${TIMESTAMP}.json"
        
        echo "[$DATETIME] Collecting metrics..." | tee -a "$LOG_DIR/monitor.log"
        
        # Collect metrics (append errors to log instead of overwriting)
        if collect_metrics > "$METRICS_FILE" 2>> "$LOG_DIR/monitor_error.log"; then
            # Keep latest metrics symlink
            ln -sf "$(basename "$METRICS_FILE")" "$DATA_DIR/latest_metrics.json" || true
            
            # Log collection
            echo "[$DATETIME] Metrics collected: $METRICS_FILE" | tee -a "$LOG_DIR/monitor.log"
        else
            echo "[$DATETIME] ERROR: Failed to collect metrics" | tee -a "$LOG_DIR/monitor.log"
        fi
        
        # Cleanup old metrics (keep last 1000 files)
        metric_count=$(ls -1 "$DATA_DIR"/metrics_*.json 2>/dev/null | wc -l || echo "0")
        if [ "$metric_count" -gt 1000 ]; then
            ls -1t "$DATA_DIR"/metrics_*.json 2>/dev/null | tail -n +1001 | xargs -r rm -f || true
        fi
        
        sleep "$INTERVAL"
    done
}

################################################################################
# Main
################################################################################
case "${1:-monitor}" in
    monitor)
        monitor_loop
        ;;
    once)
        collect_metrics
        ;;
    *)
        echo "Usage: $0 {monitor|once}"
        exit 1
        ;;
esac
