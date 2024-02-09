#!/bin/sh
tmux_version=3.3
sudo apt-get update
sudo apt-get install -y libncurses-dev libevent-dev build-essential
git clone https://github.com/tmux/tmux
cd tmux
git checkout $tmux_version
sh autogen.sh
./configure
make
./tmux -V
sudo cp tmux /usr/bin/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
