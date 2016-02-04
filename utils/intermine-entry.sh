#!/bin/bash

# set user / password from ENV
sed -i "s/TOMCAT_USER/$TOMCAT_USER/g" /opt/apache-tomcat-8.0.30/conf/tomcat_users.xml
sed -i "s/TOMCAT_PWD/$TOMCAT_PWD/g" /opt/apache-tomcat-8.0.30/conf/tomcat_users.xml

# launch catalina
/opt/apache-tomcat-8.0.30/bin/catalina.sh run

