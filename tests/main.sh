#!/bin/bash

assert ()
{
	E_PARAM_ERR=98
	E_ASSERT_FAILED=99

	if [ -z "$3" ]; then
		return $E_PARAM_ERR
	fi

	lineno=$3
	if ! eval "$2"; then
		echo "Assertion ($1) failed:  \"$2\""
		echo "File \"$0\", line $lineno"
		echo "---------------- TEST[$SHELL_CMD_FLAGS]: $1 ❌ ----------------" | \
			tr -d '\t'
		exit $E_ASSERT_FAILED
	else
		echo "---------------- TEST[$SHELL_CMD_FLAGS]: $1 ✅ ----------------" | \
			tr -d '\t'
	fi
}
validate () {
	SHELL_CMD_FLAGS_ORIG=$SHELL_CMD_FLAGS
	# Verify proper versions
	assert "conda version" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		conda -V | awk '{print \$2}'
	END
	) == ${CONDA_VER} ]" $LINENO
	assert "python version" "grep -q .${PY_VER}. <<< .$($SHELL_CMD 'eval "$(cat)"' <<-END
		python --version 2>&1 | awk '{print \$2}'
	END
	)" $LINENO
	assert "os version" "$SHELL_CMD 'cat /etc/issue' | grep -qi ${DISTRO}" $LINENO
	# Verify user environment
	assert "username" "[ $($SHELL_CMD "id -u -n") == anaconda ]" $LINENO
	assert "default group" "[ $($SHELL_CMD "id -g -n") == anaconda ]" $LINENO
	assert "home" "[ $($SHELL_CMD "cd ~ && pwd") == '/home/anaconda' ]" $LINENO
	assert "create in main" "[ $($SHELL_CMD \
		"touch /main/something && echo works") == works ]" $LINENO
	assert "conda channel priority config" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		conda config --show channel_priority | awk -F': ' '{print \$2}'
	END
	) == flexible ]" $LINENO
	assert "conda default channel" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		conda config --show channels | head -2 | tail -1 | awk -F'- ' '{print \$2}'
	END
	) == conda-forge ]" $LINENO
	assert "conda disable auto_update" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		conda config --show auto_update_conda | awk -F': ' '{print \$2}'
	END
	) == False ]" $LINENO
	assert "conda env activated" \
		"[ $($SHELL_CMD "echo \$CONDA_DEFAULT_ENV") == base ]" $LINENO
	assert "set utf8 locale" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		python -c 'print(__import__("locale").setlocale(__import__("locale").LC_ALL,
								"en_US.UTF-8"))'
	END
	) == 'en_US.UTF-8' ]" $LINENO
	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} -e NEW_USER=dja"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "rename user utility" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		id -u -n
	END
	) == 'dja' ]" $LINENO
	assert "home link utility" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		cd ~ && pwd
	END
	) == '/home/dja' ]" $LINENO
	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} -e NEW_HOME=/home/.anaconda \
		--workdir /home/anaconda"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "move home utility" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
		pip --version && readlink ~
	END
	) == '/home/.anaconda' ]" $LINENO
	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} -e NEW_USER=dja --workdir /home/anaconda"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "shell into proper home (change user)" \
		"[ $($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
			pwd
		END
		) == '/home/dja' ]" $LINENO
	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} -e NEW_HOME=/home/.anaconda \
		-e NEW_USER=dja --workdir /home/anaconda"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "shell into proper home (change user+home)" \
		"[ $($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
			pwd
		END
		) == '/home/dja' ]" $LINENO
	# Verify user installation modes
	TEST_PACKAGE=curl
	TEST_MODULE=beautifulsoup4
	TEST_MODULE_IMPORT=bs4

	assert "pip install" "grep -q /opt/conda/lib/python${PY_VER}/site-packages/ <<< \
		$($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
			pip install --force-reinstall $TEST_MODULE && \
			pip freeze | grep $TEST_MODULE && \
			python -c 'print(__import__("$TEST_MODULE_IMPORT").__file__)'
		END
		)" $LINENO
	assert "pip user install" "grep -q \
		/home/dja/.local/lib/python${PY_VER}/site-packages/ <<< \
			$($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
				pip install --force-reinstall --user $TEST_MODULE && \
				pip freeze | grep $TEST_MODULE && \
				python -c 'print(__import__("$TEST_MODULE_IMPORT").__file__)'
			END
			)" $LINENO
	assert "conda install" "grep -q /opt/conda/lib/python${PY_VER}/site-packages/ <<< \
		$($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
			conda install python==\$(python -V 2>&1 | awk '{print \$2}') \
				$TEST_MODULE -y && \
			conda list | grep $TEST_MODULE && \
			python -c 'print(__import__("$TEST_MODULE_IMPORT").__file__)'
		END
		)" $LINENO

	echo ${TEST_PACKAGE} > /tmp/requirements.txt
	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} \
		-v /tmp/requirements.txt:/tmp/${PACKAGE_MANAGER}_requirements.txt"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "os pkg-manager install" \
		"$SHELL_CMD '$TEST_PACKAGE --version > /dev/null'" $LINENO

	echo ${TEST_MODULE} > /tmp/requirements.txt
	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} \
		-v /tmp/requirements.txt:/tmp/pip_requirements.txt"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "pip install" "grep -q /opt/conda/lib/python${PY_VER}/site-packages/ <<< \
		$($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
			pip freeze | grep $TEST_MODULE && \
			python -c 'print(__import__("$TEST_MODULE_IMPORT").__file__)'
		END
		)" $LINENO

	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} \
		-v /tmp/requirements.txt:/tmp/conda_requirements.txt"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "conda install" "grep -q /opt/conda/lib/python${PY_VER}/site-packages/ <<< \
		$($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
			conda list | grep $TEST_MODULE && \
			python -c 'print(__import__("$TEST_MODULE_IMPORT").__file__)'
		END
		)" $LINENO

	rm /tmp/requirements.txt
}
# Set image context
REF=$(eval "echo $(cat dist/${DISTRO}/docker-compose.yaml | grep 'image:' | \
	awk '{print $2}')")
