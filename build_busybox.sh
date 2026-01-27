#! /usr/bin/env bash
set -xe

mkdir -p out/tmp

if [[ $(uname -m) == "aarch64" ]]; then
    wget https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/pool/main/b/busybox/busybox-static_1.37.0-4ubuntu1_arm64.deb --output-document=out/busybox.deb
fi

if [[ $(uname -m) == "x86_64" ]]; then
    wget https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main/b/busybox/busybox-static_1.36.1-6ubuntu3.1_amd64.deb --output-document=out/busybox.deb
fi

dpkg -X out/busybox.deb out/tmp

# run busybox for test
./out/tmp/usr/bin/busybox