#!/usr/bin/env bash
set -xe
set -o pipefail

PLT="$(uname)"
ARCH="$(uname -m)"
PKG_NAME="busybox"

WORKSPACE="$(pwd)"
SRC_DIR="$WORKSPACE/$PKG_NAME"
PREFIX="$SRC_DIR/_install_"

RELEASE_TAR="$WORKSPACE/$PKG_NAME-$PLT-$ARCH.tar.zst"

case "$ARCH" in
    aarch64)
        BUSYBOX_DEB_URL="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/pool/main/b/busybox/busybox-static_1.37.0-4ubuntu1_arm64.deb"
        ;;
    x86_64)
        BUSYBOX_DEB_URL="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main/b/busybox/busybox-static_1.36.1-6ubuntu3.1_amd64.deb"
        ;;
    *)
        echo "unsupported arch: $ARCH" >&2
        exit 1
        ;;
esac

build_busybox_linux() {
    mkdir -p "$SRC_DIR"
    cd "$SRC_DIR"
    wget "$BUSYBOX_DEB_URL" --output-document=busybox.deb
    dpkg -X busybox.deb "$PREFIX"
}

release() {
    cd "$WORKSPACE"
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_busybox_linux
release
