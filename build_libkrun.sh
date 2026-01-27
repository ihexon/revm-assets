#! /usr/bin/env bash
set -xe
PLT=$(uname)
ARCH=$(uname -m)
pwd_c="$(pwd)"

git clone https://github.com/containers/libkrun.git

build_libkrun_dawrin() {
	cd "$pwd_c"
	cd libkrun

	brew tap slp/krun
	brew install virglrenderer lld
	brew info virglrenderer
	make GPU=1 BLK=1 NET=1

}

build_libkrun_linux() {
	cd "$pwd_c"
	cd libkrun

	sudo apt update
	sudo apt install llvm clang libclang-dev
	make BLK=1 NET=1
}

build_libkrun() {
	if [[ "$PLT" == "Linux" ]]; then
		build_libkrun_linux
	fi

	if [[ "$PLT" == "Darwin" ]]; then
		build_libkrun_dawrin
	fi
}


repack_libkrun_source(){
	cd "$pwd_c"
	tar --zstd -cf libkrun-src.tar libkrun/
}


build_libkrun
repack_libkrun_source

