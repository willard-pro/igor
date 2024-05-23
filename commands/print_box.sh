
function print_box() {
    local -n key_value_pairs=$1

    local box_width=29
    local key_value_width=$((box_width - 4))

    printf "╔"
    printf "═%.0s" $(seq 1 $((box_width - 2)))
    printf "╗\n"

  # Iterate over the keys and values of the associative array
    for key in "${!key_value_pairs[@]}"; do
        local value="${key_value_pairs[$key]}"
        printf "║ %-${key_value_width}s ║\n" "$key: $value"
    done

    printf "╚"
    printf "═%.0s" $(seq 1 $((box_width - 2)))
    printf "╝\n"

}