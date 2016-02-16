#!/bin/bash

date=`date --iso-8601`

# set user / password and port from ENV for tomcat
sed -i "s/TOMCAT_USER/$TOMCAT_USER/g" /opt/tomcat/conf/tomcat-users.xml
sed -i "s/TOMCAT_PWD/$TOMCAT_PWD/g" /opt/tomcat/conf/tomcat-users.xml
sed -i "s/TOMCAT_PORT/$TOMCAT_PORT/g" /opt/tomcat/conf/server.xml


# starting catalina for the project
echo "[Intermine-script] Starting tomcat to create the webapp.."
/opt/tomcat/bin/catalina.sh start
sleep 5

if [ -d /data/intermine/$DB_NAME ]
then
    echo "[Intermine-script] Found $DB_NAME directory.."
    echo "[Intermine-script] Checking the setup of $DB_NAME instance.."

    # check for properties file - FIX
    if [ -e /data/.intermine/$DB_NAME.properties ]
    then
	cd /root/
	rm .intermine
	ln -s /data/.intermine .
	sed -i "s/=localhost/=$PSQL_HOST/g" .intermine/$DB_NAME.properties
	sed -i "s/PSQL_USER/$PSQL_USER/g" .intermine/$DB_NAME.properties
	sed -i "s/PSQL_PWD/$PSQL_PWD/g" .intermine/$DB_NAME.properties
	sed -i "s/TOMCAT_USER/$TOMCAT_USER/g" .intermine/$DB_NAME.properties
	sed -i "s/TOMCAT_PWD/$TOMCAT_PWD/g" .intermine/$DB_NAME.properties
	sed -i "s/TOMCAT_PORT/$TOMCAT_PORT/g" .intermine/$DB_NAME.properties
	cd /data
    else
	echo "[Intermine-script] ERROR : didn't find /data/.intermine dir + properties file"
	exit
    fi

    # check for postgres user and db
    echo "[Intermine-script] Looking for Postgres User and Databases.."
    user_exist=`psql -U postgres -h postgres -p 5432 -tAc "SELECT 1 FROM pg_roles WHERE rolname='$PSQL_USER'"`
    if [[ $user_exist != '1' ]]
    then
	echo "[Intermine-script] Postgres User $PSQL_USER doesn't exist, creating it.."
	# create user
	psql -U postgres -h postgres -p 5432 -c "CREATE USER $PSQL_USER WITH PASSWORD '$PSQL_PWD';"
	psql -U postgres -h postgres -p 5432 -c "ALTER USER $PSQL_USER WITH SUPERUSER;"
    fi

    table_exist=`psql  -U postgres -h postgres -p 5432 -lqt | cut -d \| -f 1 | grep -w $DB_NAME`
    if [[ $table_exist == '' ]]
    then
	echo "[Intermine-script] Postgres DB for $DB_NAME doesn't exist, creating them.."
	# create table
	psql -U postgres -h postgres -p 5432 -c "CREATE DATABASE \"$PSQL_DB_NAME\";"
	psql -U postgres -h postgres -p 5432 -c "CREATE DATABASE \"items-$PSQL_DB_NAME\";"
	psql -U postgres -h postgres -p 5432 -c "CREATE DATABASE \"userprofile-$PSQL_DB_NAME\";"
	psql -U postgres -h postgres -p 5432 -c "GRANT ALL PRIVILEGES ON DATABASE \"$PSQL_DB_NAME\" to $PSQL_USER;"
	psql -U postgres -h postgres -p 5432 -c "GRANT ALL PRIVILEGES ON DATABASE \"items-$PSQL_DB_NAME\" to $PSQL_USER;"
	psql -U postgres -h postgres -p 5432 -c "GRANT ALL PRIVILEGES ON DATABASE \"userprofile-$PSQL_DB_NAME\" to $PSQL_USER;"
    fi


    # check for dump and restore the latest version
    if [ -d /data/intermine-psql-dump ]
    then

	# build dbmodel
	echo "[Intermine-script] Building DB model.."
	cd /data/intermine/$DB_NAME/dbmodel
	ant clean build-db
	# Build db profiles
	echo "[Intermine-script] Building DB user-profiles.."
	cd /data/intermine/$DB_NAME/webapp
	ant build-db-userprofile

	cd /data/intermine-psql-dump/
	if [ -f ./latest.dump ]
	then
	    echo "[Intermine-script] Restauring postgres dump.."
	    pg_restore -U postgres -h postgres -p 5432 -j 2 -d $PSQL_DB_NAME ./latest.dump
	fi

    else

	# should try to create db model & all
	# build malariamine
	cd /data/intermine/$DB_NAME/dbmodel
	ant clean build-db

	# # integrate other stuff
	# cd ../integrate
	# ant -Dsource=uniprot-malaria -v
	# ant -Dsource=malaria-gff -v
	# ant -Dsource=malaria-chromosome-fasta -v
	# ant -v -Dsource=entrez-organism
	# ant -v -Dsource=update-publications
	# cd ../postprocess
	# ant -v
	# cd ../webapp
	# ant build-db-userprofile
    fi


    # build the webapp
    echo "[Intermine-script] Building the webapp.."
    cd /data/intermine/$DB_NAME
    cd postprocess/
    ant -v
    cd ../webapp/
    ant default remove-webapp release-webapp

else
    echo "[Intermine-script] ERROR /data/intermine/$DB_NAME not found !!"
    echo "[Intermine-script] Bootstraping Malariane demo.."
    /opt/utils/bootstrap-intermine-demo.sh
fi

# stoping catalina
echo "[Intermine-script] rebooting tomcat.."
/opt/tomcat/bin/catalina.sh stop
sleep 12
