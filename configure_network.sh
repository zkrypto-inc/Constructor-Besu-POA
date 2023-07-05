#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${__dir}/.env.network

RESPONSE=`/usr/lib/besu-23.4.1/bin/besu operator generate-blockchain-config --config-file=ibftConfigFile.json --to=networkFiles --private-key-file-name=key`

./copyKeys.sh

./bootnode.sh --CONTAINER_NAME="boot_node"

sshpass -p "${NODE2_PWD}" scp -r Node-2 genesis.json .env.production "${NODE2}:${NODE2_DIR}"
sshpass -p "${NODE3_PWD}" scp -r Node-3 genesis.json .env.production "${NODE3}:${NODE3_DIR}"
sshpass -p "${NODE4_PWD}" scp -r Node-4 genesis.json .env.production "${NODE4}:${NODE4_DIR}"

