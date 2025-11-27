#!/bin/bash

echo "Script Started"

# Project root
base_dir="$(dirname "$(realpath "$0")")"
monitor_path="${base_dir}/scripts/monitor.sh"
anomaly_path="${base_dir}/scripts/threshold_anomaly/anomaly.sh"
cron_line="*/1 * * * * $monitor_path"

echo "Monitor Ready"

start_cron() {
    # check if cron job already exists
    crontab -l 2>/dev/null | grep -F "$monitor_path" >/dev/null
    if [[ $? -eq 0 ]]; then
        echo "Cron is already running."
    else
        # add cron job
        (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
        echo "Cron started (runs every 1m)."
    fi
}

stop_cron() {
    # remove the cron job
    crontab -l 2>/dev/null | grep -v "$monitor_path" | crontab -
    echo "Cron stopped."
}

while ((1)); do
    read -p "Enter Command (h for help): " cmd

    case "$cmd" in
        h)
            echo "Commands:"
            echo "e = exit"
            echo "c = collect once"
            echo "p = print logs"
            echo "d = delete logs"
            echo "a = check logs for anomalies"
            echo "cl = clear screen"
            echo "sc = start cron"
            echo "xc = stop cron"
            ;;

        e)
            stop_cron        # auto-stop cron when exiting
            echo "Exiting..."
            exit 0
            ;;

        c)
            "$monitor_path"
            ;;

        a)
            echo "Run anomaly detection on which metric (enter number only)"
            echo "1) CPU"
            echo "2) Memory"
            echo "3) Disk"
            echo "4) Network"
            read -p "> " choice

            case "$choice" in
                1) "$anomaly_path" cpu ;;
                2) "$anomaly_path" mem ;;
                3) "$anomaly_path" disk ;;
                4) "$anomaly_path" net ;;
                *)
                    echo "Invalid"
                    ;;
            esac
            ;;

        sc)
            start_cron
            ;;

        xc)
            stop_cron
            ;;

        p)
            echo "Which log?"
            echo "1) CPU"
            echo "2) Memory"
            echo "3) Disk"
            echo "4) Network"
            echo "5) All"
            read -p "> " choice

            case "$choice" in
                1) cat "${base_dir}/logs/cpu.log" ;;
                2) cat "${base_dir}/logs/memory.log" ;;
                3) cat "${base_dir}/logs/disk.log" ;;
                4) cat "${base_dir}/logs/network.log" ;;
                5)
                    echo "--- CPU ---"
                    cat "${base_dir}/logs/cpu.log"
                    echo
                    echo "--- MEMORY ---"
                    cat "${base_dir}/logs/memory.log"
                    echo
                    echo "--- DISK ---"
                    cat "${base_dir}/logs/disk.log"
                    echo
                    echo "--- NETWORK ---"
                    cat "${base_dir}/logs/network.log"
                    ;;
                *)
                    echo "Invalid"
                    ;;
            esac
            ;;

        d)
            echo "Clearing logs..."
            : > "${base_dir}/logs/cpu.log"
            : > "${base_dir}/logs/memory.log"
            : > "${base_dir}/logs/disk.log"
            : > "${base_dir}/logs/network.log"
            echo "Logs cleared."
            ;;

        cl)
            clear
            ;;

        *)
            echo "Invalid Command"
            ;;
    esac

done
