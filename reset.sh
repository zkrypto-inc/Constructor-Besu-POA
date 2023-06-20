#!/bin/bash

read -r -p "Are you sure want to reset config? [y/n]" response
case "$response" in
    [yY][eE][sS]|[yY])
        rm -r genesis.json networkFiles Node-*
        docker stop $(docker ps -aqf ancestor=hyperledger/besu)
        docker rm $(docker ps -aqf ancestor=hyperledger/besu)
        ;;
    *)
        exit 1
        ;;
esac