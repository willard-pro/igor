
function docker_start() {
  docker_start_output=$(docker-compose start 2>&1)

  if [[ $docker_start_output =~ "failed" ]]; then
    docker-compose up -d
  fi
}
