
function store_push() {
	local value=$1
	
	echo "$value" >> $file_store
}

function store_peek() {
	local key_value_pair=$(tail -n 1 "$file_store")
	local value="${key_value_pair#*=}"

	echo "$value"
}
