#!/bin/bash

BESU_EXECUTABLE="besu"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  BESU_EXECUTABLE="/usr/lib/besu-23.4.1/bin/besu"
fi

RESPONSE=`python generation.py -n 4 -c qbft -al 1~4`

./bootnode.sh --NODE_NAME=Node-1 --LOCAL


./node.sh --CONTAINER_NAME=Node-2 --NODE_NAME=Node-2 --RPC_HTTP_PORT=8555 --RPC_WS_PORT=8556 --P2P_PORT=30313 --LOCAL
./node.sh --CONTAINER_NAME=Node-3 --NODE_NAME=Node-3 --RPC_HTTP_PORT=8565 --RPC_WS_PORT=8566 --P2P_PORT=30323 --LOCAL
./node.sh --CONTAINER_NAME=Node-4 --NODE_NAME=Node-4 --RPC_HTTP_PORT=8575 --RPC_WS_PORT=8576 --P2P_PORT=30333 --LOCAL
