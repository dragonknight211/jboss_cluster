#!/bin/bash
# centos_lamp.sh
#
# install LAMP packages on CentOS 6.5

# Check if the script is ran as root
if [ `id -u` -ne 0 ]; then
    # Not the root
    echo "Please make sure this script is ran as root!";
    exit 1;
fi

#
# Check if the selected service is installed and install if not
#
function check_install ()
{
    service_name=$1;

    # Select pakages name for selected service
    package_names=""; # Name of the packages to install, modify the next switch block if you want to use this script in other distro
    restart_lamp=0;     # Mark if we need to restart Apache and Mysql after installation this is used for any modules that require those restart
    case "$service_name" in
        mysql)
            package_names="mysql mysql-server";
            ;;
        httpd)
            package_names="httpd";
            ;;
        php)
            package_names="php php-gd php-imap php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel";
            ;;
        phpmyadmin)
            package_names="phpmyadmin";
            ;;
        *)
            echo " Service $service_name is not supported by this script";

            exit 1;
            ;;
    esac

    # check if selected service is installed
    install_status=`which $service_name 2> /dev/null | wc -l`;
    if [ $install_status == 0 ]; then

        echo "$service_name is not installed. Trying to install now";

        yum -y install $package_names;

        # Set mysql to auto start on run level 2, 5, 6
        chkconfig --levels 235 $service_name on

        # Start the service
        service $service_name start;

        # Restart LAMP if need to
        if [ $restart_lamp == 1 ]; then
            service httpd restart
            service mysql restart
        fi

        echo "  Done";
    else
        echo "$service_name is ALREADY INSTALLED";
    fi
}

# Install Mysql
check_install "mysql";

# Install apache web server
check_install "httpd";
# Disable defautl Apache welcome site
default_file="/etc/httpd/conf.d/welcome.conf";
if [ -f $default_file ]; then
    mv $default_file "$default_file.disabled";
fi

# Install PHP5
check_install "php";