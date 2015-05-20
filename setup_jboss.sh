#!/bin/bash
#
# setup_jboss.sh
#
# Download and extract JBoss, config it to listen on all IP address and set Jboss to be daemon and auto start with machine

DOWNLOAD_LINK="http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.tar.gz";
TARGET_DIR="/opt";
JBOSS_HOME="$TARGET_DIR/Jboss"
# Check if the script is ran as root
if [ `id -u` -ne 0 ]; then
    # Not the root
    echo "Please make sure this script is ran as root!";
    exit 1;
fi

# Create JBOSS_HOME directory and cd there to prepare
mkdir -p $JBOSS_HOME;
cd $TARGET_DIR;

# Download and extract Jboss
wget $DOWNLOAD_LINK;
jboss_tar_file=${DOWNLOAD_LINK##*/};
echo "Extracting $jboss_tar_file";
tar xzvf $jboss_tar_file -C $JBOSS_HOME --strip=1
chown -R vagrant:vagrant $JBOSS_HOME;

# Modify standalone profile to listen on all IP addresses
sed -iE "s/<inet-.*127.*/<any-ipv4-address\/>/" "$JBOSS_HOME/standalone/configuration/standalone.xml"

# Change ajp port to 9091
new_port=9091;
sed -ie "s/\(.*ajp\" port=\"\)[0-9]*\(\"\/\)/\1$new_port\2/" "$JBOSS_HOME/standalone/configuration/standalone.xml"

# change content of index in sample .war so we can know what server is this
# Get current IP address of server
SERVER_IP=`ifconfig eth1 | awk '/inet addr/{print substr($2,6)}'`;


cd /tmp/
wget --no-check-certificate https://tomcat.apache.org/tomcat-6.0-doc/appdev/sample/sample.war
jar xvf sample.war
rm sample.war
sed -ie "/img.*/a This is server $SERVER_IP" index.html
jar cvf sample.war *
cp sample.war $JBOSS_HOME/standalone/deployments/
cd $JBOSS_HOME

# Make JBoss a Daemon and set it to automatically startic
ln -s $JBOSS_HOME/bin/init.d/jboss-as-standalone.sh /etc/init.d/jboss
chmod +x /etc/init.d/jboss
# chkconfig --level 356 jboss on

# Configuration dir for JBOSS
mkdir /etc/jboss-as
echo -e "JBOSS_HOME=$JBOSS_HOME" > /etc/jboss-as/jboss-as.conf
echo "JBOSS_CONSOLE_LOG=/var/log/jboss-console.log" >> /etc/jboss-as/jboss-as.conf
echo "JBOSS_USER=root" >> /etc/jboss-as/jboss-as.conf

# Download a simple Helloworld to deply to Jboss
cd "$JBOSS_HOME/standalone/deployments/";

# Download ClusterWebApp
wget http://github.com/jaysensharma/MiddlewareMagicDemos/blob/master/ClusterTest_WebApp/ClusterWebApp.war
chown vagrant:vagrant *

# Start JBoss
#service jboss start
