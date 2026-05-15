#! /usr/bin/env bash
set -xe
set -o pipefail

export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"

export LIBKRUNFW_SRC="$WORKSPACE/libkrunfw"
export PREFIX="$LIBKRUNFW_SRC/_install_"

export RELEASE_TAR="libkrunfw-$PLT-$ARCH.tar.zst"
export SRC_ARCHIVE="libkrunfw-src-Linux-aarch64.tar.zst"

build_libkrunfw_darwin() {
    cd "$WORKSPACE"

    if [[ ! -f "$SRC_ARCHIVE" ]]; then
        echo "prebuilt $SRC_ARCHIVE not found" >&2
        exit 100
    fi

    tar --zstd -xf "$SRC_ARCHIVE"

    cd "$LIBKRUNFW_SRC"

    if [[ ! -f kernel.c ]]; then
        echo "kernel.c not found; build libkrunfw on Linux first" >&2
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
