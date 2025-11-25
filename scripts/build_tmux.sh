#!/bin/sh
set -e
sudo apt-get update
sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config
tmux_version=3.2
clone_dir=~/dev/tmux
if [ -d "$clone_dir" ]; then
  cd $clone_dir
  git fetch
else
  mkdir -p $clone_dir
  git clone https://github.com/tmux/tmux $clone_dir
fi
cd $clone_dir
git checkout $tmux_version
sh autogen.sh
./configure
make
./tmux -V
sudo cp tmux /usr/bin/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
