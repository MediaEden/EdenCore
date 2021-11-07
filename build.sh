#!/bin/bash -e

# Vars
SUDO=""
PREFIX=/opt/EdenCore
TEMP_PATH=/tmp/EdenCore
NCPU=""
OSNAME=""
OSVERSION=""
OSMINORVERSION=""
CURRENT_DIR=""
BUILD_DIR=""
MAKEFLAG=""
WITH_EDENCORE="false"
BUILD_TYPE="release"
INCR_INSTALL="true"

# ThirdParty Version
OPENSSL_VERSION=3.0.0
X264_VERSION=164 #x264.h -> X264_BUILD
X265_VERSION=3.4
VPX_VERSION=1.11.0
FDKAAC_VERSION=2.0.2
OPUS_VERSION=1.3.1
MP3LAME_VERSION=3.99.5 # libmp3lame/version.h
FFMPEG_VERSION=4.4.1

# print line
function header() {
echo ""
echo "-------------------------------------------------------------------------"
}

function footer() {
echo "-------------------------------------------------------------------------"
}

function fail_exit() {
	echo "Script failed: $1"
	cd ${CURRENT_DIR}
	exit 1
}

function print_vars() {
	header
	echo "[ Setted Vars ]"
	echo "- SUDO: ${SUDO}"
	echo "- PREFIX: ${PREFIX}"
	echo "- TEMP_PATH: ${TEMP_PATH}"
	echo "- NCPU: ${NCPU}"
	echo "- OSNAME: ${OSNAME}" 
	echo "- OSVERSION: ${OSVERSION}.${OSMINORVERSION}"
	echo "- CURRENT_DIR: ${CURRENT_DIR}"
	echo "- BUILD_DIR: ${BUILD_DIR}"
	echo "- MAKEFLAG: ${MAKEFLAG}"
	echo "- WITH_EDENCORE: ${WITH_EDENCORE}"
	echo "- BUILD_TYPE: ${BUILD_TYPE}"
	echo "- INCR_INSTALL: ${INCR_INSTALL}"
	footer
}

function print_third_party_version() {
	header
	echo "[ Third party version ]"
	echo "- OPENSSL: ${OPENSSL_VERSION}"
	echo "- SRTP: ${SRTP_VERSION}"
	echo "- SRT: ${SRT_VERSION}"
	echo "- X264: ${X264_VERSION}"
	echo "- X265: ${X265_VERSION}"
	echo "- VPX: ${VPX_VERSION}"
	echo "- FDKAAC: ${FDKAAC_VERSION}"
	echo "- OPUS: ${OPUS_VERSION}"
	echo "- MP3LAME: ${MP3LAME_VERSION}"
	echo "- FFMPEG: ${FFMPEG_VERSION}"
	footer
}

# detect OS
function detect_os() {
	header	
	echo "[ Detect OS ]"
	
	# MacOS
	if [[ "$OSTYPE" == "darwin"* ]]; then
		NCPU=$(sysctl -n hw.ncpu)
		OSNAME=$(sw_vers -ProductName)
		OSVERSION=$(sw_vers -ProductVersion)
	else
		NCPU=$(nproc)

		# CentOS, Fedora
		if [ -f /etc/redhat-release ]; then
			OSNAME=$(cat /etc/redhat-release |awk '{print $1}')
			OSVERSION=$(cat /etc/redhat-release |sed s/.*release\ // |sed s/\ .*// | cut -d"." -f1)
		# Ubuntu, Amazon
		elif [ -f /etc/os-release ]; then
			OSNAME=$(cat /etc/os-release | grep "^NAME" | tr -d "\"" | cut -d"=" -f2)
			OSVERSION=$(cat /etc/os-release | grep ^VERSION= | tr -d "\"" | cut -d"=" -f2 | cut -d"." -f1 | awk '{print $s1}')
			OSMINORVERSION=$(cat /etc/os-release | grep ^VERSION= | tr -d "\"" | cut -d"=" -f2 | cut -d"." -f2 | awk '{print $1}')
		fi
	fi

	echo "- OSNAME: ${OSNAME}"
	echo "- OSVERSION: ${OSVERSION}.${OSMINORVERSION}"
	footer
}

# validate OS
# This project is tested on [Ubuntu20.04, macOS(for dev)]
function validate_os() {
	header
	echo "[ Check OS Support ]"

	if [[ "${OSNAME}" == "Ubuntu" && "${OSVERSION}.${OSMINORVERSION}" != "20.04" ]]; then
		fail_exit "	${OSNAME} ${OSVERSION}.${OSMINORVERSION} not supproted"
	elif [[ "${OSNAME}" == "CentOS" ]]; then
		fail_exit "${OSNAME} ${OSVERSION}.${OSMINORVERSION} not supproted"
	elif [[ "${OSNAME}" != "macOS" && "${OSNAME}" != "Ubuntu" ]]; then
		fail_exit "	${OSNAME} ${OSVERSION}.${OSMINORVERSION} not supproted"
	fi

	echo "- Supproted OS"
	footer	
}

# parse args
function parse_args() {
	while [ "$1" != "" ]; do
		case $1 in
			"--with-eden-core")
				WITH_EDENCORE="true"
				;;
			"--debug")
				BUILD_TYPE="debug"; # <- build ffmpeg, EdenCore debug mode
				;;
		esac
		shift
	done
}

