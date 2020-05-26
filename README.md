# Launch locally


`docker-compose -f dist/alpine/docker-compose.yml --env-file config/.env up --build`
OR
`docker-compose -f dist/debian/docker-compose.yml --env-file config/.env up --build`


# Notes

Heavily borrowed from https://github.com/ContinuumIO/docker-images.

Conda repos
- https://repo.anaconda.com/miniconda/
- https://repo.continuum.io/miniconda/

Compatible conda releases: Miniconda3-%-Linux-x86_64.sh