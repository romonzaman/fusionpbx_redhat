#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./config.sh
. ./colors.sh
#. ./environment.sh

#send a message
verbose "Install PHP and PHP-FPM"

#install module tools
dnf -y install dnf-plugins-core

#enable the remi php stream
dnf -y module reset php
case "$php_version" in
	8.4|8.3|8.2|8.1|8.0|7.4)
		dnf -y module enable php:remi-$php_version
		;;
	*)
		php_version=8.2
		dnf -y module enable php:remi-8.2
		;;
esac

#install dependencies
dnf -y install php php-cli php-fpm php-pgsql php-gd php-xml php-mbstring php-opcache php-ldap php-odbc php-snmp php-imap php-soap php-process php-common php-curl

#send a message
verbose "Configuring php/nginx/php-fpm and permissions"

#get the timezone
TIMEZ=$(timedatectl | grep 'Time zone' | awk '{ print $3 }')

#update the php configuration
php_ini_file='/etc/php.ini'
sed -ie "s#;date.timezone =#date.timezone = $TIMEZ#g" $php_ini_file
sed -ie 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' $php_ini_file
sed -ie 's|listen = 127.0.0.1:9000|listen = /run/php-fpm/www.sock|g' /etc/php-fpm.d/www.conf
sed -ie 's/;listen.owner = nobody/listen.owner = www-data/g' /etc/php-fpm.d/www.conf
sed -ie 's/;listen.group = nobody/listen.group = www-data/g' /etc/php-fpm.d/www.conf
sed -ie 's/user = www-data/user = www-data/g' /etc/php-fpm.d/www.conf
sed -ie 's/group = www-data/group = www-data/g' /etc/php-fpm.d/www.conf
sed -ie 's/listen.acl_users/;listen.acl_users/g' /etc/php-fpm.d/www.conf

#make the session directory
mkdir -p /var/lib/php/session

#update permissions
chmod -Rf 770 /var/lib/php/session

#update the permissions
if [ -d /var/www/fusionpbx ]; then
	find /var/www/fusionpbx -type d -exec chmod 770 {} \;
	find /var/www/fusionpbx -type f -exec chmod 664 {} \;
fi

#install ioncube
#if [ .$cpu_architecture = .'x86' ]; then
#	. ./ioncube.sh
#fi

#restart php-fpm
systemctl daemon-reload
systemctl restart php-fpm

#send a message
verbose "php/nginx/php-fpm and permissions configured"
