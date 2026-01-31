#! /usr/bin/env bash
set -xe
set -o pipfail

export PLT=$(uname)
export ARCH=$(uname -m)

export WORKSPACE="$(pwd)"
export SRC_DIR="$WORKSPACE/e2fsprogs"
export PREFIX="$SRC_DIR/_install_"

export RELEASE_TAR="e2fsprogs-$PLT-$ARCH.tar.zst"

build_e2fsprogs_darwin() {
    git clone https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git "$SRC_DIR" -b v1.47.3

    cd "$SRC_DIR"
    ./configure --prefix="$PREFIX" \
        --with-udev-rules-dir="$PREFIX/etc/udev" \
        --with-crond-dir="$PREFIX/etc/crond" \
        --enable-symlink-build \
        --with-systemd-unit-dir="$PREFIX/etc/systemd"
    make -j8
    make install

    tmp_dir="libtune2fs_tmp"
    mkdir -p "$tmp_dir"
    cd "$tmp_dir"

    gcc -DBUILD_AS_LIB "-I$SRC_DIR/lib" -c "$SRC_DIR/misc/tune2fs.c" "$SRC_DIR/misc/util.c"
    ar rcs libtune2fs.a tune2fs.o util.o
    nm libtune2fs.a | grep tune2fs_main
    cp -av libtune2fs.a "$PREFIX/lib"
}

build_e2fsprogs_linux() {
    apk add gcc musl-dev make libarchive e2fsprogs-static linux-headers git tar zstd

    git clone https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git "$SRC_DIR" -b v1.47.3

    cd "$SRC_DIR"

    CC=gcc \
        CFLAGS="-O2 -fno-pie -fno-plt" \
        CXXFLAGS="-O2 -fno-pie -fno-plt" \
        LDFLAGS="-static -no-pie" ./configure --prefix="$PREFIX" \
        --with-udev-rules-dir="$PREFIX/etc/udev" \
        --with-crond-dir="$PREFIX/etc/crond" \
        --enable-symlink-build \
        --with-systemd-unit-dir="$PREFIX/etc/systemd"
    make -j8
    make install
}

release() {
    cd "$WORKSPACE"
    tar --zstd -cvf "$RELEASE_TAR" -C "$PREFIX" .
}

build() {
    cd "$WORKSPACE"

    if [[ "$PLT" == "Linux" ]]; then
        build_e2fsprogs_linux
    fi

    if [[ "$PLT" == "Darwin" ]]; then
        build_e2fsprogs_darwin
    fi
}

build
release
