#!/bin/bash
# Launches bash inside the intermine container

WEBAPP_CONTAINER_ID=$(docker ps | grep _webapp | cut -f1 -d$' ')
[ -z "$WEBAPP_CONTAINER_ID" ] && {
  echo "No intermine webapp container running. Exiting."
  exit 1
}
docker exec -it $WEBAPP_CONTAINER_ID bash
