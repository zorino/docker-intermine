#!/bin/bash -x

LOG_FILE=/data/docker-intermine.log
[ -f "$LOG_FILE" ] && rm $LOG_FILE

prefix() {
  cat - | awk 'NF { printf "[%s] %s\n", "'$1'", $0; next } { print $0 }'
}

log() {
  echo $@ | prefix "Intermine-script" | tee /dev/stderr
}

PSQL="psql -U postgres -h postgres -p 5432"
wait_for_pg() {
  log "Waiting for postgres to be ready.."
  until $PSQL -v ON_ERROR_STOP=1 -c "select version()" &> /dev/null
    do sleep 2
  done
  sleep 3
}

main() {
  [ -z "$MINE_NAME" ] && {
    log "MINE_NAME environment variable missing. Exiting.."
    exit 1
  }
  MINE_DIR="/intermine/${MINE_NAME}"
  if [ -d "${MINE_DIR}" ]; then
    log "Found ${MINE_NAME} directory.."

    # check for properties file
    CONF_DIR="$HOME/.intermine"
    DEFAULT_CONF_FILE="${CONF_DIR}/default.properties"
    CONF_FILE="${CONF_DIR}/${MINE_NAME}.properties"
    if [ ! -f "$CONF_FILE" ]; then
      log "Preparing configuration files.."

      DB_HOST=$(echo $POSTGRES_NAME  | egrep -o '[a-zA-Z]+$')
      TOMCAT_PORT_NUM=$(echo $TOMCAT_PORT | egrep -o '[0-9]+$')
      TOMCAT_HOST=$(echo $TOMCAT_NAME | egrep -o '[a-zA-Z]+$')

      sed -i "s/DB_HOST/${DB_HOST}/g" ${CONF_DIR}/intermine-bio-test.properties
      sed -i "s/DB_USER/${DB_USER}/g" ${CONF_DIR}/intermine-bio-test.properties
      sed -i "s/DB_PWD/${DB_PWD}/g" ${CONF_DIR}/intermine-bio-test.properties
      sed -i "s/TOMCAT_HOST/${TOMCAT_HOST}/g" ${CONF_DIR}/intermine-bio-test.properties
      sed -i "s/TOMCAT_PORT/${TOMCAT_PORT_NUM}/g" ${CONF_DIR}/intermine-bio-test.properties

      cp ${DEFAULT_CONF_FILE} ${CONF_FILE}

      sed -i "s/DB_HOST/${DB_HOST}/g" ${CONF_FILE}
      sed -i "s/DB_USER/${DB_USER}/g" ${CONF_FILE}
      sed -i "s/DB_PWD/${DB_PWD}/g" ${CONF_FILE}

      sed -i "s/MINE_NAME/${MINE_NAME}/g" ${CONF_FILE}

      sed -i "s/DB_ITEMS/${DB_ITEMS}/g" ${CONF_FILE}
      sed -i "s/DB_PROFILE/${DB_PROFILE}/g" ${CONF_FILE}
      sed -i "s/DB_MAIN/${DB_MAIN}/g" ${CONF_FILE}

      sed -i "s/TOMCAT_HOST/${TOMCAT_HOST}/g" ${CONF_FILE}
      sed -i "s/TOMCAT_PORT/${TOMCAT_PORT_NUM}/g" ${CONF_FILE}

      sed -i "s/TOMCAT_USER/${TOMCAT_ENV_TOMCAT_USER}/g" ${CONF_FILE}
      sed -i "s/TOMCAT_PWD/${TOMCAT_ENV_TOMCAT_PWD}/g" ${CONF_FILE}
    fi

    # Wait for postgres
    wait_for_pg

    # Check if user & databases exist else create them
    USER_EXIST=$($PSQL -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'") || true
    if [[ $USER_EXIST == '' ]]; then
      log "Creating DB user '${DB_USER}'.."
      $PSQL -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PWD}';"
      $PSQL -c "ALTER USER ${DB_USER} WITH SUPERUSER;"

      log "Creating intermine databases.."
      $PSQL -c 'CREATE DATABASE "'${DB_MAIN}'";'
      $PSQL -c 'CREATE DATABASE "'${DB_ITEMS}'";'
      $PSQL -c 'CREATE DATABASE "'${DB_PROFILE}'";'

      $PSQL -c 'CREATE DATABASE "bio-fulldata-test";'
      $PSQL -c 'CREATE DATABASE "bio-test";'

      log "Granting access to databases.."
      $PSQL -c 'GRANT ALL PRIVILEGES ON DATABASE "'${DB_MAIN}'" to '${DB_USER}';'
      $PSQL -c 'GRANT ALL PRIVILEGES ON DATABASE "'${DB_ITEMS}'" to '${DB_USER}';'
      $PSQL -c 'GRANT ALL PRIVILEGES ON DATABASE "'${DB_PROFILE}'" to '${DB_USER}';'

      $PSQL -c 'GRANT ALL PRIVILEGES ON DATABASE "bio-fulldata-test" to '${DB_USER}';'
      $PSQL -c 'GRANT ALL PRIVILEGES ON DATABASE "bio-test" to '${DB_USER}';'

      log "Building intermine dbmodel.."
      ant -f /intermine/bio/test-all/dbmodel/build.xml -v clean build-db || return 1
      log "Running intermine tests.."
      ant -f /intermine/bio/test-all/dbmodel/build.xml -v clean default || return 1
    fi

    # check for dump and restore the latest version
    DUMP_DIR="/data/intermine-psql-dump"
    [ -f $DUMP_DIR/latest.dump ] && {
      log "Restoring postgres dump.."
      pg_restore -U postgres -h postgres -p 5432 -d ${DB_MAIN} $DUMP_DIR/latest.dump || return 1
    }

    log "Done."
  else
    log "Error: ${MINE_DIR} not found !!"
    log "Please check README.md for more info on how to setup intemine"
    exit 1
  fi
}

main > $LOG_FILE ||
  # Print last 50 lines of logs if error occured
  tail -n 50 $LOG_FILE | prefix ERROR_LOG

# Keep container running
tail -f /dev/null
