#!/bin/sh

# Process args
ORIG_USER=$1;shift;
ORIG_HOME=$1;shift;

#Set default permission of new files
umask u+rwx,g+rwx,o-rwx

#Fix UID/GID
/startup -user=$ORIG_USER -new_uid=$(id -u) -new_gid=$(id -g)

#Enable conda paths
. $(ls -a ${ORIG_HOME}/.*ashrc)

#Install Conda dependencies
if [ -f "$CONDA_REQUIREMENTS" ]; then
    conda install -yc conda-forge --file $CONDA_REQUIREMENTS
    conda clean -ya && \
    find /opt/conda/conda-meta -user $ORIG_USER -exec chmod u+rwx,g+rwx,o-rwx "{}" \;
fi

#Install Python dependencies
if [ -f "$PIP_REQUIREMENTS" ]; then
    pip install -r $PIP_REQUIREMENTS --upgrade --no-cache-dir
fi

#Run command
"$@"