#!/bin/bash
#
# setup_jboss.sh
#
# Download and extract JBoss, config it to listen on all IP address and set Jboss to be daemon and auto start with machine
CUR_DIR=$(pwd)
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

# Copy clusterwebapp to deployments
cp $CUR_DIR/ClusterWebApp.war $JBOSS_HOME/standalone/deployments/

chown -R vagrant:vagrant $JBOSS_HOME

last_ip=`echo "${SERVER_IP: -2}"`
node_name="node$last_ip"

CLUTER_BROADCAST="230.0.0.4"
# Start JBoss
$JBOSS_HOME/bin/standalone.sh -c standalone-ha.xml -b 0.0.0.0 -Djboss.node.name=$node_name -u $CLUTER_BROADCAST
