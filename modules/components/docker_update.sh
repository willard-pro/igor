
function docker_update() {
  docker-compose stop
  docker-compose pull
  docker-compose up -d
}
