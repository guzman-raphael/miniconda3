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
		exit $E_ASSERT_FAILED
	else
		echo "---------------- TEST[$SHELL_CMD_FLAGS]: $1 ✔️ ----------------" | \
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
	if [ $PY_VER == '3.6' ]; then
		assert "conda channel priority config" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
			conda config --show channel_priority | awk -F': ' '{print \$2}'
		END
		) == True ]" $LINENO
	else
		assert "conda channel priority config" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
			conda config --show channel_priority | awk -F': ' '{print \$2}'
		END
		) == flexible ]" $LINENO
	fi
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
# Determine reference size
if [ $DISTRO == alpine ] && [ $PY_VER == '3.1' ] || [ $PY_VER == '3.10' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=478
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.9' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=240
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.8' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=188
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.7' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=196
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.6' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=155
elif [ $DISTRO == debian ] && [ $PY_VER == '3.1' ] || [ $PY_VER == '3.10' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=572
elif [ $DISTRO == debian ] && [ $PY_VER == '3.9' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=311 #481
elif [ $DISTRO == debian ] && [ $PY_VER == '3.8' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=265 #428
elif [ $DISTRO == debian ] && [ $PY_VER == '3.7' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=269 #437
elif [ $DISTRO == debian ] && [ $PY_VER == '3.6' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=228 #396
elif [ $DISTRO == debian ] && [ $PY_VER == '3.9' ] && [ $PLATFORM == 'linux/arm64' ]; then
	SIZE_LIMIT=505
elif [ $DISTRO == debian ] && [ $PY_VER == '3.8' ] && [ $PLATFORM == 'linux/arm64' ]; then
	SIZE_LIMIT=450
elif [ $DISTRO == debian ] && [ $PY_VER == '3.7' ] && [ $PLATFORM == 'linux/arm64' ]; then
	SIZE_LIMIT=460
fi
SIZE_LIMIT=$(echo "scale=4; $SIZE_LIMIT * 1.17" | bc)
# Verify size minimal
SIZE=$(docker images --filter "reference=$REF" --format "{{.Size}}" | awk -F'MB' '{print $1}')
assert "minimal footprint" "(( $(echo "$SIZE <= $SIZE_LIMIT" | bc -l) ))" $LINENO
# Run tests
SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
validate

SHELL_CMD_FLAGS="-u $HOST_UID:anaconda"
SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
validate
