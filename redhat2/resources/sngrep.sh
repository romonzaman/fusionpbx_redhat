#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

IRONTEC="[irontec]
name=Irontec RPMs repository
baseurl=https://packages.irontec.com/centos/\$releasever/\$basearch/"
echo "${IRONTEC}" > /etc/yum.repos.d/irontec.repo
rpm --import https://packages.irontec.com/public.key
dnf -y install sngrep
