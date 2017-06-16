#!/bin/bash
# Launches bash inside the intermine container

MINE_NAME=$1
[ -z "$MINE_NAME" ] && {
  echo "Missing script argument. Exiting."
  echo -e "\nUsage: $0 <mine name> [<conainter type>]"
  echo -e "\t<mine name>: name of the intermine container you want to reach"
  echo -e "\t<container type>: ('main' by default) caontiner types: main, postgres, tomcat"
  exit 1
}
CONTAINER_TYPE=main
[ -n "$2" ] && CONTAINER_TYPE=$2

SHELL=bash
[ -n "$3" ] && SHELL=$3

MINE_CONTAINER_ID=$(docker ps | grep ${MINE_NAME}_${CONTAINER_TYPE} | cut -f1 -d$' ')
[ -z "$MINE_CONTAINER_ID" ] && {
  echo "No $MINE_NAME intermine container running. Exiting."
  exit 1
}
docker exec -it $MINE_CONTAINER_ID $SHELL
