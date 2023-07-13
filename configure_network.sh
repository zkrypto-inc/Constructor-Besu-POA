#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${__dir}/.env.network

BESU_EXECUTABLE="besu"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  BESU_EXECUTABLE="/usr/lib/besu-23.4.1/bin/besu"
fi
RESPONSE=`python3 generation.py -n 4 -c qbft -al 1~4`
./bootnode.sh --NODE_NAME=Node-1

sshpass -p "${NODE2_PWD}" scp -r Node-2 genesis.json .env.production "${NODE2}:${NODE2_DIR}"
sshpass -p "${NODE3_PWD}" scp -r Node-3 genesis.json .env.production "${NODE3}:${NODE3_DIR}"
sshpass -p "${NODE4_PWD}" scp -r Node-4 genesis.json .env.production "${NODE4}:${NODE4_DIR}"