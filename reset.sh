#!/bin/bash

read -r -p "Are you sure want to reset config? [y/n]" response
case "$response" in
    [yY][eE][sS]|[yY])
        rm -r genesis.json networkFiles Node-*
        docker stop $(docker ps -aqf ancestor=hyperledger/besu:21.10.9)
        docker rm $(docker ps -aqf ancestor=hyperledger/besu:21.10.9)
        ;;
    *)
        exit 1
        ;;
esac
