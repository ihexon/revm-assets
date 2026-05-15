#!/usr/bin/env bash
set -xe
set -o pipefail

PLT="$(uname)"
ARCH="$(uname -m)"
PKG_NAME="libkrun"

WORKSPACE="$(pwd)"
LIBKRUN_SRC="$WORKSPACE/$PKG_NAME"
PREFIX="$LIBKRUN_SRC/_install_"
RELEASE_TAR="$WORKSPACE/$PKG_NAME-$PLT-$ARCH.tar.zst"

LIBKRUN_COMMIT="391409d0335d67ab3c7e86dcd16ea8af70f231a0"

checkout_libkrun() {
    git clone https://github.com/ihexon/libkrun.git "$LIBKRUN_SRC"
    cd "$LIBKRUN_SRC" && git checkout "$LIBKRUN_COMMIT"
}

set_libkrun_crate_type() {
    cd "$LIBKRUN_SRC"
    local crate_type="$1"
    perl -0pi -e "s/crate-type = \\[[^\\]]+\\]/crate-type = [$crate_type]/" src/libkrun/Cargo.toml
}

build_libkrun_linux() {
    export RUSTFLAGS="${RUSTFLAGS:-} -C linker=gcc -C link-arg=-static-libgcc"

    cd "$LIBKRUN_SRC"
    set_libkrun_crate_type '"cdylib", "staticlib", "lib"'
    make clean
    make PREFIX="$PREFIX" BLK=1 NET=1

    rm -rf "$PREFIX"
    make PREFIX="$PREFIX" BLK=1 NET=1 install
    install -m 644 target/release/libkrun.a "$PREFIX/lib64/"
}

release() {
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

checkout_libkrun
build_libkrun_linux
release
