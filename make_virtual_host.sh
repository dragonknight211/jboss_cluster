#!/bin/bash

# make_virtual_host.sh
#
# Make a virtual host for the selected user and set up policy according to homework problem
#

site_name="tan.internavi.tk"; # Name of the selected site, also the URL to access it
HOME_DIR="/tmp/$site_name";
VIRTUAL_HOST_CONFIG_DIR="/etc/httpd/conf.d";
#VIRTUAL_HOST_CONFIG_DIR="/home/vagrant";

# Check to make sure this script is run as root
if [ `id -u` != 0 ]; then
    echo "Make sure this script is run as root";
    exit 1;
fi

# Create the home directory for the site if need to 
if [ ! -d $HOME_DIR ]; then
    mkdir -p $HOME_DIR;
fi

# Get current IP address of server
SERVER_IP=`ifconfig eth1 | awk '/inet addr/{print substr($2,6)}'`;

echo " Index file of $site_name running on server $SERVER_IP, this file is in $HOME_DIR, created on `date`" > $HOME_DIR/index.html


# Set this site into hosts file if not already
host_file_status=`grep $site_name /etc/hosts | wc -l`;
if [ $host_file_status == 0 ]; then
    echo -n "127.0.0.1\t$site_name" >> /etc/hosts
fi

# Make the virtualhost file to apache
# Config this virtualhost to use backend server by mod_proxy
virtual_host_file="$VIRTUAL_HOST_CONFIG_DIR/$site_name.conf";
touch $virtual_host_file;
echo "<Proxy balancer://mycluster>"		> $virtual_host_file;
echo "Order deny,allow"					>> $virtual_host_file;
echo "Allow from all"					>> $virtual_host_file;
echo "BalancerMember http://192.168.44.21:8080/sample route=node1"  	>> $virtual_host_file;
echo "BalancerMember http://192.168.44.22:8080/sample route=node2"		>> $virtual_host_file;
echo "ProxySet stickysession=ROUTEID"		>> $virtual_host_file;
echo "</Proxy>"							>> $virtual_host_file;

echo "<Proxy balancer://mycluster_2>"	>> $virtual_host_file;
echo "Order deny,allow"					>> $virtual_host_file;
echo "Allow from all"					>> $virtual_host_file;
echo "BalancerMember http://192.168.44.21:8080/check route=node1"  	>> $virtual_host_file;
echo "BalancerMember http://192.168.44.22:8080/check route=node2"		>> $virtual_host_file;
echo "ProxySet stickysession=ROUTEID"		>> $virtual_host_file;
echo "</Proxy>"							>> $virtual_host_file;

echo "<VirtualHost *:80>"               >> $virtual_host_file;
echo -e "\tServerName\t$site_name"      >> $virtual_host_file;
echo -e "\tDocumentRoot\t$HOME_DIR/"    >> $virtual_host_file;
echo -e "\tHeader add Set-Cookie \"ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/\" env=BALANCER_ROUTE_CHANGED"    >> $virtual_host_file;

echo -e "\t<Directory \"$HOME_DIR/\">"  >> $virtual_host_file;
echo -e "\t\tAllowOverride All"         >> $virtual_host_file;
echo -e "\t</Directory>"                >> $virtual_host_file;
echo "ProxyPreserveHost On"             >> $virtual_host_file;

echo "ProxyPass /sample balancer://mycluster">> $virtual_host_file;
echo "ProxyPass /check balancer://mycluster_2">> $virtual_host_file;
echo "</VirtualHost>"                   >> $virtual_host_file;

# Restart httpd to load new settings
service httpd restart

# A little notification
echo -e " Web server running on $SERVER_IP, \n Please change your hosts file to point $site_name to $SERVER_IP";
