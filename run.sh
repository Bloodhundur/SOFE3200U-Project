#!/bin/bash

echo "Script Started"

base_dir="$(pwd)"
#cron_job="* * * * * $base_dir/"

echo "Cron Has Started"

while ((1)) do
	read -p "Enter Command (h for help): " cmd
	
	case "$cmd" in
		h)
			echo "e to exit"
			echo "c to collect"
			echo "p to print newest log"
			echo "delete logs"
			;;
		e)
			echo "exiting"
			exit 1
			;;
		c)
			echo "collecting logs"
			"${base_dir}/scripts/monitor.sh"
			;;
		p)
			cat "$(ls -t ${base_dir}/logs/*.txt | head -n 1)"
			;;
		d)
			echo "delete logs"
			;;
		*)
		echo "Invaild Command"
		;;
	esac

done
