#! /usr/bin/env bash
brew tap slp/krun
brew install virglrenderer lld
brew info virglrenderer
git clone https://github.com/containers/libkrun.git
cd libkrun
make GPU=1 BLK=1 NET=1
