#!/bin/bash
# Common helper functions for Threshold & Anomaly Detection (Linux)

# Get the latest numeric value from a log file.
# Assumes the metric is in the LAST column of the LAST line.
# On success: prints the value and returns 0.
# On error: prints message to stderr and returns 1.
get_latest_value() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "[ERROR] Log file not found: $file" >&2
        return 1
    fi

    if [[ ! -s "$file" ]]; then
        echo "[ERROR] Log file is empty: $file" >&2
        return 1
    fi

    # Take last line, last field
    local value
    value="$(tail -n 1 "$file" | awk '{print $NF}')"

    # Check numeric (int or float)
    if ! [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "[ERROR] Non-numeric value in $file: '$value'" >&2
        return 1
    fi

    echo "$value"
}

# Simple check: return 0 if value looks numeric, 1 otherwise
is_numeric() {
    local v="$1"
    [[ "$v" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}