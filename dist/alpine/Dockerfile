# This could be a better upgrade:
# https://github.com/ContinuumIO/docker-images/blob/master/miniconda3/alpine/Dockerfile

FROM alpine:3 as alpine-glibc

LABEL MAINTAINER="Vlad Frolov"
LABEL SRC=https://github.com/frol/docker-alpine-glibc
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# periodically needs to be updated (see above repo)
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.34-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    mv /etc/nsswitch.conf /etc/nsswitch.conf.bak && \
    apk add --no-cache --force-overwrite \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    mv /etc/nsswitch.conf.bak /etc/nsswitch.conf && \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    (/usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true) && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# Temp Image to create exec to allow UID/GID to be updated on boot
FROM golang:alpine as go_tmp
COPY ./utilities/startup.go /startup.go
RUN cd / && go build startup.go

FROM alpine-glibc as miniconda-build

LABEL maintainerName="Raphael Guzman" \
	maintainerEmail="raphael@datajoint.com" \
	maintainerCompany="DataJoint"
ARG CONDA_VER
ARG CONDA_SUFFIX
ARG CONDA_SHA256
ARG PY_LABEL
ARG PY_VER
# Create anaconda group, install dependencies, install Conda
RUN \
	addgroup -S anaconda && \
	export uid=3000 gid=$(awk -F':' '/^anaconda/{print $3}' /etc/group) && \
	mkdir -p /home/anaconda && \
	mkdir /main && \
	chmod g+w /main && \
	echo "anaconda:x:${uid}:${gid}:Developer,,,:/home/anaconda:/bin/sh" >> /etc/passwd && \
	# echo "anaconda:x:${uid}:" >> /etc/group && \
	chown ${uid}:${gid} -R /home/anaconda && \
	chown ${uid}:${gid} -R /main
USER root:anaconda
RUN \
	umask u+rwx,g+rwx,o-rwx && \
	# Add locale config (not related to miniconda3)
	wget -q -O /etc/apk/keys/sgerrand.rsa.pub \
		https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
	wget -q -O /tmp/glibc-i18n-2.25-r0.apk \
		$(echo "https://github.com/sgerrand/alpine-pkg-glibc/releases/download\
			/2.25-r0/glibc-i18n-2.25-r0.apk" | tr -d '\n' | tr -d '\t') && \
	apk add /tmp/glibc-i18n-2.25-r0.apk && \
	rm /tmp/glibc-i18n-2.25-r0.apk && \
	/usr/glibc-compat/bin/localedef -i en_US -c -f UTF-8 en_US.UTF-8 && \
	# Current latest Miniconda3 release
	wget --quiet $(echo "https://repo.anaconda.com/miniconda\
		/Miniconda3-${PY_LABEL}${CONDA_VER}${CONDA_SUFFIX}-Linux-x86_64.sh" | \
		tr -d '\n' | tr -d '\t') && \
	# wget --quiet $(echo "https://repo.continuum.io/miniconda\
	# 	/Miniconda3-${PY_LABEL}${CONDA_VER}${CONDA_SUFFIX}-Linux-x86_64.sh" | \
	# 	tr -d '\n' | tr -d '\t') && \
	mv Miniconda3-${PY_LABEL}${CONDA_VER}${CONDA_SUFFIX}-Linux-x86_64.sh miniconda.sh && \
	mkdir -p /opt && \
	sh ./miniconda.sh -b -p /opt/conda && \
	rm miniconda.sh miniconda.sha256 && \
	ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
	find /opt/conda/ -follow -type f -name '*.a' -delete && \
	find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
	# /opt/conda/bin/conda clean -afy
	opt/conda/bin/conda clean -ay && \
	chown -R root:anaconda /opt/conda/conda-meta && \
	chmod -R u+rwx,g+rwx,o-rwx /opt/conda/conda-meta
USER anaconda:anaconda
ENV PATH /opt/conda/bin:$PATH
COPY ./utilities/shell_intercept.sh  /home/anaconda/.ashrc
ENV ENV "/home/anaconda/.ashrc"
RUN \
	umask u+rwx,g+rwx,o-rwx && \
	conda config --add channels conda-forge && \
	conda config --set auto_update_conda False && \
	[ "${PY_VER}" != "3.11" ] || conda install python=${PY_VER} conda=${CONDA_VER} && \
	# allow gui for gnome apps
	# conda install -yc conda-forge gtk2 && \
	find /opt/conda/conda-meta -user anaconda -exec chmod u+rwx,g+rwx,o-rwx "{}" \; && \
	conda clean -ya

ENV HOME /home/anaconda
ENV APK_REQUIREMENTS /tmp/apk_requirements.txt
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
CMD ["sh"]

# Squashed Final Image
FROM scratch
COPY --from=miniconda-build / /
LABEL maintainerName="Raphael Guzman" \
	maintainerEmail="raphael@datajoint.com" \
	maintainerCompany="DataJoint"
USER anaconda:anaconda
# Add conda to path here for use in downstream dockerfiles
ENV PATH /opt/conda/bin:$PATH
ENV ENV "/home/anaconda/.ashrc"
ENV HOME /home/anaconda
ENV LANG C.UTF-8
ENV APK_REQUIREMENTS /tmp/apk_requirements.txt
ENV PIP_REQUIREMENTS /tmp/pip_requirements.txt
ENV CONDA_REQUIREMENTS /tmp/conda_requirements.txt
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /main
VOLUME /tmp/.X11-unix
CMD ["sh"]