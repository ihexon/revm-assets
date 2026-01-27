#!/usr/bin/env sh
set -xe
# Please build in alpine container using docker or podman
apk add gcc git musl-dev zlib-dev make bash

git clone https://github.com/mkj/dropbear.git -b DROPBEAR_2025.89

cd dropbear
LDFLAGS="-Wl,--gc-sections" CFLAGS="-ffunction-sections -fdata-sections" bash ./configure \
	--disable-zlib \
	--disable-syslog \
	--disable-wtmpx \
	--disable-pam \
	--disable-utmpx \
	--disable-wtmp \
	--disable-shadow \
	--disable-fuzz \
	--enable-static
make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1
du -sk dropbearmulti
