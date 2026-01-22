#!/bin/sh

#update the packages
dnf -y update

#install packages
dnf -y install git redhat-lsb-core

#get the install script
cd /usr/src && git clone https://github.com/fusionpbx/fusionpbx-install.sh.git

#change the working directory
cd /usr/src/fusionpbx-install.sh/redhat2
