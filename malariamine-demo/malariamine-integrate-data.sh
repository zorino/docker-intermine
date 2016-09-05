#!/bin/bash
# Connect to malariamine docker container launch data integration, postprocess and web app deployment

export MINE_NAME=malariamine
WEBAPP_CONTAINER_ID=$(docker ps | grep ${MINE_NAME}_main | cut -f1 -d$' ')
[ -z "$WEBAPP_CONTAINER_ID" ] && {
  echo "No malariamine docker container running. "
  echo "Please run ./docker-configure-run.sh. Exiting."
  exit 1
}

docker_exec() {
  CMD="docker exec $WEBAPP_CONTAINER_ID sh -c '$@'"
  echo $CMD
  eval $CMD
}

# Verify that tomcat is up and running inside malariamine container
docker_exec curl -sI tomcat:8080 &> /dev/null || {
  echo "Tomcat is not responding in the malaria mine docker container. "
  echo "Please make sure tomcat is running and re-run this script. Exiting."
  exit 1
}

# Clean & build database
docker_exec ant -f /intermine/$MINE_NAME/dbmodel/build.xml clean build-db
# Integrate sources
docker_exec ant -f /intermine/$MINE_NAME/integrate/build.xml -Dsource=all -v
# Postprocess
docker_exec ant -f /intermine/$MINE_NAME/postprocess/build.xml -v
# Clean & build user profiles
docker_exec ant -f /intermine/$MINE_NAME/webapp/build.xml build-db-userprofile
# Release webapp
docker_exec ant -f /intermine/$MINE_NAME/webapp/build.xml default remove-webapp release-webapp

## create psql dump
#DUMP_DIR=$DATA_DIR/intermine-psql-dump
#[ -d "$DUMP_DIR" ] || mkdir $DUMP_DIR
#$INTERMINE_DIR/bio/scripts/project_build -b -v localhost $DUMP_DIR/$MINE_NAME.$(date --iso-8601).dump
#ln -s $DUMP_DIR/$DB_NAME.$date.dump.final $DUMP_DIR/latest.dump
