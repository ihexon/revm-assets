#! /usr/bin/env bash
set -xe
PLT=$(uname)
ARCH=$(uname -m)

git clone https://github.com/containers/libkrun.git
cd libkrun

# For macos arm64 variant
if [[ "$PLT" == "Darwin" ]]; then
	brew tap slp/krun
	brew install virglrenderer lld
	brew info virglrenderer
	make GPU=1 BLK=1 NET=1
fi

# For linux variant, disable GPU feature
if [[ "$PLT" == "Linux" ]]; then
	sudo apt update
	sudo apt install llvm clang libclang-dev
	make BLK=1 NET=1
fi

tar --zstd -cvf "libkrun-$PLT-$ARCH.tar" $(find . -name "libkrun*.so.*")
