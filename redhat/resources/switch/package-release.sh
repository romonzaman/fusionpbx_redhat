#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ../config.sh
. ../colors.sh

#send a message
verbose "Installing FreeSWITCH"

#install dependencies
dnf -y install memcached curl gdb

#install freeswitch packages
#dnf install -y https://files.freeswitch.org/repo/yum/el8-release/freeswitch-release-repo-0-1.noarch.rpm epel-release
echo "signalwire" > /etc/yum/vars/signalwireusername
echo 'please get your token from this site: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Installation/HOWTO-Create-a-SignalWire-Personal-Access-Token_67240087/#attachments'
echo "please enter your token:" 
read token
echo $token > /etc/yum/vars/signalwiretoken
repo_base="https://$(< /etc/yum/vars/signalwireusername):$(< /etc/yum/vars/signalwiretoken)@freeswitch.signalwire.com/repo/yum"
dnf -y install "$repo_base/el8-release/freeswitch-release-repo-0-1.noarch.rpm" epel-release || \
	dnf -y install "$repo_base/centos-release/freeswitch-release-repo-0-1.noarch.rpm" epel-release
dnf -y install freeswitch-config-vanilla freeswitch-lang-* freeswitch-sounds-* freeswitch-lua freeswitch-xml-cdr

#remove the music package to protect music on hold from package updates
mkdir -p /usr/share/freeswitch/sounds/temp
mv /usr/share/freeswitch/sounds/music/*000 /usr/share/freeswitch/sounds/temp
dnf -y remove freeswitch-sounds-music
mkdir -p /usr/share/freeswitch/sounds/music/default
mv /usr/share/freeswitch/sounds/temp/* /usr/share/freeswitch/sounds/music/default
rm -R /usr/share/freeswitch/sounds/temp

#send a message
verbose "FreeSWITCH installed"
