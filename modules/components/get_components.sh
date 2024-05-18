
get_components_result=""

function get_components() {
	declare -A component_options=()

	component_options["MySQL"]="mysql"
	component_options["JRegistry"]="jregistry"
	component_options["GreenMail"]="greenmail"
	component_options["RoundCube"]="roundcube"

	get_components_result=$(build_options component_options)
}