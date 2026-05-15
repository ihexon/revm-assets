#!/usr/bin/env bash
set -xe
set -o pipefail

PLT="$(uname)"
ARCH="$(uname -m)"
PKG_NAME="alpine-rootfs"
ALPINE_VERSION="${ALPINE_VERSION:-3.23.3}"

WORKSPACE="$(pwd)"
ROOTFS="$WORKSPACE/$PKG_NAME"
CONTAINER="$PKG_NAME-$ARCH"
RELEASE_TAR="$WORKSPACE/$PKG_NAME-$PLT-$ARCH.tar.zst"

cleanup() {
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}

build_alpine_rootfs_linux() {
    cd "$WORKSPACE"
    cleanup
    rm -rf "$ROOTFS"
    mkdir -p "$ROOTFS"

    docker run --name="$CONTAINER" "alpine:$ALPINE_VERSION" \
        sh -c "apk add --no-cache bash nftables podman tar util-linux zstd && rm -rf /var/lib/containers"

    docker export "$CONTAINER" | tar -x -C "$ROOTFS"
    install -D -m 0644 "$WORKSPACE/containers.conf" "$ROOTFS/etc/containers/containers.conf"
}

release() {
    cd "$WORKSPACE"
    tar --zstd -cvf "$RELEASE_TAR" -C "$ROOTFS" .
}

trap cleanup EXIT

build_alpine_rootfs_linux
release
