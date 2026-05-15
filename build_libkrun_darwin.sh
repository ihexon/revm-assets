#!/usr/bin/env bash
set -xe
set -o pipefail

PLT="$(uname)"
ARCH="$(uname -m)"
PKG_NAME="libkrun"

WORKSPACE="$(pwd)"
LIBKRUN_SRC="$WORKSPACE/$PKG_NAME"
PREFIX="$LIBKRUN_SRC/_install_"
LIBEPOXY_PREFIX="$WORKSPACE/libepoxy/_install_"
VIRGLRENDERER_PREFIX="$WORKSPACE/virglrenderer/_install_"
LIBEPOXY_TAR="$WORKSPACE/libepoxy-Darwin-arm64.tar.zst"
VIRGLRENDERER_TAR="$WORKSPACE/virglrenderer-Darwin-arm64.tar.zst"
RELEASE_TAR="$PKG_NAME-$PLT-$ARCH.tar.zst"

LIBKRUN_COMMIT="391409d0335d67ab3c7e86dcd16ea8af70f231a0"
MOLTENVK_PREFIX="${MOLTENVK_PREFIX:-}"

checkout_libkrun() {
    git clone https://github.com/ihexon/libkrun.git "$LIBKRUN_SRC"
    cd "$LIBKRUN_SRC" && git checkout "$LIBKRUN_COMMIT"
}

set_libkrun_crate_type() {
    cd "$LIBKRUN_SRC"
    local crate_type="$1"
    perl -0pi -e "s/crate-type = \\[[^\\]]+\\]/crate-type = [$crate_type]/" src/libkrun/Cargo.toml
}

unpack_static_deps_darwin() {
    if [[ ! -f "$LIBEPOXY_TAR" ]]; then
        echo "prebuilt $LIBEPOXY_TAR not found" >&2
        exit 100
    fi

    if [[ ! -f "$VIRGLRENDERER_TAR" ]]; then
        echo "prebuilt $VIRGLRENDERER_TAR not found" >&2
        exit 100
    fi

    rm -rf "$LIBEPOXY_PREFIX" "$VIRGLRENDERER_PREFIX"
    mkdir -p "$LIBEPOXY_PREFIX" "$VIRGLRENDERER_PREFIX"
    tar --zstd -xf "$LIBEPOXY_TAR" -C "$LIBEPOXY_PREFIX"
    tar --zstd -xf "$VIRGLRENDERER_TAR" -C "$VIRGLRENDERER_PREFIX"
}

install_static_deps_darwin() {
    brew tap slp/krun
    brew install pkg-config molten-vk lld
    brew info molten-vk
    MOLTENVK_PREFIX="${MOLTENVK_PREFIX:-$(brew --prefix molten-vk)}"
    export MOLTENVK_PREFIX

    unpack_static_deps_darwin
}

build_libkrun_darwin() {
    export RUSTUP_TOOLCHAIN="${RUSTUP_TOOLCHAIN:-nightly}"

    install_static_deps_darwin

    export PKG_CONFIG_PATH="$VIRGLRENDERER_PREFIX/lib/pkgconfig:$LIBEPOXY_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export PKG_CONFIG_ALL_STATIC=1
    export LIBRARY_PATH="$VIRGLRENDERER_PREFIX/lib:$LIBEPOXY_PREFIX/lib:$MOLTENVK_PREFIX/lib:$MOLTENVK_PREFIX/libexec/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
    export CPATH="$VIRGLRENDERER_PREFIX/include:$LIBEPOXY_PREFIX/include:$MOLTENVK_PREFIX/libexec/include${CPATH:+:$CPATH}"

    cd "$LIBKRUN_SRC"
    set_libkrun_crate_type '"cdylib", "staticlib", "lib"'
    make clean
    TIMESYNC=1 make PREFIX="$PREFIX" BLK=1 NET=1 GPU=1
    TIMESYNC=1 make PREFIX="$PREFIX" BLK=1 NET=1 GPU=1 install

    rm -rf "$PREFIX/lib/pkgconfig"
    install -m 644 target/release/libkrun.a "$PREFIX/lib/"
    install -m 644 "$VIRGLRENDERER_PREFIX/lib/libvirglrenderer.a" "$LIBEPOXY_PREFIX/lib/libepoxy.a" "$PREFIX/lib/"
    install -m 644 "$MOLTENVK_PREFIX/lib/libMoltenVK.a" "$MOLTENVK_PREFIX/libexec/lib/libSPIRVCross.a" "$MOLTENVK_PREFIX/libexec/lib/libSPIRVTools.a" "$PREFIX/lib/"
}

release() {
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

checkout_libkrun
build_libkrun_darwin
release
