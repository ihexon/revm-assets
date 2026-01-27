#! /usr/bin/env bash
set -xe
wget https://busybox.net/downloads/busybox-1.37.0.tar.bz2 --output-document=- | tar -zxv -
cd busybox-1.37.0 && make defconfig && make -j8 && make install