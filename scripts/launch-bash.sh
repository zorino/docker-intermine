#!/bin/bash
# Launches bash inside the intermine container

MINE_NAME=$1
[ -z "$MINE_NAME" ] && {
  echo "Missing script argument. Exiting."
  echo -e "\nUsage: $0 <mine name>"
  echo -e "\t<mine name>: name of the intermine container you want to reach"
  exit 1
}

MINE_CONTAINER_ID=$(docker ps | grep ${MINE_NAME}_main | cut -f1 -d$' ')
[ -z "$MINE_CONTAINER_ID" ] && {
  echo "No $MINE_NAME intermine container running. Exiting."
  exit 1
}
docker exec -it $MINE_CONTAINER_ID bash
