#! /usr/bin/env bash
set -xe
PLT=$(uname)
ARCH=$(uname -m)

git clone https://github.com/containers/libkrunfw.git
cd libkrunfw

if [[ "$PLT" == "Linux" ]]; then
	sudo apt-get update
	sudo apt-get install -y make gcc bc bison flex elfutils python3-pyelftools curl patch libelf-dev
	git clean -xfd
	make -j8 kernel.c
else
	echo "please build kernel.c in linux"
	exit 100
fi

if [[ ! -f kernel.c ]]; then
	echo "kernel.c not find, please build kernel.c first"
	exit 100
fi

make

tar --zstd -cvf "libkrunfw-$PLT-$ARCH.tar" $(find . -name "libkrunfw*.so.*")

