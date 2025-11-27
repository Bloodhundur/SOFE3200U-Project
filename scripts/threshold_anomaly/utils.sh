#!/bin/bash
# Common helper functions for Threshold & Anomaly Detection (Linux)

# Get the latest numeric value from a log file.
# Works with lines like:
#   "2025-11-26 21:23:19 CPU: 0%"
#   "2025-11-26 21:23:19 MEM: 29.22%"
#   "2025-11-26 21:23:19 DISK: 26%"
#   "2025-11-26 21:23:19 NET iface:enp0s3 rx:97298462 tx:1275615"
#
# In ALL cases, this will return the LAST number on the line:
#   0
#   29.22
#   26
#   1275615
#
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

    # Get the last line of the file
    local last_line
    last_line="$(tail -n 1 "$file")"

    # Extract all numeric tokens (ints/floats) and take the LAST one.
    # This strips %, "tx:", etc. automatically.
    local value
    value="$(printf '%s\n' "$last_line" | grep -Eo '[0-9]+(\.[0-9]+)?' | tail -n 1)"

    if [[ -z "$value" ]]; then
        echo "[ERROR] No numeric data found in last line of $file: '$last_line'" >&2
        return 1
    fi

    # Final sanity check
    if ! [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "[ERROR] Non-numeric value in $file: '$value' (from line: '$last_line')" >&2
        return 1
    fi

    echo "$value"
}

# Simple check: return 0 if value looks numeric, 1 otherwise
is_numeric() {
    local v="$1"
    [[ "$v" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}
