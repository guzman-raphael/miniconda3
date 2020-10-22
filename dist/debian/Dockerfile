FROM debian:9.12-slim

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

ARG CONDA_VERSION
ARG PY_LABEL

RUN \
    umask u+rwx,g+rwx,o-rwx && \
    groupadd -r anaconda && \
    apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion && \
    apt-get clean && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${PY_LABEL}${CONDA_VERSION}-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    chown -R root:anaconda /opt && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    # /opt/conda/bin/conda clean -afy
    /opt/conda/bin/conda clean -ay && \
    chmod -R u+rwx,g+rwx,o-rwx /opt/conda/conda-meta

CMD [ "/bin/bash" ]
USER root:anaconda