# init script
function init_script() {
	# get sudo privilege
	# for no password
	# echo '${user_name} ALL=NOPASSWD: ALL' >> /etc/sudoers
	if [[ $EUID -ne 0 ]]; then
		SUDO="sudo -E"
	fi

	CURRENT_DIR="${PWD}"
	BUILD_DIR="${CURRENT_DIR}/build"
	MAKEFLAG="${MAKEFLAGS} -j${NCPU}"
}

function install_base_ubuntu() {
	header
	echo "[ Install Ubuntu base deps ]"

	${SUDO} apt update -y
	${SUDO} apt upgrade -y
	${SUDO} apt install -y pkg-config nasm yasm automake libtool cmake make build-essential autoconf
	${SUDO} apt install -y libxml2-dev libfreetype-dev
	
	footer
}

function install_base_macos() {
	header
	echo "[ Install MacOS base deps ]"

	brew update
	brew upgrade
	brew install pkg-config nasm yasm automake libtool cmake make
	brew install libxml2 freetype
 	
	footer
}

function install_base_deps() {
	if [ "${OSNAME}" == "Ubuntu" ]; then
		install_base_ubuntu
	elif [ "${OSNAME}" == "macOS" ]; then
		install_base_macos
	else
		fail_exit "Unknown Error"
	fi
}

