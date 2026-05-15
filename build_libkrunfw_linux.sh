#! /usr/bin/env bash
set -xe
set -o pipefail

export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"

export LIBKRUNFW_SRC="$WORKSPACE/libkrunfw"
export PREFIX="$LIBKRUNFW_SRC/_install_"

export SRC_ARCHIVE="libkrunfw-src-$PLT-$ARCH.tar.zst"
export RELEASE_TAR="libkrunfw-$PLT-$ARCH.tar.zst"
export LIBKRUNFW_COMMIT="7d995aa487644fa0f57eb4f42fe730460f50087b"

build_libkrunfw_linux() {
    git clone https://github.com/ihexon/libkrunfw.git "$LIBKRUNFW_SRC"
    cd "$LIBKRUNFW_SRC" && git checkout "$LIBKRUNFW_COMMIT"

    cp -av "$WORKSPACE/config-libkrunfw_aarch64" "$LIBKRUNFW_SRC/config-libkrunfw_aarch64"
    cp -av "$WORKSPACE/config-libkrunfw_x86_64" "$LIBKRUNFW_SRC/config-libkrunfw_x86_64"

    if [[ "$ARCH" == "aarch64" ]]; then
        ARCH=arm64 make PREFIX="$PREFIX" -j8
        rm -rf "$PREFIX"
        ARCH=arm64 make PREFIX="$PREFIX" -j8 install
    else
        make PREFIX="$PREFIX" -j8
        rm -rf "$PREFIX"
        make PREFIX="$PREFIX" -j8 install
    fi
}

repack_libkrunfw_source() {
    cd "$WORKSPACE"
    tar --zstd -cf "$SRC_ARCHIVE" -C "$(dirname "$LIBKRUNFW_SRC")" "$(basename "$LIBKRUNFW_SRC")"
}

release() {
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_libkrunfw_linux
repack_libkrunfw_source
release
