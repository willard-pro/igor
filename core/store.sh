
store_value=""

function store_push() {
	local value=$1

	log DEBUG "Storin value $value"

	echo "$value" >> $file_store
}

function store_peek() {
	local key_value_pair=$(tail -n 1 "$file_store")
	store_value="${key_value_pair#*=}"
}
