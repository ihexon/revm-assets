#! /usr/bin/env bash
set -xe

export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"

export LIBKRUN_SRC="$WORKSPACE/libkrun"
export PREFIX="$LIBKRUN_SRC/_install_"

export SRC_ARCHIVE="libkrun-src.tar"


git clone https://github.com/containers/libkrun.git "$LIBKRUN_SRC"

build_libkrun_dawrin() {
    brew tap slp/krun
    brew install virglrenderer lld
    brew info virglrenderer

    cd "$LIBKRUN_SRC"
    make GPU=1 BLK=1 NET=1
    make GPU=1 BLK=1 NET=1 install
}

build_libkrun_linux() {
    sudo apt update
    sudo apt install llvm clang libclang-dev

    cd "$LIBKRUN_SRC"
    make BLK=1 NET=1
    make BLK=1 NET=1 install
}

build_libkrun() {
    cd "$WORKSPACE"

    if [[ "$PLT" == "Linux" ]]; then
        build_libkrun_linux
    fi

    if [[ "$PLT" == "Darwin" ]]; then
        build_libkrun_dawrin
    fi
}

repack_libkrun_source() {
    cd "$WORKSPACE"
    tar --zstd -cf "$SRC_ARCHIVE" -C "$(dirname "$LIBKRUN_SRC")" "$(basename "$LIBKRUN_SRC")"
}

build_libkrun
repack_libkrun_source
