#! /usr/bin/env bash
set -xe
set -o pipefail

export PLT=$(uname)
export ARCH=$(uname -m)
export WORKSPACE="$(pwd)"
export LIBKRUN_SRC="$WORKSPACE/libkrun"
export PREFIX="$LIBKRUN_SRC/_install_"
export LIBKRUN_DEPS_PREFIX="$LIBKRUN_SRC/_deps_"
export SRC_ARCHIVE="libkrun-src-$PLT-$ARCH.tar.zst"
export RELEASE_TAR="libkrun-$PLT-$ARCH.tar.zst"
export commit_id="391409d0335d67ab3c7e86dcd16ea8af70f231a0"

export LIBEPOXY_VERSION="1.5.10"
export LIBEPOXY_SHA256="072cda4b59dd098bba8c2363a6247299db1fa89411dc221c8b81b8ee8192e623"
export VIRGLRENDERER_VERSION="0.10.4e-krunkit"
export VIRGLRENDERER_SHA256="09d000623fbdb966cb604eb48c962a0815e8142383e6066d6494809335b76dbb"
export MOLTENVK_PREFIX="${MOLTENVK_PREFIX:-}"

git clone https://github.com/ihexon/libkrun.git "$LIBKRUN_SRC"
cd "$LIBKRUN_SRC" && git checkout "$commit_id"

set_libkrun_crate_type() {
    cd "$LIBKRUN_SRC"
    local crate_type="$1"
    perl -0pi -e "s/crate-type = \\[[^\\]]+\\]/crate-type = [$crate_type]/" src/libkrun/Cargo.toml
}

download() {
    local url="$1"
    local output="$2"

    if [[ ! -f "$output" ]]; then
        curl -fL --retry 3 -o "$output" "$url"
    fi
}

verify_sha256() {
    local expected="$1"
    local file="$2"
    local actual

    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
        echo "sha256 mismatch for $file: expected $expected, got $actual" >&2
        exit 1
    fi
}

build_libepoxy_static_darwin() {
    local dist="$WORKSPACE/distfiles/libepoxy-$LIBEPOXY_VERSION.tar.xz"
    local src="$WORKSPACE/build/libepoxy-$LIBEPOXY_VERSION"

    mkdir -p "$WORKSPACE/distfiles" "$WORKSPACE/build"
    download "https://download.gnome.org/sources/libepoxy/1.5/libepoxy-$LIBEPOXY_VERSION.tar.xz" "$dist"
    verify_sha256 "$LIBEPOXY_SHA256" "$dist"

    rm -rf "$src"
    tar -xf "$dist" -C "$WORKSPACE/build"

    cd "$src"
    meson setup build-static \
        --prefix="$LIBKRUN_DEPS_PREFIX" \
        --libdir=lib \
        --buildtype=release \
        --default-library=static \
        -Dglx=no \
        -Degl=no \
        -Dx11=false \
        -Dtests=false
    meson compile -C build-static
    meson install -C build-static
}

