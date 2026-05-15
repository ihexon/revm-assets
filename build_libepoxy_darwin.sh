#! /usr/bin/env bash
set -xe
set -o pipefail

export PLT=$(uname)
export ARCH=$(uname -m)
export WORKSPACE="$(pwd)"
export PKG_NAME="libepoxy"
export PREFIX="$WORKSPACE/$PKG_NAME/_install_"
export RELEASE_TAR="$PKG_NAME-$PLT-$ARCH.tar.zst"

export LIBEPOXY_VERSION="1.5.10"
export LIBEPOXY_SHA256="072cda4b59dd098bba8c2363a6247299db1fa89411dc221c8b81b8ee8192e623"

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

build_libepoxy_darwin() {
    local dist="$WORKSPACE/distfiles/libepoxy-$LIBEPOXY_VERSION.tar.xz"
    local src="$WORKSPACE/build/libepoxy-$LIBEPOXY_VERSION"

    brew install meson ninja pkg-config

    mkdir -p "$WORKSPACE/distfiles" "$WORKSPACE/build"
    download "https://download.gnome.org/sources/libepoxy/1.5/libepoxy-$LIBEPOXY_VERSION.tar.xz" "$dist"
    verify_sha256 "$LIBEPOXY_SHA256" "$dist"

    rm -rf "$src" "$PREFIX"
    tar -xf "$dist" -C "$WORKSPACE/build"

    cd "$src"
    meson setup build-static \
        --prefix="$PREFIX" \
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

release() {
    cd "$WORKSPACE"
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build_libepoxy_darwin
release
