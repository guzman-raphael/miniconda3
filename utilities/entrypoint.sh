#!/bin/sh
set -e
# Source shell intercept
. $(ls -a ${HOME}/.*ashrc)
# Verify not root
if ! [ $(id -u) = 0 ]; then
	# Install Conda dependencies
	if [ -f "$CONDA_REQUIREMENTS" ]; then
		conda install -yc conda-forge python==$(python -V 2>&1 | awk '{print $2}') \
			--file $CONDA_REQUIREMENTS
		find /opt/conda/conda-meta -user $NEW_USER \
			-exec chmod u+rwx,g+rwx,o-rwx "{}" \;
		conda clean -ya
	fi
	# Install Python dependencies
	if [ -f "$PIP_REQUIREMENTS" ]; then
		pip install -r $PIP_REQUIREMENTS --upgrade --no-cache-dir
	fi
fi
# Run command
[ "$(pwd)" != '/home/anaconda' ] || cd ~
"$@"