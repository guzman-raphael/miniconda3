# Miniconda3

A minimal base docker image with conda.

# Features

- Provides a minimal docker image with `conda`, `python`, and `pip`.
- As long as internal user is part of `anaconda` group, they should have access to perform `conda` and `pip` operations in the `base` environment (default).
- To properly shell into the image and activate the default environment, should pass `--login` flag. For instance:
```shell
docker exec -it debian_app_1 bash -l || docker exec -it alpine_app_1 sh -l
```

# Launch locally

```shell
docker-compose -f dist/alpine/docker-compose.yml --env-file config/.env up --build
```

OR

```shell
docker-compose -f dist/debian/docker-compose.yml --env-file config/.env up --build
```


# Notes

Heavily borrowed from https://github.com/ContinuumIO/docker-images.

Conda repos
- https://repo.anaconda.com/miniconda/
- https://repo.continuum.io/miniconda/

Compatible conda releases: Miniconda3-%-Linux-x86_64.sh