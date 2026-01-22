#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ../config.sh
. ../colors.sh

#upgrade packages (RHEL 8.x)
dnf -y update

dnf -y install memcached curl gdb git wget

#install build dependencies
dnf -y install autoconf automake libtool gcc-c++ ncurses-devel zlib-devel \
libjpeg-turbo-devel openssl-devel libcurl-devel pcre-devel libuuid-devel libogg-devel curl-devel

#dnf -y install lua-devel libedit-devel speex-devel libvorbis-devel\
#libogg-devel ldns-devel libsndfile-devel libtheora-devel

#install additional dependencies
dnf -y install libjpeg-turbo-devel sqlite-devel libpng-devel libtiff-devel \
libX11-devel e2fsprogs-devel openldap-devel libyuv-devel
dnf -y install sox sqlite unzip

#we are about to move out of the executing directory so we need to preserve it to return after we are done
CWD=$(pwd)

#install the following dependencies if the switch version is greater than 1.10.0
if [ $(echo "$switch_version" | tr -d '.') -gt 1100 ]; then

	# libks build-requirements
	dnf -y install cmake libuuid-devel libatomic

	# libks
	cd /usr/src
	git clone https://github.com/signalwire/libks.git libks
	cd libks
	cmake .
	make -j $(getconf _NPROCESSORS_ONLN)
	make install

	# libks C includes
	export C_INCLUDE_PATH=/usr/include/libks

	# sofia-sip
	cd /usr/src
	#git clone https://github.com/freeswitch/sofia-sip.git sofia-sip
	wget https://github.com/freeswitch/sofia-sip/archive/refs/tags/v$sofia_version.zip
	unzip v$sofia_version.zip
	cd sofia-sip-$sofia_version
	sh autogen.sh
	./configure --enable-debug
	make -j $(getconf _NPROCESSORS_ONLN)
	make install

	# spandsp
	cd /usr/src
	git clone https://github.com/freeswitch/spandsp.git spandsp
	cd spandsp
 	git reset --hard 0d2e6ac65e0e8f53d652665a743015a88bf048d4
 	#/usr/bin/sed -i 's/AC_PREREQ(\[2\.71\])/AC_PREREQ([2.69])/g' /usr/src/spandsp/configure.ac
	sh autogen.sh
	./configure --enable-debug
	make -j $(getconf _NPROCESSORS_ONLN)
	make install
	ldconfig
fi

cd /usr/src

#check for master
if [ $switch_branch = "master" ]; then
	#master branch
	echo "Using version master"
	rm -r /usr/src/freeswitch
	git clone https://github.com/signalwire/freeswitch.git
	cd /usr/src/freeswitch
	./bootstrap.sh -j
fi

#check for stable release
if [ $switch_branch = "stable" ]; then
	echo "Using version $switch_version"
	#1.8 and older
	if [ $(echo "$switch_version" | tr -d '.') -lt 1100 ]; then
		wget http://files.freeswitch.org/freeswitch-releases/freeswitch-$switch_version.zip
		unzip freeswitch-$switch_version.zip
		cd /usr/src/freeswitch-$switch_version
	fi

	#1.10.0 and newer
	if [ $(echo "$switch_version" | tr -d '.') -gt 1100 ]; then
		wget http://files.freeswitch.org/freeswitch-releases/freeswitch-$switch_version.-release.zip
		unzip freeswitch-$switch_version.-release.zip
		mv freeswitch-$switch_version.-release freeswitch-$switch_version
		cd /usr/src/freeswitch-$switch_version
		#apply patch
		#patch -u /usr/src/freeswitch/src/mod/databases/mod_pgsql/mod_pgsql.c -i /usr/src/fusionpbx-install.sh/debian/resources/switch/source/mod_pgsql.patch
	fi
	dnf config-manager --set-enabled powertools
	dnf -y install epel-release
	dnf -y makecache
	dnf -y 	install speex-devel speexdsp-devel libedit-devel nasm 
	#dnf -y install ffmpeg-devel
	dnf config-manager --set-enabled powertools
	dnf -y install lua-devel libpq-devel php-devel libmemcached-devel libshout-devel libsndfile-devel
	dnf -y install libmpg123-devel

fi

# enable required modules
#sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_avmd:applications/mod_avmd:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#applications/mod_av:formats/mod_av:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#applications/mod_callcenter:applications/mod_callcenter:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#applications/mod_cidlookup:applications/mod_cidlookup:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#applications/mod_memcache:applications/mod_memcache:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#applications/mod_nibblebill:applications/mod_nibblebill:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#applications/mod_curl:applications/mod_curl:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#applications/mod_translate:applications/mod_translate:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#formats/mod_shout:formats/mod_shout:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#formats/mod_pgsql:formats/mod_pgsql:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#say/mod_say_es:say/mod_say_es:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'#say/mod_say_fr:say/mod_say_fr:'

#disable module or install dependency libks to compile signalwire
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'applications/mod_signalwire:#applications/mod_signalwire:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'endpoints/mod_skinny:#endpoints/mod_skinny:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'endpoints/mod_verto:#endpoints/mod_verto:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'applications/mod_spandsp:#applications/mod_spandsp:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'applications/mod_enum:#applications/mod_enum:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'applications/mod_av:#formats/mod_av:'
sed -i /usr/src/freeswitch-$switch_version/modules.conf -e s:'codecs/mod_opus:#codecs/mod_opus:'

# prepare the build
#./configure --prefix=/usr/local/freeswitch --enable-core-pgsql-support --disable-fhs
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/pgsql-13/lib/pkgconfig
./configure -C --enable-portable-binary --disable-dependency-tracking --enable-debug \
--prefix=/usr --localstatedir=/var --sysconfdir=/etc \
--with-openssl --enable-core-pgsql-support

# compile and install
make -j $(getconf _NPROCESSORS_ONLN)
make install

#return to the executing directory
cd $CWD