build_virglrenderer_static_darwin() {
    local dist="$WORKSPACE/distfiles/virglrenderer-$VIRGLRENDERER_VERSION.tar.gz"
    local src="$WORKSPACE/build/virglrenderer-$VIRGLRENDERER_VERSION"
    local moltenvk_lib="$MOLTENVK_PREFIX/lib/libMoltenVK.a"
    local spirv_cross_lib="$MOLTENVK_PREFIX/libexec/lib/libSPIRVCross.a"
    local spirv_tools_lib="$MOLTENVK_PREFIX/libexec/lib/libSPIRVTools.a"

    if [[ -z "$MOLTENVK_PREFIX" || ! -f "$moltenvk_lib" || ! -f "$spirv_cross_lib" || ! -f "$spirv_tools_lib" ]]; then
        echo "MoltenVK static libraries were not found; install Homebrew molten-vk first." >&2
        exit 1
    fi

    mkdir -p "$WORKSPACE/distfiles" "$WORKSPACE/build"
    download "https://gitlab.freedesktop.org/slp/virglrenderer/-/archive/$VIRGLRENDERER_VERSION/virglrenderer-$VIRGLRENDERER_VERSION.tar.gz" "$dist"
    verify_sha256 "$VIRGLRENDERER_SHA256" "$dist"

    rm -rf "$src"
    tar -xf "$dist" -C "$WORKSPACE/build"

    cd "$src"
    perl -0pi -e "s|add_project_link_arguments\\('-lMoltenVK', language : 'c'\\)|add_project_link_arguments('$moltenvk_lib', '$spirv_cross_lib', '$spirv_tools_lib', language : 'c')|" meson.build
    perl -0pi -e "s|-I/opt/homebrew/opt/molten-vk/libexec/include|-I$MOLTENVK_PREFIX/libexec/include|" meson.build
    perl -0pi -e "s|if not with_host_windows\\n   subdir\\('vtest'\\)\\nendif\\n\\n||" meson.build

    PKG_CONFIG_PATH="$LIBKRUN_DEPS_PREFIX/lib/pkgconfig" \
    PKG_CONFIG_ALL_STATIC=1 \
    CPPFLAGS="-I$LIBKRUN_DEPS_PREFIX/include -I$MOLTENVK_PREFIX/libexec/include" \
    LDFLAGS="-L$LIBKRUN_DEPS_PREFIX/lib" \
        meson setup build-static \
            --prefix="$LIBKRUN_DEPS_PREFIX" \
            --libdir=lib \
            --buildtype=release \
            --default-library=static \
            -Dvenus=true \
            -Drender-server=false \
            -Ddrm=disabled \
            '-Dplatforms=[]'

    PKG_CONFIG_PATH="$LIBKRUN_DEPS_PREFIX/lib/pkgconfig" \
    PKG_CONFIG_ALL_STATIC=1 \
        meson compile -C build-static
    meson install -C build-static

    cat >> "$LIBKRUN_DEPS_PREFIX/lib/pkgconfig/virglrenderer.pc" <<EOF
Libs.private: $moltenvk_lib $spirv_cross_lib $spirv_tools_lib -framework Metal -framework Foundation -framework QuartzCore -framework CoreGraphics -framework IOSurface -framework IOKit -framework AppKit -lc++ -lobjc
EOF
}

build_libkrun_deps_darwin() {
    brew tap slp/krun
    brew install meson ninja pkg-config molten-vk lld
    brew info molten-vk
    MOLTENVK_PREFIX="${MOLTENVK_PREFIX:-$(brew --prefix molten-vk)}"
    export MOLTENVK_PREFIX

    rm -rf "$LIBKRUN_DEPS_PREFIX"
    build_libepoxy_static_darwin
    build_virglrenderer_static_darwin
}

build_libkrun_darwin() {
    export RUSTUP_TOOLCHAIN="${RUSTUP_TOOLCHAIN:-nightly}"

    build_libkrun_deps_darwin

    export PKG_CONFIG_PATH="$LIBKRUN_DEPS_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export PKG_CONFIG_ALL_STATIC=1
    export LIBRARY_PATH="$LIBKRUN_DEPS_PREFIX/lib:$MOLTENVK_PREFIX/lib:$MOLTENVK_PREFIX/libexec/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
    export CPATH="$LIBKRUN_DEPS_PREFIX/include:$MOLTENVK_PREFIX/libexec/include${CPATH:+:$CPATH}"

    cd "$LIBKRUN_SRC"
    set_libkrun_crate_type '"cdylib", "staticlib", "lib"'
    make clean
    TIMESYNC=1 make PREFIX="$PREFIX" BLK=1 NET=1 GPU=1
    TIMESYNC=1 make PREFIX="$PREFIX" BLK=1 NET=1 GPU=1 install

    rm -rf "$PREFIX/lib/pkgconfig"
    install -m 644 target/release/libkrun.a "$PREFIX/lib/"
    install -m 644 "$LIBKRUN_DEPS_PREFIX/lib/libvirglrenderer.a" "$LIBKRUN_DEPS_PREFIX/lib/libepoxy.a" "$PREFIX/lib/"
    install -m 644 "$MOLTENVK_PREFIX/lib/libMoltenVK.a" "$MOLTENVK_PREFIX/libexec/lib/libSPIRVCross.a" "$MOLTENVK_PREFIX/libexec/lib/libSPIRVTools.a" "$PREFIX/lib/"
}

build_libkrun_linux() {
    sudo apt update
    sudo apt install -y llvm clang libclang-dev libcap-ng-dev

    export RUSTFLAGS="${RUSTFLAGS:-} -C linker=gcc -C link-arg=-static-libgcc"

    cd "$LIBKRUN_SRC"
    set_libkrun_crate_type '"cdylib", "staticlib", "lib"'
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
