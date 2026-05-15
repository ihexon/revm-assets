#! /usr/bin/env bash
set -xe
set -o pipefail

export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"

export LIBKRUNFW_SRC="$WORKSPACE/libkrunfw"
export PREFIX="$LIBKRUNFW_SRC/_install_"

export RELEASE_TAR="libkrunfw-$PLT-$ARCH.tar.zst"

build_libkrunfw_darwin() {
    cd "$WORKSPACE"

    if [[ ! -f libkrunfw-src-Linux-aarch64.tar.zst ]]; then
        echo "prebuild libkrunfw-src-Linux-aarch64.tar.zst not find, please download it"
        exit 100
    fi

    tar --zstd -xf libkrunfw-src-Linux-aarch64.tar.zst

    cd "$LIBKRUNFW_SRC"

    if [[ ! -f kernel.c ]]; then
        echo "kernel.c not find, please build kernel.c on linux first"
        exit 100
    fi

    make PREFIX="$PREFIX" -j8
    rm -rf "$PREFIX"
    make PREFIX="$PREFIX" -j8 install
}

release() {
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_libkrunfw_darwin
release
