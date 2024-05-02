# Function to log messages with different log levels
log() {
    local level=$1
    local message=$2
    
    case $level in
        "ERROR")
            echo -e "${RED}[ERROR]${RESET} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${RESET} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${RESET} $message"
            ;;
        "DEBUG")
            if [ "$debug" -eq 1 ]; then
                echo -e "${BLUE}[DEBUG]${RESET} $message"
            fi
            ;;
        *)
            echo "Unknown log level: $level"
            ;;
    esac
}