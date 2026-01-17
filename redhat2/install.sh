#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./resources/config.sh
. ./resources/colors.sh

#update to latest packages
verbose "Update installed packages"
dnf -y update

#install dependencies
dnf -y install dnf-plugins-core epel-release
dnf -y install chrony curl wget net-tools htop vim openssl ca-certificates dialog

#enable remi repository for PHP packages
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

#SNMP
dnf -y install net-snmp net-snmp-utils
echo "rocommunity public" > /etc/snmp/snmpd.conf
systemctl enable --now snmpd

#disable vi visual mode
echo "set mouse-=a" >> ~/.vimrc

#Disable SELinux
resources/selinux.sh

#FusionPBX
resources/fusionpbx.sh

#Postgres
resources/postgresql.sh

#NGINX web server
resources/sslcert.sh
resources/nginx.sh

#PHP
resources/php.sh

#Firewalld
resources/firewalld.sh

#FreeSWITCH
resources/switch.sh

#Fail2ban
resources/fail2ban.sh

#add the database schema, user and groups
resources/finish.sh
