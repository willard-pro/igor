
function is_zip_file() {
	local zip_file="$1"

	file "$zip_file" | grep -q 'Zip archive data'

	return $?
}