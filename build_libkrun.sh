#! /usr/bin/env bash
set -xe
set -o pipefail

export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"

export LIBKRUN_SRC="$WORKSPACE/libkrun"
export PREFIX="$LIBKRUN_SRC/_install_"

export SRC_ARCHIVE="libkrun-src-$PLT-$ARCH.tar.zst"
export RELEASE_TAR="libkrun-$PLT-$ARCH.tar.zst"

export commit_id="ed9c408129fa4730e65b53333819a477ede93555"

git clone https://github.com/containers/libkrun.git "$LIBKRUN_SRC" && cd "$LIBKRUN_SRC" && git checkout "$commit_id"

build_libkrun_darwin() {
    brew tap slp/krun
    brew install virglrenderer lld
    brew info virglrenderer

    cd "$LIBKRUN_SRC"
    make PREFIX="$PREFIX" GPU=1 BLK=1 NET=1

    rm -rf "$PREFIX"
    make PREFIX="$PREFIX" GPU=1 BLK=1 NET=1 install
}

build_libkrun_linux() {
    sudo apt update
    sudo apt install -y llvm clang libclang-dev

    cd "$LIBKRUN_SRC"

    make PREFIX="$PREFIX" BLK=1 NET=1

    rm -rf "$PREFIX"
    make PREFIX="$PREFIX" BLK=1 NET=1 install
}

build_libkrun() {
    cd "$WORKSPACE"

    if [[ "$PLT" == "Linux" ]]; then
        build_libkrun_linux
    fi

    if [[ "$PLT" == "Darwin" ]]; then
        build_libkrun_darwin
    fi
}

repack_libkrun_source() {
    cd "$WORKSPACE"
    tar --zstd -cf "$SRC_ARCHIVE" -C "$(dirname "$LIBKRUN_SRC")" "$(basename "$LIBKRUN_SRC")"
}

release() {
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_libkrun
repack_libkrun_source
release
