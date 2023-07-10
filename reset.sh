#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH=${__dir}/.env.production

source ${ENV_PATH}

read -r -p "Are you sure want to reset config? [y/n]" response
case "$response" in
    [yY][eE][sS]|[yY])
        rm -r genesis.json nodeKeys
        docker stop $(docker ps -aqf ancestor=${BESU_IMAGE})
        docker rm $(docker ps -aqf ancestor=${BESU_IMAGE})
        ;;
    *)
        exit 1
        ;;
esac
