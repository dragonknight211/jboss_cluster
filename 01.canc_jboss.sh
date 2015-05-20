#!/bin/bash
#
# 01.canc_jboss.sh
#
# Control the whole process of installing a Jboss server running HelloWorld app
CUR_DIR=$(pwd)

# Execute alter_java to set up java
$CUR_DIR/alter_java.sh install 7u76

# Execute setup_jboss to download, install and run jboss
$CUR_DIR/setup_jboss.sh

SERVER_IP=`ifconfig eth1 | awk '/inet addr/{print substr($2,6)}'`
echo "Server ready and is running JBoss-AS with IP $SERVER_IP"