# install openssl
function install_openssl() {
	header
	echo "[ Install OpenSSL ]"

	local LIST_LIBS=`ls ${PREFIX}/lib/libssl* ${PREFIX}/lib64/libssl* 2>/dev/null`
	$INCR_INSTALL && [[ ! -z $LIST_LIBS ]] && echo "OpenSSL already installed." && footer && return 0

	(DIR=${TEMP_PATH}/openssl && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/openssl/openssl/archive/refs/tags/openssl-${OPENSSL_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	./config --prefix="${PREFIX}" --openssldir="${PREFIX}" -fPIC -Wl,-rpath,"${PREFIX}/lib" && \
	make ${MAKEFLAG} && \
	${SUDO} make install_sw && \
	${SUDO} rm -rf ${DIR}) || fail_exit "install openssl faield"

	footer
}

# install X264
function install_x264() {
	header
	echo "[ Install X264 ]"

	local LIST_LIBS=`ls ${PREFIX}/lib/libx264* ${PREFIX}/lib64/libx264* 2>/dev/null`
	$INCR_INSTALL && [[ ! -z $LIST_LIBS ]] && echo "X264 already installed." && footer && return 0

	(DIR=${TEMP_PATH}/x264 && \
	git clone https://github.com/mirror/x264.git ${DIR} && \
	cd ${DIR} && \
	./configure --prefix="${PREFIX}" --enable-shared --enable-pic --disable-cli && \
	make ${MAKEFLAG} && \
	${SUDO} make install && \
	rm -rf ${DIR}) || fail_exit "install x264 failed"
	
	footer
}

# install X265
function install_x265() {
	header
	echo "[ Install X265 ]"

	local LIST_LIBS=`ls ${PREFIX}/lib/libx265* ${PREFIX}/lib64/libx265* 2>/dev/null`
	$INCR_INSTALL && [[ ! -z $LIST_LIBS ]] && echo "X265 already installed." && footer && return 0

	(DIR=${TEMP_PATH}/x265 && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/videolan/x265/archive/${X265_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	cd ${DIR}/build/linux && \
	cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DENABLE_SHARED:bool=on ../../source && \
	make ${MAKEFLAG} && \
	${SUDO} make install && \
	rm -rf ${DIR}) || fail_exit "install x265 failed"
	
	footer
}

# install VPX
function install_vpx() {
	header
	echo "[ Install VPX ]"

	if [[ "${OSNAME}" == "macOS" ]]; then
		local ADDITIONAL_FLAG=--target=x86_64-darwin16-gcc # <- solve ld: --no-undefined error
	fi

	local LIST_LIBS=`ls ${PREFIX}/lib/libvpx* ${PREFIX}/lib64/libvpx* 2>/dev/null`
	$INCR_INSTALL && [[ ! -z $LIST_LIBS ]] && echo "vpx already installed." && footer && return 0

	(DIR=${TEMP_PATH}/vpx && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/webmproject/libvpx/archive/refs/tags/v${VPX_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	./configure --prefix="${PREFIX}" --enable-pic --enable-shared --disable-static --disable-debug \
							--disable-examples --disable-docs --disable-install-bins \
							--enable-vp8 --enable-vp9 ${ADDITIONAL_FLAG} && \
	make ${MAKEFLAG} && \
	${SUDO} make install && \
	rm -rf ${DIR}) || fail_exit "install vpx failed"
	
	footer
}

# install fdkaac
function install_fdkaac() {
	header
	echo "[ Install fdkaac ]"

	local LIST_LIBS=`ls ${PREFIX}/lib/libfdk-aac* ${PREFIX}/lib64/libfdk-aad* 2>/dev/null`
	$INCR_INSTALL && [[ ! -z $LIST_LIBS ]] && echo "fdkaac already installed." && footer && return 0

	(DIR=${TEMP_PATH}/fdkaac && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/mstorsjo/fdk-aac/archive/refs/tags/v${FDKAAC_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	autoreconf -fiv && \	
	./configure --prefix="${PREFIX}" --enable-shared --disable-static --datadir=/tmp/fdkaac && \
	make ${MAKEFLAG} && \
	${SUDO} make install && \
	rm -rf ${DIR}) || fail_exit "install fdkaac failed"

	footer
}

# install opus
function install_opus() {
	header
	echo "[ Install opus ]"

	local LIST_LIBS=`ls ${PREFIX}/lib/libopus* ${PREFIX}/lib64/libopus* 2>/dev/null`
	$INCR_INSTALL && [[ ! -z $LIST_LIBS ]] && echo "opus already installed." && footer && return 0

	(DIR=${TEMP_PATH}/opus && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \i

	curl -sLf https://github.com/xiph/opus/archive/refs/tags/v${OPUS_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	autoreconf -fiv && \
	./configure --prefix="${PREFIX}" --enable-shared --disable-static && \
	make ${MAKEFLAG} && \
	${SUDO} make install && \
	rm -rf ${DIR}) || fail_exit "install opus failed"

	footer
}

# install mp3lame
function install_mp3lame() {
	header
	echo "[ Install mp3lame ]"

	local LIST_LIBS=`ls ${PREFIX}/lib/libmp3lame* ${PREFIX}/lib64/libmpm3lame* 2>/dev/null`
	$INCR_INSTALL && [[ ! -z $LIST_LIBS ]] && echo "mp3lame already installed." && footer && return 0

	(DIR=${TEMP_PATH}/mp3lame && \
	git clone https://github.com/gypified/libmp3lame.git ${DIR} && \
	cd ${DIR} && \
	./configure --prefix="${PREFIX}" --enable-nasm --enable-shared=yes --enable-static=no && \
	make ${MAKEFLAG} && \
	${SUDO} make install && \
	rm -rf ${DIR}) || fail_exit "install mp3lame failed"

	footer
}


# install FFmpeg
function install_ffmpeg() {
	header
	echo "[ Install FFmpeg ]"

	#	flag save: --enable-libaom --enable-libmp3lame --enable-libfdk_aac --enable-opus

	local LIST_LIBS=`ls ${PREFIX}/lib/libavformat* ${PREFIX}/lib64/libavformat* 2>/dev/null`
	$INCR_INSTALL && [[ ! -z $LIST_LIBS ]] && echo "FFmpeg already installed." && footer && return 0

  local	DEBUG_FLAGS=""
	if [ "${BUILD_TYPE}" == "debug" ]; then
		DEBUG_FLAGS+=" --enable-debug=3  --disable-optimizations --disable-mmx --disable-stripping"
	fi

	(DIR=${TEMP_PATH}/ffmpeg && \
	mkdir -p ${DIR} && \
	cd ${DIR} && \
	curl -sLf https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n${FFMPEG_VERSION}.tar.gz | tar -xz --strip-components=1 && \
	PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:/${PREFIX}/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH} ./configure \
	--prefix="${PREFIX}" \
	--enable-gpl --enable-nonfree --enable-version3 \
	--extra-cflags="-I${PREFIX}/include" \
	--extra-ldflags="-L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib" \
	--enable-shared --disable-static \
	--enable-openssl \
	--enable-libxml2 \
  --enable-libfreetype \
	--enable-libx264 --enable-libx265 --enable-libvpx \
	--enable-libfdk-aac --enable-libopus --enable-libmp3lame \
  ${DEBUG_FLAGS} && \
	make ${MAKEFLAG} && \
	${SUDO} make install && \
	rm -rf ${DIR}) || fail_exit "install FFmpeg failed"
	
	footer
}

# build EdenCore
function install_eden_core() {
	header
	echo "[ Build EdenCore Project ]"

	# Go to current directory
	cd ${CURRENT_DIR}

	# Update the submodule and initialize
	${SUDO} git submodule update --init

	# The folder in which we will build EdenCore
	BUILD_DIR="${CURRENT_DIR}/build"
	if [ -d $build_dir ]; then
		echo "Deleted folder: ${BUILD_DIR}"
		${SUDO} rm -rf $build_dir
	fi

	(cmake -S. -B build && \
	cmake --build build && \
	cmake --build build --target install) || fail_exit "install EdenCore failed"
	
	footer
}

# Main Script
detect_os
validate_os
parse_args $*
init_script
print_vars
print_third_party_version

install_base_deps

install_openssl
#install_srtp
#install_srt
#install_webrtc
install_x264
install_x265
install_vpx
install_fdkaac
install_opus
install_mp3lame
install_ffmpeg

if [ "${WITH_EDENCORE}" == "true" ]; then
	install_eden_core
fi

