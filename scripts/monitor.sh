#!/bin/bash

# find project folder
base_dir="$(dirname "$(realpath "$0")")/.."

# make sure logs directory exists
mkdir -p "$base_dir/logs"

# time for logs
timestamp="$(date +"%Y-%m-%d %H:%M:%S")"

# log files
cpu_log="$base_dir/logs/cpu.log"
mem_log="$base_dir/logs/memory.log"
disk_log="$base_dir/logs/disk.log"
net_log="$base_dir/logs/network.log"
services_log="$base_dir/logs/services.log"
app_log="$base_dir/logs/app_errors.log"   # NEW: application/system log monitoring

# ---------------- CPU ----------------
# CPU usage (user + system)
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
echo "$timestamp CPU: $cpu_usage%" >> "$cpu_log"

# ---------------- Memory ----------------
# memory usage %
mem_usage=$(free | awk '/Mem:/ {printf("%.2f", $3/$2 * 100)}')
echo "$timestamp MEM: $mem_usage%" >> "$mem_log"

# ---------------- Disk ----------------
# disk usage for /
disk_usage=$(df -h / | awk 'NR==2 {print $5}')
echo "$timestamp DISK: $disk_usage" >> "$disk_log"

# ---------------- Network ----------------
# network interface (first non-lo)
iface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# bytes in/out
rx=$(cat /sys/class/net/$iface/statistics/rx_bytes)
tx=$(cat /sys/class/net/$iface/statistics/tx_bytes)

echo "$timestamp NET iface:$iface rx:$rx tx:$tx" >> "$net_log"

# ---Service Monitoring---

down_message=""

# Apache check
if systemctl is-active --quiet apache2; then
    echo "$timestamp Apache: running" >> "$services_log"
else
    down_message+="Apache DOWN; "
fi

# MySQL check
if systemctl is-active --quiet mysql; then
    echo "$timestamp MySQL: running" >> "$services_log"
else
    down_message+="MySQL DOWN; "
fi

# Nginx check
if systemctl is-active --quiet nginx; then
    echo "$timestamp Nginx: running" >> "$services_log"
else
    down_message+="Nginx DOWN; "
fi

# If any service was down, log one combined message and send alert
if [[ -n "$down_message" ]]; then
    message="$timestamp Services issue: $down_message"
    echo "$message" >> "$services_log"
    echo "$message"

    # send notification through alert.sh
    if [[ -f "$base_dir/scripts/alert.sh" ]]; then
        bash "$base_dir/scripts/alert.sh" "$message"
    else
        echo "[ERROR] alert.sh not found at $base_dir/scripts/alert.sh"
    fi
fi

# --- Application / System Log Monitoring (NEW) ---
# Grab recent error-like lines from /var/log/syslog and append to app_errors.log
if [[ -f /var/log/syslog ]]; then
    {
        echo
        echo "===== $timestamp - Recent application/system errors from /var/log/syslog ====="
        grep -iE "error|failed|failure|warning" /var/log/syslog | tail -n 20
    } >> "$app_log"
fi

#--------------------------------------------------------------------------
# After logging metrics, run anomaly detection
"$base_dir"/scripts/threshold_anomaly/anomaly.sh cpu
"$base_dir"/scripts/threshold_anomaly/anomaly.sh mem
"$base_dir"/scripts/threshold_anomaly/anomaly.sh disk
"$base_dir"/scripts/threshold_anomaly/anomaly.sh net
