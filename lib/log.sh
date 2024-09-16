# Function to log messages with different log levels
function log() {
    local level=$1
    local message=$2
    
    case $level in
        "IGOR")
            echo -e "${BG_WHITE}${BLACK}[IGOR]${RESET} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${RESET} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${RESET} $message"
            ;;
        "INFO")
            if [[ "$debug" -eq 1 || "$development" -eq 1 || "$enhancement" -eq 1 ]]; then
                echo -e "${GREEN}[INFO]${RESET} $message"
            fi
            ;;
        "DEBUG")
            if [[ "$debug" -eq 1 && ("$development" -eq 1 || "$enhancement" -eq 1) ]]; then
                echo -e "${BLUE}[DEBUG]${RESET} $message"
            fi
            ;;
        "TRACE")
            echo -e "${BG_RED}${WHITE}[TRACE]${RESET} $message"
            ;;
        *)
            echo "Unknown log level: $level"
            ;;
    esac
}

function log_phrase() {
    # Get a random line from the file
    if command -v "shuf" &> /dev/null; then
        local random_phrase=$(shuf -n 1 "$config_dir/phrases.txt")
        log IGOR "$random_phrase"
    else
        log IGOR "Good bye"
    fi
}
