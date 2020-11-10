FROM alpine:3.11 as alpine-glibc

LABEL MAINTAINER="Vlad Frolov"
LABEL SRC=https://github.com/frol/docker-alpine-glibc
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN eval $'set -e\n\
	ALPINE_GLIBC_BASE_URL=$(echo "https://github.com/sgerrand/alpine-pkg-glibc\
		/releases/download" | tr -d "\n" | tr -d "\t")\n\
	ALPINE_GLIBC_PACKAGE_VERSION="2.28-r0"\n\
	ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk"\n\
	ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk"\n\
	ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk"\n\
	apk add --no-cache --virtual=.build-dependencies wget ca-certificates\n\
	cat <<-EOL > "/etc/apk/keys/sgerrand.rsa.pub"\n\
		-----BEGIN PUBLIC KEY-----\n\
		MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\n\
		y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\n\
		tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\n\
		m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\n\
		KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\n\
		Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\n\
		1QIDAQAB\n\
		-----END PUBLIC KEY-----\n\
	EOL\n\
	wget \
		$(echo "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION\
			/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" | tr -d "\n" | tr -d "\t")\
		$(echo "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION\
			/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" | tr -d "\n" | tr -d "\t")\
		$(echo "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION\
			/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" | tr -d "\n" | tr -d "\t")\n\
	apk add --no-cache \
		"$ALPINE_GLIBC_BASE_PACKAGE_FILENAME"\
		"$ALPINE_GLIBC_BIN_PACKAGE_FILENAME"\
		"$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"\n\
	rm "/etc/apk/keys/sgerrand.rsa.pub"\n\
	/usr/glibc-compat/bin/localedef \
		--force --inputfile POSIX --charmap UTF-8 "$LANG" || true\n\
	echo "export LANG=$LANG" > /etc/profile.d/locale.sh\n\
	apk del glibc-i18n\n\
	rm "/root/.wget-hsts"\n\
	apk del .build-dependencies\n\
	rm \
		"$ALPINE_GLIBC_BASE_PACKAGE_FILENAME"\
		"$ALPINE_GLIBC_BIN_PACKAGE_FILENAME"\
		"$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"\n\
	'

FROM alpine-glibc

LABEL MAINTAINER="Raphael Guzman"
ARG CONDA_VER
ARG CONDA_MD5
ARG PY_LABEL
ARG PY_VER
# Create non-root user, install dependencies, install Conda
RUN \
	umask u+rwx,g+rwx,o-rwx && \
	[ "${PY_VER}" != "3.9" ] || CONDA_VER_UPDATE=$CONDA_VER && \
	# Current latest Miniconda3 release
	[ "${PY_VER}" != "3.9" ] || CONDA_VER=4.8.3 && \
	addgroup -S anaconda && \
	wget --quiet $(echo "https://repo.anaconda.com/miniconda\
		/Miniconda3-${PY_LABEL}${CONDA_VER}-Linux-x86_64.sh" | \
		tr -d '\n' | tr -d '\t') && \
	# wget --quiet $(echo "https://repo.continuum.io/miniconda\
	# 	/Miniconda3-${PY_LABEL}${CONDA_VER}-Linux-x86_64.sh" | \
	# 	tr -d '\n' | tr -d '\t') && \
	echo "${CONDA_MD5}  Miniconda3-${PY_LABEL}${CONDA_VER}-Linux-x86_64.sh" \
		> miniconda.md5 && \
	if [ $(md5sum -c miniconda.md5 | awk '{print $2}') != "OK" ] ; then exit 1; fi && \
	mv Miniconda3-${PY_LABEL}${CONDA_VER}-Linux-x86_64.sh miniconda.sh && \
	mkdir -p /opt && \
	sh ./miniconda.sh -b -p /opt/conda && \
	rm miniconda.sh miniconda.md5 && \
	ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
	chown -R root:anaconda /opt && \
	echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.profile && \
	echo "conda activate base" >> ~/.profile && \
	. /opt/conda/etc/profile.d/conda.sh && \
	conda activate base && \
	conda config --add channels conda-forge && \
	conda config --set auto_update_conda False && \
	[ "${PY_VER}" != "3.9" ] || \
		conda install -yc conda-forge conda=${CONDA_VER_UPDATE} python=${PY_VER} && \
	find /opt/conda/ -follow -type f -name '*.a' -delete && \
	find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
	# /opt/conda/bin/conda clean -afy
	opt/conda/bin/conda clean -ay && \
	chmod -R u+rwx,g+rwx,o-rwx /opt/conda/conda-meta

ENV PATH "/bin:/sbin:/usr/bin"

CMD [ "sh", "--login", "-i" ]
USER root:anaconda