#! /usr/bin/env bash
set -xe
PLT=$(uname)
ARCH=$(uname -m)

pwd_c=$(pwd)

build_libkrunfw_linux() {
	cd "$pwd_c"
	sudo apt-get update
	sudo apt-get install -y make gcc bc bison flex elfutils python3-pyelftools curl patch libelf-dev

	git clone https://github.com/containers/libkrunfw.git

	cd libkrunfw
	make -j8
}

build_libkrunfw_darwin() {
	cd "$pwd_c"
	cd libkrunfw

	if [[ ! -f kernel.c ]]; then
		echo "kernel.c not find, please build kernel.c first"
		exit 100
	fi
	make -j8
}

build_libkrunfw() {
	if [[ "$PLT" == "Linux" ]]; then
		build_libkrunfw_linux
	fi

	if [[ "$PLT" == "Darwin" ]]; then
		build_libkrunfw_darwin
	fi
}

repack_libkrunfw_source(){
				cd "$pwd_c"
				tar --zstd -cf libkrunfw-src.tar.zst libkrunfw
}

build_libkrunfw
repack_libkrunfw_source
