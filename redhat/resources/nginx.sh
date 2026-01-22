#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./config.sh
. ./colors.sh

#send a message
verbose "Installing the web server"

#create www-data user/group if needed
if ! getent group www-data >/dev/null 2>&1; then
  groupadd -r www-data
fi
if ! id -u www-data >/dev/null 2>&1; then
  useradd -r -g www-data -d /usr/share/nginx -s /sbin/nologin www-data
fi

#install dependencies
dnf -y install nginx

#setup nginx
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

#enable fusionpbx nginx config
cp ./nginx/fusionpbx /etc/nginx/sites-available/fusionpbx.conf
ln -s /etc/nginx/sites-available/fusionpbx.conf /etc/nginx/sites-enabled/fusionpbx.conf
awk '/server *{/ {c=1 ; next} c && /{/{c++} c && /}/{c--;next} !c' /etc/nginx/nginx.conf > /etc/nginx/nginx.tmp && mv -f /etc/nginx/nginx.tmp /etc/nginx/nginx.conf && rm -f /etc/nginx/nginx.tmp
sed -i '/include \/etc\/nginx\/conf\.d\/\*\.conf\;/a \    include \/etc\/nginx\/sites-enabled\/\*\.conf\;' /etc/nginx/nginx.conf

#set the log permissions
chmod -R 664 /var/log/nginx/

#send a message
verbose "nginx installed"
