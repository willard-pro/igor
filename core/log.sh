# Function to log messages with different log levels
log() {
    local level=$1
    local message=$2
    
    case $level in
        "ERROR")
            echo -e "${RED}[ERROR] $message${RESET}"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN] $message${RESET}"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO] $message${RESET}"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG] $message${RESET}"
            ;;
        *)
            echo "Unknown log level: $level"
            ;;
    esac
}