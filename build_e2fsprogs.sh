#! /usr/bin/env bash
set -xe

export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"
export SRC_DIR="$WORKSPACE/e2fsprogs"
export PREFIX="$SRC_DIR/_install_"

export RELEASE_TAR="e2fsprogs-$PLT-$ARCH.tar.zst"

git clone https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git "$SRC_DIR" -b v1.47.3

build_e2fsprogs_darwin(){
    cd "$SRC_DIR"
    ./configure --prefix="$PREFIX"
    make -j8
    make install
}

release() {
    cd "$WORKSPACE"
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_e2fsprogs_darwin
release