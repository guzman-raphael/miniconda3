datajoint/miniconda3
####################

| A minimal base docker image with ``conda``.
| For more details, have a look at `prebuilt images <https://hub.docker.com/r/datajoint/miniconda3>`_, `source <https://github.com/datajoint/miniconda3-docker>`_, and `documentation <https://datajoint.github.io/miniconda3-docker>`_.

temp notes...
=============

apk add tk
apt-get install python3-tk -y
conda install -yc conda-forge gtk2
set -a && . config/.env && docker-compose -f dist/${DISTRO}/docker-compose.yaml build && tests/main.sh && set +a

# # rebuild image
# set -o allexport; . config/.env; set +o allexport
# docker-compose -f dist/${DISTRO}/docker-compose.yaml build