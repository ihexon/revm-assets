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
export commit_id="6e404e9fdb7d1c581d844ffe5dfb72cf7a9a0b1f"

build_libkrunfw_linux() {
    sudo apt-get update
    sudo apt-get install -y make gcc bc bison flex elfutils python3-pyelftools curl patch libelf-dev

    git clone https://github.com/containers/libkrunfw.git "$LIBKRUNFW_SRC"
    cd "$LIBKRUNFW_SRC" && git checkout "$commit_id"

    cp -av "$WORKSPACE/config-libkrunfw_aarch64" "$LIBKRUNFW_SRC/config-libkrunfw_aarch64"
    cp -av "$WORKSPACE/config-libkrunfw_x86_64" "$LIBKRUNFW_SRC/config-libkrunfw_x86_64"

    if [[ "$ARCH" == "aarch64" ]]; then
        # set ARCH to arm64 rather then aarch64
        local ARM64="arm64"
        ARCH=$ARM64 make PREFIX="$PREFIX" -j8
        rm -rf "$PREFIX"
        ARCH=$ARM64 make PREFIX="$PREFIX" -j8 install
    else
        make PREFIX="$PREFIX" -j8
        rm -rf "$PREFIX"
        make PREFIX="$PREFIX" -j8 install
    fi
}

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
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_libkrunfw
repack_libkrunfw_source
release
