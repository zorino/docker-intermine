#!/bin/bash

# datamine=$1

# set user / password from ENV for tomcat
sed -i "s/TOMCAT_USER/$TOMCAT_USER/g" /opt/tomcat/conf/tomcat-users.xml
sed -i "s/TOMCAT_PWD/$TOMCAT_PWD/g" /opt/tomcat/conf/tomcat-users.xml


if [ -d /data/intermine/$DB_NAME ]
then

    echo "Found $DB_NAME directory.."
    echo "Checking the setup of $DB_NAME instance.."
    if [ -d /data/intermine-psql-dump ]
    then
	cd /data/intermine-psql-dump/
	if [ -f ./latest.dump ]
	then
	    echo "Restauring postgres dump.."
	    pg_restore ./latest.dump
	fi
    fi
    
    # build the webapp
    echo "Building the webapp.."
    cd /data/intermine/$DB_NAME
    cd webapp/
    ant build-db-userprofile
    ant default remove-webapp release-webapp

else
    echo "/data/intermine/$DB_NAME not found !!"
    echo "Bootstraping Malariane demo.."
    /opt/utils/bootstrap-intermine-demo.sh
fi

