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
export commit_id="391409d0335d67ab3c7e86dcd16ea8af70f231a0"

git clone https://github.com/ihexon/libkrun.git "$LIBKRUN_SRC"
cd "$LIBKRUN_SRC" && git checkout "$commit_id"

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

repack_libkrun_source() {
    cd "$WORKSPACE"
    tar --zstd -cf "$SRC_ARCHIVE" -C "$(dirname "$LIBKRUN_SRC")" "$(basename "$LIBKRUN_SRC")"
}

release() {
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_libkrun_linux
repack_libkrun_source
release
