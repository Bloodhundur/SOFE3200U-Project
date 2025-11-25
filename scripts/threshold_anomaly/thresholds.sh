#!/bin/bash
# Threshold checking script (Linux)
#
# Exit codes:
#   0 = all metrics OK
#   1 = at least one threshold exceeded
#   2 = config or log error

set -euo pipefail

# ----- Determine project root -----
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

# Load config and utils
# shellcheck disable=SC1090
source "$CONFIG_FILE"
# shellcheck disable=SC1090
source "$UTILS_FILE"

# ----- Read latest metrics from logs -----
CPU_VAL="$(get_latest_value "$PROJECT_ROOT/$CPU_LOG"   || echo "NaN")"
MEM_VAL="$(get_latest_value "$PROJECT_ROOT/$MEM_LOG"   || echo "NaN")"
DISK_VAL="$(get_latest_value "$PROJECT_ROOT/$DISK_LOG" || echo "NaN")"
NET_VAL="$(get_latest_value "$PROJECT_ROOT/$NET_LOG"   || echo "NaN")"

if [[ "$CPU_VAL" == "NaN" || "$MEM_VAL" == "NaN" || "$DISK_VAL" == "NaN" || "$NET_VAL" == "NaN" ]]; then
    echo "[ERROR] Failed to read one or more metric logs."
    exit 2
fi

# ----- Compare values against thresholds using bc (Linux) -----
alert=0

compare_and_report() {
    local label="$1"
    local value="$2"
    local threshold="$3"
    local unit="$4"

    # Floating-point comparison using bc
    if (( $(echo "$value > $threshold" | bc -l) )); then
        echo "[THRESHOLD] $label HIGH: $value$unit (limit: $threshold$unit)"
        alert=1
    else
        echo "[OK] $label: $value$unit (limit: $threshold$unit)"
    fi
}

compare_and_report "CPU usage"     "$CPU_VAL"  "$CPU_THRESHOLD"  "%"
compare_and_report "Memory usage"  "$MEM_VAL"  "$MEM_THRESHOLD"  "%"
compare_and_report "Disk usage"    "$DISK_VAL" "$DISK_THRESHOLD" "%"
compare_and_report "Network usage" "$NET_VAL"  "$NET_THRESHOLD"  " KB/s"

exit "$alert"