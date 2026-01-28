#! /usr/bin/env bash
set -xe
export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"

export LIBKRUNFW_SRC="$WORKSPACE/libkrunfw"
export PREFIX="$LIBKRUNFW_SRC/_install_"

export SRC_ARCHIVE="libkrunfw-src.tar.zst"

build_libkrunfw_linux() {
    sudo apt-get update
    sudo apt-get install -y make gcc bc bison flex elfutils python3-pyelftools curl patch libelf-dev

    git clone https://github.com/containers/libkrunfw.git "$LIBKRUNFW_SRC"

    cd "$LIBKRUNFW_SRC"

    make -j8
    make -j8 install
}

build_libkrunfw_darwin() {
    cd "$LIBKRUNFW_SRC"

    if [[ ! -f kernel.c ]]; then
        echo "kernel.c not find, please build kernel.c on linux first"
        exit 100
    fi

    make -j8
    make -j8 install
}

build_libkrunfw() {
    if [[ "$PLT" == "Linux" ]]; then
        build_libkrunfw_linux
    fi

    if [[ "$PLT" == "Darwin" ]]; then
        build_libkrunfw_darwin
    fi
}

repack_libkrunfw_source() {
    cd "$WORKSPACE"
    tar --zstd -cf "$SRC_ARCHIVE" -C "$(dirname "$LIBKRUNFW_SRC")" "$(basename "$LIBKRUNFW_SRC")"
}

release() {
    cd "$WORKSPACE"
}

build_libkrunfw
repack_libkrunfw_source
