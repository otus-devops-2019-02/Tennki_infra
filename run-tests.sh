#!/bin/bash
DOCKER_IMAGE=express42/otus-homeworks
echo "-=Run tests=-"
# Prepare network & run container
docker network create test-net 
docker run -d -v $(pwd):/srv -v /var/run/docker.sock:/tmp/docker.sock \
	-e DOCKER_HOST=unix:///tmp/docker.sock --cap-add=NET_ADMIN -p 33444:22 --privileged \
	--device /dev/net/tun --name test --network test-net $DOCKER_IMAGE
# Запуск скрипта с тестами
docker exec -e USER=appuser hw-test /srv/tests.sh
