#!/bin/bash

RESPONSE=`besu operator generate-blockchain-config --config-file=ibftConfigFile.json --to=networkFiles --private-key-file-name=key`

./copyKeys.sh

./bootnode.sh --CONTAINER_NAME="boot_node" --NODE_NUMBER=1

./node.sh --CONTAINER_NAME="Node-2" --NODE_NUMBER=2 --LOCAL_PORT=5670
./node.sh --CONTAINER_NAME="Node-3" --NODE_NUMBER=3 --LOCAL_PORT=5680
./node.sh --CONTAINER_NAME="Node-4" --NODE_NUMBER=4 --LOCAL_PORT=5690