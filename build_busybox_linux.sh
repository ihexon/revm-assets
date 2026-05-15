#! /usr/bin/env bash
set -xe
export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"
export SRC_DIR="$WORKSPACE/busybox"
export PREFIX="$SRC_DIR/_install_"

export RELEASE_TAR="busybox-$PLT-$ARCH.tar.zst"

build_busybox_linux() {
    mkdir -p "$SRC_DIR"
    cd "$SRC_DIR"

    if [[ $(uname -m) == "aarch64" ]]; then
        wget https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/pool/main/b/busybox/busybox-static_1.37.0-4ubuntu1_arm64.deb --output-document=busybox.deb
    fi

    if [[ $(uname -m) == "x86_64" ]]; then
        wget https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main/b/busybox/busybox-static_1.36.1-6ubuntu3.1_amd64.deb --output-document=busybox.deb
    fi
    dpkg -X busybox.deb "$PREFIX"
}

release() {
    cd "$WORKSPACE"
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build() {
    build_busybox_linux
}

build
release
