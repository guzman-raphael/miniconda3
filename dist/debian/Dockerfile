#Temp Image to create exec to allow UID/GID to be updated on boot
FROM golang:alpine as go_tmp
COPY ./utilities/startup.go /startup.go
RUN cd / && go build startup.go

FROM debian:11-slim as miniconda-build
LABEL maintainerName="Raphael Guzman" \
	maintainerEmail="raphael@datajoint.com" \
	maintainerCompany="DataJoint"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

ARG CONDA_VER
ARG PY_LABEL
ARG PY_VER
# Create anaconda group user, install dependencies, install Conda
RUN \
	groupadd -r anaconda && \
	export uid=3000 gid=$(awk -F':' '/^anaconda/{print $3}' /etc/group) && \
	mkdir -p /home/anaconda && \
	mkdir /main && \
	echo "anaconda:x:${uid}:${gid}:Developer,,,:/home/anaconda:/bin/bash"\
		>> /etc/passwd && \
	# echo "anaconda:x:${uid}:" >> /etc/group && \
	chown ${uid}:${gid} -R /home/anaconda && \
	chown ${uid}:${gid} -R /main
USER root:anaconda
RUN \
	umask u+rwx,g+rwx,o-rwx && \
	# Current latest Miniconda3 release
	apt-get update --fix-missing && \
	apt-get install -y wget bzip2 && \
	# Add locale config (not related to miniconda3)
	apt-get install locales -y && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
	# bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 \
	# 	libxrender1 git mercurial subversion && \
	apt-get clean && \
	# Remove after 4.12.0 version releases
	[ "${CONDA_VER}" != "4.12.0" ] || CONDA_VER="4.11.0" && \
	wget --quiet $(echo "https://repo.anaconda.com/miniconda\
		/Miniconda3-${PY_LABEL}${CONDA_VER}-Linux-$(uname -m).sh" | \
		tr -d "\n" | tr -d "\t") -O ~/miniconda.sh && \
	/bin/bash ~/miniconda.sh -b -p /opt/conda && \
	rm ~/miniconda.sh && \
	/opt/conda/bin/conda clean -tipsy && \
	ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
	find /opt/conda/ -follow -type f -name '*.a' -delete && \
	find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
	# /opt/conda/bin/conda clean -afy
	/opt/conda/bin/conda clean -ay && \
	chown -R root:anaconda /opt/conda/conda-meta && \
	chmod -R u+rwx,g+rwx,o-rwx /opt/conda/conda-meta
USER anaconda:anaconda
ENV PATH /opt/conda/bin:$PATH
COPY ./utilities/shell_intercept.sh  /home/anaconda/.bashrc
RUN \
	umask u+rwx,g+rwx,o-rwx && \
	conda config --add channels conda-forge && \
	conda config --set auto_update_conda False && \
	# Python 3.10 version hack
	[ "${PY_VER}" != "3.1" ] || PY_VER="3.10" && \
	[ "${PY_VER}" != "3.10" ] || conda install python=3.10 conda=4.12.0 && \
	[ "${PY_VER}" != "3.6" ] || sed -i \
		$(echo "s@version_relation_re = re.compile(r'(==|!=|<=|>=|<|>)(?!\[=<>!\])\
			(\S\+)$')@version_relation_re = re.compile(r'(==|!=|<=|>=|<|>|=)\
			(?!\[=<>!\])(\\\S\+)$')@g" | tr -d '\n' | tr -d '\t') \
		/opt/conda/lib/python3.6/site-packages/conda/models/version.py && \
	[ "${PY_VER}" != "3.6" ] || sed -i \
		"s|op.__gt__|op.__gt__, '=': lambda x, y: x.startswith(y)|g" \
		/opt/conda/lib/python${PY_VER}/site-packages/conda/models/version.py && \
	# allow gui for gnome apps
	# conda install -yc conda-forge gtk2 && \
	find /opt/conda/conda-meta -user anaconda -exec chmod u+rwx,g+rwx,o-rwx "{}" \; && \
	conda clean -ya

ENV APT_REQUIREMENTS /tmp/apt_requirements.txt
ENV PIP_REQUIREMENTS /tmp/pip_requirements.txt
ENV CONDA_REQUIREMENTS /tmp/conda_requirements.txt
COPY ./utilities/entrypoint.sh /entrypoint.sh
COPY --from=go_tmp /startup /startup
USER root
RUN \
	chmod +x /entrypoint.sh && \
	chmod 4755 /startup
USER anaconda:anaconda
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /main
VOLUME /tmp/.X11-unix
CMD ["bash"]

# Squashed Final Image
FROM scratch
COPY --from=miniconda-build / /
LABEL maintainerName="Raphael Guzman" \
	maintainerEmail="raphael@datajoint.com" \
	maintainerCompany="DataJoint"
USER anaconda:anaconda
# Add conda to path here for use in downstream dockerfiles
ENV PATH /opt/conda/bin:$PATH
ENV HOME /home/anaconda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV APT_REQUIREMENTS /tmp/apt_requirements.txt
ENV PIP_REQUIREMENTS /tmp/pip_requirements.txt
ENV CONDA_REQUIREMENTS /tmp/conda_requirements.txt
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /main
VOLUME /tmp/.X11-unix
CMD ["bash"]