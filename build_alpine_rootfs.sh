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
    docker run --name="$PKG_NAME" alpine:3.23.3 sh -c "apk update && apk add podman nftables"
}

release() {
    cd "$WORKSPACE"
    mkdir -p "$PREFIX"
    docker export "$PKG_NAME" | tar -x -C "$PREFIX"
    install -D -m 0644 "$WORKSPACE/containers.conf" "$PREFIX/etc/containers/containers.conf"
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
    docker rm "$PKG_NAME"
}

build() {
    build_alpine_rootfs
}

build
release
