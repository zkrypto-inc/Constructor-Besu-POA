#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_NUMBER="Node-1"
CONTAINER_NAME="Node-1"
IP_LOCAL_PORT=5660

# parse command-line arguments
for arg in "$@"
do
    case $arg in
        --CONTAINER_NAME=*)
        CONTAINER_NAME="${arg#*=}"
        ;;
        --NODE_NUMBER=*)
        NODE_NUMBER="Node-${arg#*=}"
        ;;
        --LOCAL_PORT=*)
        IP_LOCAL_PORT="${arg#*=}"
        ;;
        --help)
        # Display script usage
        echo "Usage: bootnode.sh [OPTIONS]"
        echo "Options:"
        echo "  --CONTAINER_NAME=VALUE     Specify the container name (default: Node-1)"
        echo "  --NODE_NUMBER=VALUE        Specify the node number (default: Node-1)"
        echo "  --LOCAL_PORT=VALUE      Specify the local port number for JSON-RPC (default: 5660)"
        exit 0
        ;;
        *)
        # ignore unrecognized arguments
        ;;
    esac
done
IP_LOCAL_PORT2=$(($IP_LOCAL_PORT + 1))
IP_LOCAL_PORT3=$(($IP_LOCAL_PORT + 2))

source ${__dir}/env.defaults

# create node container
docker create --name ${CONTAINER_NAME} -p ${IP_LOCAL_PORT}:8545 -p ${IP_LOCAL_PORT2}:8546 -p ${IP_LOCAL_PORT3}:30303 hyperledger/besu:latest --genesis-file=/genesis.json --rpc-http-enabled --rpc-http-api=ETH,NET,IBFT --host-allowlist="*" --rpc-http-cors-origins="all" --bootnodes=${BOOT_NODE_ENODE}

# setting node container
docker cp ${GENESIS} ${CONTAINER_NAME}:/genesis.json
docker cp ${KEY} ${CONTAINER_NAME}:/opt/besu/key
docker cp ${KEY_PUB} ${CONTAINER_NAME}:/opt/besu/key.pub

# print local port information
echo "Local Port for JSON-RPC: ${IP_LOCAL_PORT}"
echo "Local Port for WebSocket (WS): ${IP_LOCAL_PORT2}"
echo "Local Port for Peer-to-Peer (P2P) communication: ${IP_LOCAL_PORT3}"

# start docker
if docker start ${CONTAINER_NAME}; then
    echo "Successfully start docker container: ${CONTAINER_NAME}"
else
  exit 1
fi