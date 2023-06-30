#!/bin/bash

RESPONSE=`besu operator generate-blockchain-config --config-file=ibftConfigFile.json --to=networkFiles --private-key-file-name=key`

./copyKeys.sh

./bootnode.sh --CONTAINER_NAME="boot_node" --NODE_NAME=Node-1

./node.sh --CONTAINER_NAME="Node-2" --NODE_NAME=Node-2 --RPC_HTTP_PORT=8555 --RPC_WS_PORT=8556 --P2P_PORT=30313
./node.sh --CONTAINER_NAME="Node-3" --NODE_NAME=Node-3 --RPC_HTTP_PORT=8565 --RPC_WS_PORT=8566 --P2P_PORT=30323
./node.sh --CONTAINER_NAME="Node-4" --NODE_NAME=Node-4 --RPC_HTTP_PORT=8575 --RPC_WS_PORT=8576 --P2P_PORT=30333
