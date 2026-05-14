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

enable_libkrun_staticlib() {
    cd "$LIBKRUN_SRC"
    if ! grep -q '"staticlib"' src/libkrun/Cargo.toml; then
        sed -i 's/crate-type = \["cdylib", "lib"\]/crate-type = ["cdylib", "staticlib", "lib"]/' src/libkrun/Cargo.toml
    fi
}

build_libkrun_darwin() {
    brew tap slp/krun
    brew install virglrenderer lld
    brew info virglrenderer

    cd "$LIBKRUN_SRC"
    enable_libkrun_staticlib
    make clean
    TIMESYNC=1 make PREFIX="$PREFIX" GPU=1 BLK=1 NET=1

    rm -rf "$PREFIX"
    TIMESYNC=1 make PREFIX="$PREFIX" GPU=1 BLK=1 NET=1 install
    install -m 644 target/release/libkrun.a "$PREFIX/lib/"
}

build_libkrun_linux() {
    sudo apt update
    sudo apt install -y llvm clang libclang-dev libcap-ng-dev

    export RUSTFLAGS="${RUSTFLAGS:-} -C linker=gcc -C link-arg=-static-libgcc"

    cd "$LIBKRUN_SRC"
    enable_libkrun_staticlib
    make clean
    make PREFIX="$PREFIX" BLK=1 NET=1

    rm -rf "$PREFIX"
    make PREFIX="$PREFIX" BLK=1 NET=1 install
    install -m 644 target/release/libkrun.a "$PREFIX/lib64/"
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
