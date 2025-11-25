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

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[ERROR] Config file not found: $CONFIG_FILE"
    exit 2
fi

if [[ ! -f "$UTILS_FILE" ]]; then
    echo "[ERROR] Utils file not found: $UTILS_FILE"
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
    echo "[ERROR] Metric log file not found: $LOG_FILE"
    exit 2
fi

# Take last WINDOW_SIZE samples (value = last column)
values_raw="$(tail -n "$WINDOW_SIZE" "$LOG_FILE" | awk '{print $NF}')"

# Filter numeric lines only (if is_numeric available, could use it;
# here we use grep -E which is standard on Linux)
values="$(printf '%s\n' "$values_raw" | grep -E '^[0-9]+(\.[0-9]+)?$' || true)"

if [[ -z "$values" ]]; then
    echo "[ERROR] No numeric data available in $LOG_FILE"
    exit 2
fi

count=$(printf '%s\n' "$values" | wc -l)
if (( count < 2 )); then
    echo "[ERROR] Not enough data points for anomaly detection (need >= 2, have $count)"
    exit 2
fi

# ----- Compute mean using awk -----
mean=$(printf '%s\n' "$values" | awk '{sum+=$1} END {if (NR>0) print sum/NR; else print 0}')

# ----- Compute standard deviation -----
std=$(printf '%s\n' "$values" | awk -v m="$mean" '
{
    sum += ($1 - m) * ($1 - m)
}
END {
    if (NR>0) print sqrt(sum/NR); else print 0
}')

current=$(printf '%s\n' "$values" | tail -n 1)

# If std dev is zero, no variation → no anomaly
if (( $(echo "$std == 0" | bc -l) )); then
    echo "[OK] $LABEL: current=$current, mean=$mean, std=0 (no variation, no anomaly)"
    exit 0
fi

upper=$(echo "$mean + ($STD_DEV_FACTOR * $std)" | bc -l)

echo "[INFO] $LABEL: current=$current, mean=$mean, std=$std, upper_limit=$upper"

if (( $(echo "$current > $upper" | bc -l) )); then
    echo "[ANOMALY] $LABEL: $current > mean + $STD_DEV_FACTOR * std ($upper)"
    exit 1
else
    echo "[OK] No anomaly detected for $LABEL."
    exit 0
fi