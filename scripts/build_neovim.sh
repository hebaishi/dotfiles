#!/bin/sh
set -e
clone_dir=~/dev/neovim
version=v0.11.2
build_type=Release

if [ -d "$clone_dir" ]; then
  cd $clone_dir
  git fetch
else
  mkdir -p $clone_dir
  git clone https://github.com/neovim/neovim $clone_dir
fi

cd $clone_dir
git checkout $version
sudo apt-get install ninja-build gettext cmake unzip curl
cmake -S cmake.deps -B .deps -G Ninja -D CMAKE_BUILD_TYPE=$build_type
cmake --build .deps
cmake -B build -G Ninja -D CMAKE_BUILD_TYPE=$build_type
cmake --build build
cd build
cpack -G DEB
sudo dpkg -i *.deb
