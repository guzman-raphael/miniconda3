FROM debian:9.12-slim

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

ARG CONDA_VER
ARG PY_LABEL
ARG PY_VER
# Create non-root user, install dependencies, install Conda
RUN \
	umask u+rwx,g+rwx,o-rwx && \
	[ "${PY_VER}" != "3.9" ] || CONDA_VER_UPDATE=$CONDA_VER && \
	# Current latest Miniconda3 release
	[ "${PY_VER}" != "3.9" ] || CONDA_VER=4.8.3 && \
	groupadd -r anaconda && \
	apt-get update --fix-missing && \
	apt-get install -y wget bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 \
		libxrender1 git mercurial subversion && \
	apt-get clean && \
	wget --quiet $(echo "https://repo.anaconda.com/miniconda\
		/Miniconda3-${PY_LABEL}${CONDA_VER}-Linux-x86_64.sh" | \
		tr -d "\n" | tr -d "\t") -O ~/miniconda.sh && \
	/bin/bash ~/miniconda.sh -b -p /opt/conda && \
	rm ~/miniconda.sh && \
	/opt/conda/bin/conda clean -tipsy && \
	ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
	chown -R root:anaconda /opt && \
	echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
	echo "conda activate base" >> ~/.bashrc && \
	. /opt/conda/etc/profile.d/conda.sh && \
	conda activate base && \
	conda config --add channels conda-forge && \
	conda config --set auto_update_conda False && \
	[ "${PY_VER}" != "3.9" ] || \
		conda install -yc conda-forge conda=${CONDA_VER_UPDATE} python=${PY_VER} && \
	find /opt/conda/ -follow -type f -name '*.a' -delete && \
	find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
	# /opt/conda/bin/conda clean -afy
	/opt/conda/bin/conda clean -ay && \
	chmod -R u+rwx,g+rwx,o-rwx /opt/conda/conda-meta

CMD [ "/bin/bash" ]
USER root:anaconda