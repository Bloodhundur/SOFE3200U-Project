#!/bin/bash
# Anomaly detection using mean + standard deviation (Linux)
#
# Usage (from project root):
#   ./scripts/threshold_anomaly/anomaly.sh cpu
#   ./scripts/threshold_anomaly/anomaly.sh mem
#   ./scripts/threshold_anomaly/anomaly.sh disk
#   ./scripts/threshold_anomaly/anomaly.sh net
#   ./scripts/threshold_anomaly/anomaly.sh logs/custom_metric.log
#
# Exit codes:
#   0 = no anomaly
#   1 = anomaly detected
#   2 = input / data error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG_FILE="$PROJECT_ROOT/scripts/threshold_anomaly/config.conf"
UTILS_FILE="$PROJECT_ROOT/scripts/threshold_anomaly/utils.sh"
ALERT_SCRIPT="$PROJECT_ROOT/scripts/alert.sh"

# Load config and utils
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[ERROR] Config file not found: $CONFIG_FILE" >&2
    exit 2
fi

if [[ ! -f "$UTILS_FILE" ]]; then
    echo "[ERROR] Utils file not found: $UTILS_FILE" >&2
    exit 2
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"
# shellcheck disable=SC1090
source "$UTILS_FILE"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 {cpu|mem|disk|net|/path/to/log}" >&2
    exit 2
fi

arg="$1"
LOG_FILE=""
LABEL=""

case "$arg" in
    cpu)
        LOG_FILE="$PROJECT_ROOT/$CPU_LOG"
        LABEL="CPU usage (%)"
        ;;
    mem|memory)
        LOG_FILE="$PROJECT_ROOT/$MEM_LOG"
        LABEL="Memory usage (%)"
        ;;
    disk)
        LOG_FILE="$PROJECT_ROOT/$DISK_LOG"
        LABEL="Disk usage (%)"
        ;;
    net|network)
        LOG_FILE="$PROJECT_ROOT/$NET_LOG"
        LABEL="Network usage (KB/s)"
        ;;
    *)
        # Treat as custom log path (absolute or relative)
        LOG_FILE="$arg"
        LABEL="Custom metric ($arg)"
        ;;
esac

if [[ ! -f "$LOG_FILE" ]]; then
    echo "[ERROR] Metric log file not found: $LOG_FILE" >&2
    exit 2
fi

WINDOW_SIZE="${WINDOW_SIZE:-10}"

# --------------------------------------------------------------------
# Extract numeric values from the last WINDOW_SIZE lines of the log.
# We DON'T trust the last column because lines look like:
#   "CPU: 0%"
#   "DISK: 26%"
#   "NET iface:enp0s3 rx:... tx:1275615"
# Instead, we grab ALL numbers from those lines and then keep only
# the last WINDOW_SIZE numeric values.
# --------------------------------------------------------------------
numeric_values="$(
    tail -n "$WINDOW_SIZE" "$LOG_FILE" | grep -Eo '[0-9]+(\.[0-9]+)?'
)"

# Clean out empty lines
numeric_values="$(printf '%s\n' "$numeric_values" | sed '/^$/d')"
count=$(printf '%s\n' "$numeric_values" | wc -l)

if (( count < 2 )); then
    echo "[ERROR] Not enough numeric data points in $LOG_FILE for anomaly detection (have $count, need >= 2)" >&2
    exit 2
fi

# If there are more numeric tokens than WINDOW_SIZE, take only the last WINDOW_SIZE
if (( count > WINDOW_SIZE )); then
    numeric_values="$(printf '%s\n' "$numeric_values" | tail -n "$WINDOW_SIZE")"
    count="$WINDOW_SIZE"
fi

# Split into historical (all but last) and current (last)
current="$(printf '%s\n' "$numeric_values" | tail -n 1)"
historical="$(printf '%s\n' "$numeric_values" | head -n $((count - 1)))"

hist_count=$(printf '%s\n' "$historical" | wc -l)
if (( hist_count < 1 )); then
    echo "[ERROR] Not enough historical data points for anomaly detection (have $hist_count)" >&2
    exit 2
fi

# ------ Compute mean (historical only) ------
mean=$(printf '%s\n' "$historical" | awk '{sum+=$1} END {if (NR>0) print sum/NR; else print 0}')

# ------ Compute standard deviation (historical only) ------
std=$(printf '%s\n' "$historical" | awk -v m="$mean" '{
    sum += ($1 - m)^2
} END {
    if (NR>0) print sqrt(sum/NR); else print 0
}')

# If std dev is zero, no variation → no anomaly
if (( $(echo "$std == 0" | bc -l) )); then
    echo "[OK] $LABEL: current=$current, mean=$mean, std=0 (no variation, no anomaly)"
    exit 0
fi

upper=$(echo "$mean + ($STD_DEV_FACTOR * $std)" | bc -l)

echo "[INFO] $LABEL: current=$current, mean=$mean, std=$std, upper_limit=$upper"

if (( $(echo "$current > $upper" | bc -l) )); then
    message="[ANOMALY] $LABEL: $current > mean + $STD_DEV_FACTOR * std ($upper)"
    echo "$message"

    # send notification using alert.sh through email and slack
    if [[ -f "$ALERT_SCRIPT" ]]; then
        bash "$ALERT_SCRIPT" "$message"
    else
        echo "[ERROR] alert.sh not found at $ALERT_SCRIPT"
    fi

    exit 1
else
    echo "[OK] No anomaly detected for $LABEL."
    exit 0
fi
