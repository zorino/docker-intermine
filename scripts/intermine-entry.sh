#!/bin/bash
set -e

[ -z "$MINE_NAME" ] && {
  echo "[Intermine-script] MINE_NAME environment variable missing. Exiting.."
  exit 1
}
MINE_DIR="/intermine/${MINE_NAME}"
if [ -d "${MINE_DIR}" ]; then

  echo "[Intermine-script] Found ${MINE_NAME} directory.."

  PSQL="psql -U postgres -h postgres -p 5432"
  wait_for_pg() {
    echo -n "[Intermine-script] Waiting for postgres to be ready.."
    until $PSQL -v ON_ERROR_STOP=1 -c "select version()" &> /dev/null; do
      echo -n "."
      sleep 2
    done
    echo
    sleep 3
  }

  # check for properties file
  CONF_DIR="/root/.intermine"
  DEFAULT_CONF_FILE="${CONF_DIR}/default.properties"
  CONF_FILE="${CONF_DIR}/${MINE_NAME}.properties"
  if [ ! -f "$CONF_FILE" ]; then
    echo "[Intermine-script] Preparing configuration files.."

    # set user / password and port from ENV for tomcat
    sed -i "s/TOMCAT_USER/${TOMCAT_USER}/g" /opt/tomcat/conf/tomcat-users.xml
    sed -i "s/TOMCAT_PWD/${TOMCAT_PWD}/g" /opt/tomcat/conf/tomcat-users.xml
    sed -i "s/TOMCAT_PORT/${TOMCAT_PORT}/g" /opt/tomcat/conf/server.xml

    cp ${DEFAULT_CONF_FILE} ${CONF_FILE}
    #sed -i "s/=localhost/=${PSQL_HOST}/g" ${CONF_FILE}
    sed -i "s/PSQL_HOST/${PSQL_HOST}/g" ${CONF_DIR}/intermine-bio-test.properties
    sed -i "s/PSQL_HOST/${PSQL_HOST}/g" ${CONF_FILE}
    sed -i "s/MINE_NAME/${MINE_NAME}/g" ${CONF_FILE}
    sed -i "s/PSQL_USER/${PSQL_USER}/g" ${CONF_FILE}
    sed -i "s/PSQL_PWD/${PSQL_PWD}/g" ${CONF_FILE}
    sed -i "s/PSQL_DB_ITEMS/${PSQL_DB_ITEMS}/g" ${CONF_FILE}
    sed -i "s/PSQL_DB_USER/${PSQL_DB_USER}/g" ${CONF_FILE}
    sed -i "s/PSQL_DB/${PSQL_DB}/g" ${CONF_FILE}
    sed -i "s/TOMCAT_USER/${TOMCAT_USER}/g" ${CONF_FILE}
    sed -i "s/TOMCAT_PWD/${TOMCAT_PWD}/g" ${CONF_FILE}
    sed -i "s/TOMCAT_PORT/${TOMCAT_PORT}/g" ${CONF_FILE}
  fi

  # Wait for postgres
  wait_for_pg

  # Check if user & databases exist else create them
  echo "[Intermine-script] Looking for Postgres User and Databases.."
  USER_EXIST=$($PSQL -tAc "SELECT 1 FROM pg_roles WHERE rolname='${PSQL_USER}'")
  if [[ $USER_EXIST == '' ]]; then
    echo "[Intermine-script] Creating postgres User ${PSQL_USER}.."
    # create user
    $PSQL -c "CREATE USER ${PSQL_USER} WITH PASSWORD '${PSQL_PWD}';"
    $PSQL -c "ALTER USER ${PSQL_USER} WITH SUPERUSER;"

    echo "[Intermine-script] Creating postgres DB for ${MINE_NAME}.."
    # create table
    $PSQL -c "CREATE DATABASE \"${PSQL_DB}\";"
    $PSQL -c "CREATE DATABASE \"${PSQL_DB_ITEMS}\";"
    $PSQL -c "CREATE DATABASE \"${PSQL_DB_USER}\";"

    $PSQL -c "CREATE DATABASE \"bio-fulldata-test\";"
    $PSQL -c "CREATE DATABASE \"bio-test\";"

    $PSQL -c "GRANT ALL PRIVILEGES ON DATABASE \"${PSQL_DB}\" to ${PSQL_USER};"
    $PSQL -c "GRANT ALL PRIVILEGES ON DATABASE \"${PSQL_DB_ITEMS}\" to ${PSQL_USER};"
    $PSQL -c "GRANT ALL PRIVILEGES ON DATABASE \"${PSQL_DB_USER}\" to ${PSQL_USER};"

    $PSQL -c "GRANT ALL PRIVILEGES ON DATABASE \"bio-fulldata-test\" to ${PSQL_USER};"
    $PSQL -c "GRANT ALL PRIVILEGES ON DATABASE \"bio-test\" to ${PSQL_USER};"

    echo "[Intermine-script] Building base intermine dbmodel.."
    ant -f /intermine/bio/test-all/dbmodel/build.xml clean build-db
    ant -f /intermine/bio/test-all/dbmodel/build.xml clean default
  fi

  # check for dump and restore the latest version
  if [ -d /data/intermine-psql-dump ]
  then
	  # build dbmodel
	  echo "[Intermine-script] Building DB model.."
	  cd ${MINE_DIR}/dbmodel
	  ant clean build-db
	  # Build db profiles
	  echo "[Intermine-script] Building DB user-profiles.."
	  cd ${MINE_DIR}/webapp
	  ant build-db-userprofile

	  cd /data/intermine-psql-dump/
	  [ -f ./latest.dump ] && {
	    echo "[Intermine-script] Restauring postgres dump.."
	    pg_restore -U postgres -h postgres -p 5432 -j 2 -d ${PSQL_DB} ./latest.dump
	  }
  fi
else
  echo "[Intermine-script] ERROR ${MINE_DIR} not found !!"
  echo "Please check README for more info on how to setup intemine"
  exit 1
fi

# launch catalina
/opt/tomcat/bin/catalina.sh run
