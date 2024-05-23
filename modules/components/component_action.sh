
function component_action() {
	local action=$1
	local component=$2

	pushd "../microservices/$microservice"

    case $action_option in
        "restart")
            echo "Restarting $component"
            restart
            ;;
        "stop")
            echo "Stopping $component"
            stop
            ;;
        "start")
            echo "Starting $component"
            start
            ;;
        "update")
            echo "Updating $component"
            update
            ;;
        *)
            echo "Invalid action option: $action_option for components"
            popd
            usage
            ;;
    esac

}