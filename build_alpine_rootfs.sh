#!/usr/bin/env sh
set -xe

export PLT=$(uname)
export ARCH=$(uname -m)
export PKG_NAME="alpine-rootfs"

export WORKSPACE="$(pwd)"
export SRC_DIR="$WORKSPACE/$PKG_NAME"
export PREFIX="$SRC_DIR/_install_"

export RELEASE_TAR="$PKG_NAME-$PLT-$ARCH.tar.zst"

build_alpine_rootfs() {
    cd "$WORKSPACE"
    docker run --name="$PKG_NAME" alpine:edge sh -c "apk update && apk add podman"
}

release() {
    cd "$WORKSPACE"
    docker export "$PKG_NAME" | zstd -T0 -19 -o "$RELEASE_TAR"
}

build(){
    build_alpine_rootfs
}

build
release
