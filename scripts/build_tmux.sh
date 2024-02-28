#!/bin/sh
set -e
build_dir=~/dev/tmux
tmux_version=3.3
sudo apt-get update
sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config
mkdir $build_dir
git clone https://github.com/tmux/tmux $build_dir
cd $build_dir
git checkout $tmux_version
sh autogen.sh
./configure
make
./tmux -V
sudo cp tmux /usr/bin/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