TAG=$(echo $REF | awk -F':' '{print $2}')
IMAGE=$(echo $REF | awk -F':' '{print $1}')
SHELL_CMD_TEMPLATE="docker run --rm -i \$SHELL_CMD_FLAGS $REF \
	$(docker inspect "$REF" --format '{{join .Config.Cmd " "}}') -c"
# Get the compressed size of the last build from docker hub
LAST_BUILD_SIZE=$(curl -s https://hub.docker.com/v2/repositories/$IMAGE/tags \
	| jq -r '.results[] | select(.name=="'"$CONDA_VER"'-py'"$PY_VER"'-'"$DISTRO"'") | .images[0].size')
SIZE_INCRESE_FACTOR=1.5
SIZE_LIMIT=$(echo "scale=4; $LAST_BUILD_SIZE * $SIZE_INCRESE_FACTOR" | bc)
# Verify size minimal
echo Compressing image for size verification...
docker save $REF | gzip > /tmp/$TAG.tar.gz
SIZE=$(ls -al /tmp | grep $TAG.tar.gz | awk '{ print $5 }')
echo -e \
	Size comparison:\\n\
	Current size: $(numfmt --to iec --format "%8.4f" $SIZE)\\n\
	Last build size:  $(numfmt --to iec --format "%8.4f" $LAST_BUILD_SIZE)\\n\
	Size factor: $SIZE_INCRESE_FACTOR\\n\
	Size limit: $(numfmt --to iec --format "%8.4f" $SIZE_LIMIT)
assert "minimal footprint" "(( $(echo "$SIZE <= $SIZE_LIMIT" | bc -l) ))" $LINENO
rm /tmp/$TAG.tar.gz
# Run tests
SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
validate

SHELL_CMD_FLAGS="-u $HOST_UID:anaconda"
SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
validate
