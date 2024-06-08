# Text color
BLACK='\e[30m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
WHITE='\e[37m'

# Background color
BG_BLACK='\e[40m'
BG_RED='\e[41m'
BG_GREEN='\e[42m'
BG_YELLOW='\e[43m'
BG_BLUE='\e[44m'
BG_MAGENTA='\e[45m'
BG_CYAN='\e[46m'
BG_WHITE='\e[47m'

# Text attributes
BOLD='\e[1m'
UNDERLINE='\e[4m'
INVERT='\e[7m'

# Reset
RESET='\e[0m'

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