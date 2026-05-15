#!/usr/bin/env sh
set -xe

export PLT=$(uname)
export ARCH=$(uname -m)
export PKG_NAME="alpine-rootfs"
export ALPINE_VERSION="${ALPINE_VERSION:-3.23.3}"

export WORKSPACE="$(pwd)"
export SRC_DIR="$WORKSPACE/$PKG_NAME"
export PREFIX="$SRC_DIR/_install_"

export RELEASE_TAR="$PKG_NAME-$PLT-$ARCH.tar.zst"

build_alpine_rootfs_linux() {
    cd "$WORKSPACE"
    docker rm -f "$PKG_NAME" >/dev/null 2>&1 || true
    docker run --name="$PKG_NAME" "alpine:$ALPINE_VERSION" sh -c "apk update && apk add podman nftables bash tar zstd util-linux && rm -rf /var/lib/containers"
}

release() {
    cd "$WORKSPACE"
    mkdir -p "$PREFIX"
    docker export "$PKG_NAME" | tar -x -C "$PREFIX"
    install -D -m 0644 "$WORKSPACE/containers.conf" "$PREFIX/etc/containers/containers.conf"
    #install -D -m 0644 "$WORKSPACE/storage.conf" "$PREFIX/etc/containers/storage.conf"
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
    docker rm "$PKG_NAME"
}

build_alpine_rootfs_linux
release
