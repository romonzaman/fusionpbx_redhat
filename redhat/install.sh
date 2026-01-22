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
dnf -y install chrony curl wget net-tools htop vim openssl ca-certificates dialog nano mlocate git gcc make

#enable remi repository for PHP packages
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

#SNMP
dnf -y install net-snmp net-snmp-utils
echo "rocommunity public" > /etc/snmp/snmpd.conf
systemctl enable --now snmpd

#disable vi visual mode
echo "set mouse-=a" >> ~/.vimrc

#Disable SELinux
# resources/selinux.sh
verbose "Disabling SELinux"
warning "Reboot required after installation completes"
setenforce 0
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config
verbose "SELinux disabled"

useradd -r \
  -g daemon \
  -d /var/lib/freeswitch \
  -s /sbin/nologin \
  -c "FreeSWITCH daemon user" \
  freeswitch

#FusionPBX
# resources/fusionpbx.sh
verbose "Installing FusionPBX"

#install dependencies
dnf -y install git ghostscript libtiff-devel libtiff libtiff-devel at

#forensics tools
#wget https://forensics.cert.org/cert-forensics-tools-release-el8.rpm
#rpm -Uvh cert-forensics-tools-release*rpm
#dnf -y --enablerepo=forensics install lame

cwd=$(pwd)

cd /usr/src
wget https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
tar xvf lame-3.100.tar.gz
cd lame-3.100
./configure
make
make install

cd $cwd

#add the cache directory
mkdir -p /var/cache/fusionpbx
chown -R www-data:www-data /var/cache/fusionpbx

#get the source code
git clone -b 5.4 https://github.com/fusionpbx/fusionpbx.git /var/www/fusionpbx

#send a message
verbose "FusionPBX Installed"


#Postgres
#resources/postgresql.sh
password=${database_password}
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -y module disable postgresql
sudo dnf install -y postgresql14-server postgresql14-contrib postgresql14 postgresql14-libs

sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
sudo systemctl enable postgresql-14
sudo systemctl start postgresql-14

sed -i 's/\(host  *all  *all  *127.0.0.1\/32  *\)ident/\1md5/' /var/lib/pgsql/14/data/pg_hba.conf
sed -i 's/\(host  *all  *all  *::1\/128  *\)ident/\1md5/' /var/lib/pgsql/14/data/pg_hba.conf

systemctl daemon-reload
systemctl restart postgresql-14

cwd=$(pwd)
cd /tmp

#add the databases, users and grant permissions to them
sudo -u postgres /usr/bin/psql -d fusionpbx -c "DROP SCHEMA public cascade;";
sudo -u postgres /usr/bin/psql -d fusionpbx -c "CREATE SCHEMA public;";
sudo -u postgres /usr/bin/psql -c "CREATE DATABASE fusionpbx";
sudo -u postgres /usr/bin/psql -c "CREATE DATABASE freeswitch";
sudo -u postgres /usr/bin/psql -c "CREATE ROLE fusionpbx WITH SUPERUSER LOGIN PASSWORD '$password';"
sudo -u postgres /usr/bin/psql -c "CREATE ROLE freeswitch WITH SUPERUSER LOGIN PASSWORD '$password';"
sudo -u postgres /usr/bin/psql -c "GRANT ALL PRIVILEGES ON DATABASE fusionpbx to fusionpbx;"
sudo -u postgres /usr/bin/psql -c "GRANT ALL PRIVILEGES ON DATABASE freeswitch to fusionpbx;"
sudo -u postgres /usr/bin/psql -c "GRANT ALL PRIVILEGES ON DATABASE freeswitch to freeswitch;"
#ALTER USER fusionpbx WITH PASSWORD 'newpassword';
cd $cwd


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
