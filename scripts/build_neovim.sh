#!/bin/sh
set -e
build_dir=~/dev/neovim
version=v0.9.4

if [ -d "$build_dir" ]; then
  cd $build_dir
  git fetch
else
  mkdir -p $build_dir
  git clone https://github.com/neovim/neovim $build_dir
fi

cd $build_dir
git checkout $version
sudo apt-get install ninja-build gettext cmake unzip curl
cmake -S cmake.deps -B .deps -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build .deps
cmake -B build -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
cd build
cpack -G DEB
sudo dpkg -i *.deb
