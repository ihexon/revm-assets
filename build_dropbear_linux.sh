#!/usr/bin/env sh
set -xe

export PLT=$(uname)
export ARCH=$(uname -m)
export PKG_NAME="dropbear"

export WORKSPACE="$(pwd)"
export SRC_DIR="$WORKSPACE/$PKG_NAME"
export PREFIX="$SRC_DIR/_install_"

export RELEASE_TAR="$PKG_NAME-$PLT-$ARCH.tar.zst"

export DROPBEAR_PATCH="$WORKSPACE/dropbear.diff"
export DROPBEAR_PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"

build_dropbear_linux() {
    cd "$WORKSPACE"
    git clone -b DROPBEAR_2025.89 https://github.com/mkj/dropbear.git "$SRC_DIR"
    cd "$SRC_DIR"
    git apply "$DROPBEAR_PATCH"

    LDFLAGS="-Wl,--gc-sections" CFLAGS="-ffunction-sections -fdata-sections -DDROPBEAR_LISTEN_BACKLOG=50" bash ./configure \
        --prefix="$PREFIX" \
        --disable-zlib \
        --disable-syslog \
        --disable-wtmpx \
        --disable-pam \
        --disable-utmpx \
        --disable-wtmp \
        --disable-shadow \
        --disable-fuzz \
        --disable-lastlog \
        --enable-static
    make PROGRAMS="$DROPBEAR_PROGRAMS" MULTI=1
    make PROGRAMS="$DROPBEAR_PROGRAMS" MULTI=1 install
}

release() {
    cd "$WORKSPACE"
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_dropbear_linux
release
