
function to_color() {
    color="$1"

	case "$color" in
	    "BLACK") 
	        echo -ne "${BLACK}" 
	        ;;
	    "RED") 
	        echo -ne "${RED}" 
	        ;;
	    "GREEN") 
	        echo -ne "${GREEN}" 
	        ;;
	    "YELLOW") 
	        echo -ne "${YELLOW}" 
	        ;;
	    "BLUE") 
	        echo -ne "${BLUE}" 
	        ;;
	    "MAGENTA") 
	        echo -ne "${MAGENTA}" 
	        ;;
	    "CYAN") 
	        echo -ne "${CYAN}" 
	        ;;
	    "WHITE") 
	        echo -ne "${WHITE}" 
	        ;;
	    "BG_BLACK") 
	        echo -ne "${BG_BLACK}" 
	        ;;
	    "BG_RED") 
	        echo -ne "${BG_RED}" 
	        ;;
	    "BG_GREEN") 
	        echo -ne "${BG_GREEN}" 
	        ;;
	    "BG_YELLOW") 
	        echo -ne "${BG_YELLOW}" 
	        ;;
	    "BG_BLUE") 
	        echo -ne "${BG_BLUE}" 
	        ;;
	    "BG_MAGENTA") 
	        echo -ne "${BG_MAGENTA}" 
	        ;;
	    "BG_CYAN") 
	        echo -ne "${BG_CYAN}" 
	        ;;
	    "BG_WHITE") 
	        echo -ne "${BG_WHITE}" 
	        ;;
	    "BOLD") 
	        echo -ne "${BOLD}" 
	        ;;
	    "UNDERLINE") 
	        echo -ne "${UNDERLINE}" 
	        ;;
	    "INVERT") 
	        echo -ne "${INVERT}" 
	        ;;
	    *) 
	        echo -ne "${RESET}" 
	        ;;  # Reset if no match
	esac
}