#!/bin/sh
export PS1="\[\e[32;1m\]\u\[\e[m\]@\[\e[34;1m\]\H\[\e[m\]:\[\e[33;1m\]\w\[\e[m\]$ "
. /opt/conda/etc/profile.d/conda.sh
conda activate
if ! [ $(id -u) = 0 ]; then
    export HOME=/home/$(whoami)
fi
export PATH=$(readlink -f "$HOME")/.local/bin:$PATH