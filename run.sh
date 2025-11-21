echo "Script Started"

while ((1)) do
	read -p "Enter Command (h for help): " cmd
	
	case "$cmd" in
		h)
			echo "e to exit"
			;;
		e)
			echo "exiting"
			exit 1
			;;
		*)
		echo "Invaild Command"
		;;
	esac

done
