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
		echo "Assertion failed:  \"$2\""
		echo "File \"$0\", line $lineno"
		exit $E_ASSERT_FAILED
	else
		echo "---------------- TEST[$SHELL_CMD_FLAGS]: $1 ✔️ ----------------"
	fi
}
validate () {
	SHELL_CMD_FLAGS_ORIG=$SHELL_CMD_FLAGS
	# verify proper versions
	assert "conda version" "[ $($SHELL_CMD "conda -V | awk '{print \$2}'") == ${CONDA_VER} ]" $LINENO
	assert "python version" "grep -q .${PY_VER}. <<< .$($SHELL_CMD "python --version 2>&1 | awk '{print \$2}'")" $LINENO
	assert "os version" "$SHELL_CMD 'cat /etc/issue' | grep -qi ${DISTRO}" $LINENO
	# # verify user environment
	assert "username" "[ $($SHELL_CMD "id -u -n") == aneaconda ]" $LINENO
	assert "default group" "[ $($SHELL_CMD "id -g -n") == anaconda ]" $LINENO
	assert "home" "[ $($SHELL_CMD "cd ~ && pwd") == '/home/anaconda' ]" $LINENO
	if [ $PY_VER == '3.6' ]; then
		assert "conda channel priority config" "[ $($SHELL_CMD "conda config --show channel_priority | awk -F': ' '{print \$2}'") == True ]" $LINENO
	else
		assert "conda channel priority config" "[ $($SHELL_CMD "conda config --show channel_priority | awk -F': ' '{print \$2}'") == flexible ]" $LINENO
	fi
	assert "conda default channel" "[ $($SHELL_CMD "conda config --show channels | head -2 | tail -1 | awk -F'- ' '{print \$2}'") == conda-forge ]" $LINENO
	assert "conda disable auto_update" "[ $($SHELL_CMD "conda config --show auto_update_conda | awk -F': ' '{print \$2}'") == False ]" $LINENO
	assert "conda env activated" "[ $($SHELL_CMD "echo \$CONDA_DEFAULT_ENV") == base ]" $LINENO
	assert "set utf8 locale" "[ $($SHELL_CMD "python -c 'print(__import__(\"locale\").setlocale(__import__(\"locale\").LC_ALL, \"en_US.UTF-8\"))'") == 'en_US.UTF-8' ]" $LINENO
	# # verify user installation modes
	TEST_PACKAGE=curl
	TEST_MODULE=beautifulsoup4
	TEST_MODULE_IMPORT=bs4

	assert "pip install" "grep -q /opt/conda/lib/python${PY_VER}/site-packages/ <<< $($SHELL_CMD "pip install --force-reinstall $TEST_MODULE && pip freeze | grep $TEST_MODULE && python -c 'print(__import__(\"$TEST_MODULE_IMPORT\").__file__)'" | tail -1)" $LINENO
	assert "pip user install" "grep -q /home/anaconda/.local/lib/python${PY_VER}/site-packages/ <<< $($SHELL_CMD "pip install --force-reinstall --user $TEST_MODULE && pip freeze | grep $TEST_MODULE && python -c 'print(__import__(\"$TEST_MODULE_IMPORT\").__file__)'" | tail -1)" $LINENO
	assert "conda install" "grep -q /opt/conda/lib/python.*/site-packages/ <<< $($SHELL_CMD "conda install python==\$(python -V 2>&1 | awk '{print \$2}') $TEST_MODULE -y && conda list | grep $TEST_MODULE && python -c 'print(__import__(\"$TEST_MODULE_IMPORT\").__file__)'" | tail -1)" $LINENO

	echo ${TEST_PACKAGE} > /tmp/requirements.txt
	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} -v /tmp/requirements.txt:/tmp/${PACKAGE_MANAGER}_requirements.txt"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "os pkg-manager install" "$SHELL_CMD '$TEST_PACKAGE --version > /dev/null'" $LINENO

	echo ${TEST_MODULE} > /tmp/requirements.txt
	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} -v /tmp/requirements.txt:/tmp/pip_requirements.txt"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "pip install" "grep -q /opt/conda/lib/python${PY_VER}/site-packages/ <<< $($SHELL_CMD "pip freeze | grep $TEST_MODULE && python -c 'print(__import__(\"$TEST_MODULE_IMPORT\").__file__)'" | tail -1)" $LINENO

	SHELL_CMD_FLAGS="${SHELL_CMD_FLAGS_ORIG} -v /tmp/requirements.txt:/tmp/conda_requirements.txt"
	SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
	assert "conda install" "grep -q /opt/conda/lib/python.*/site-packages/ <<< $($SHELL_CMD "conda list | grep $TEST_MODULE && python -c 'print(__import__(\"$TEST_MODULE_IMPORT\").__file__)'" | tail -1)" $LINENO

	rm /tmp/requirements.txt
}
# set image context
REF=$(eval "echo $(cat dist/${DISTRO}/docker-compose.yaml | grep 'image:' | awk '{print $2}')")
TAG=$(echo $REF | awk -F':' '{print $2}')
IMAGE=$(echo $REF | awk -F':' '{print $1}')
SHELL_CMD_TEMPLATE="docker run --rm \$SHELL_CMD_FLAGS $REF $(docker inspect "$REF" --format '{{join .Config.Cmd " "}}') -c"
# determine reference size
if [ $DISTRO == alpine ] && [ $PY_VER == '3.9' ]; then
	SIZE_LIMIT=240
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.8' ]; then
	SIZE_LIMIT=188
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.7' ]; then
	SIZE_LIMIT=196
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.6' ]; then
	SIZE_LIMIT=155
elif [ $DISTRO == debian ] && [ $PY_VER == '3.9' ]; then
	SIZE_LIMIT=311 #481
elif [ $DISTRO == debian ] && [ $PY_VER == '3.8' ]; then
	SIZE_LIMIT=265 #428
elif [ $DISTRO == debian ] && [ $PY_VER == '3.7' ]; then
	SIZE_LIMIT=269 #437
elif [ $DISTRO == debian ] && [ $PY_VER == '3.6' ]; then
	SIZE_LIMIT=228 #396
fi
# verify size minimal
assert "minimal footprint" "(( $(echo "$(docker images --filter "reference=$REF" --format "{{.Size}}" | awk -F'MB' '{print $1}') <= $(echo "scale=4; $SIZE_LIMIT * 1.11" | bc)" | bc -l) ))" $LINENO
# run tests
SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
validate

SHELL_CMD_FLAGS="-u $HOST_UID:anaconda"
SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
validate
