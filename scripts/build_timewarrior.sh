#!/bin/sh
set -e
timew_version=v1.9.1
clone_dir=~/dev/timew
if [ -d "$clone_dir" ]; then
  cd $clone_dir
  git fetch
else
  mkdir -p $clone_dir
  git clone --recurse-submodules https://github.com/GothenburgBitFactory/timewarrior $clone_dir
fi
cd $clone_dir
git checkout $timew_version
cmake -DCMAKE_BUILD_TYPE=Release -G Ninja -S . -B build
cmake --build build -j
cd build
sudo ninja install
