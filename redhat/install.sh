#!/bin/sh

# Red Hat Enterprise Linux 8.10 install

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./resources/config.sh
. ./resources/colors.sh

#ensure RHEL 8.x
if [ -f /etc/os-release ]; then
	. /etc/os-release
	if [ .$ID != .rhel ]; then
		error "This installer is for Red Hat Enterprise Linux"
		exit 3
	fi
	case "$VERSION_ID" in
		8.10) ;;
		8.*) warning "Tested on RHEL 8.10, continuing on $VERSION_ID" ;;
		*) error "Unsupported RHEL version $VERSION_ID"; exit 3 ;;
	esac
fi

# Update RHEL
verbose "Updating RHEL"
dnf -y upgrade --refresh

# enable repos when subscription-manager is available
if command -v subscription-manager >/dev/null 2>&1; then
	subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms || warning "Unable to enable CodeReady Builder repo"
fi

# Add additional repositories (EPEL, Remi)
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# Installing basic packages
dnf -y install chrony dnf-plugins-core net-tools htop vim openssl wget curl mlocate

# Add the freeswitch user
useradd -r -g daemon -d /var/lib/freeswitch -s /sbin/nologin -c "FreeSWITCH daemon user" freeswitch


# Disable SELinux
resources/selinux.sh

#FusionPBX
resources/fusionpbx.sh

#Postgres
resources/postgresql.sh

#NGINX web server
resources/sslcert.sh
resources/nginx.sh

#PHP/PHP-FPM
resources/php.sh

#Firewalld
resources/firewalld.sh

#FreeSWITCH
resources/switch.sh

#Fail2ban
resources/fail2ban.sh

#restart services
verbose "Restarting packages for final configuration"
systemctl daemon-reload
systemctl restart freeswitch
systemctl restart php-fpm
systemctl restart nginx
systemctl restart fail2ban

#add the database schema, user and groups
resources/finish.sh
