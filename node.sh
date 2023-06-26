#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_NUMBER="Node-1"
CONTAINER_NAME="Node-1"
IP_LOCAL_PORT=5660
ENV_PATH=${__dir}/.env.production

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
        echo "Usage: ./node.sh [OPTIONS]"
        echo "Options:"
        echo "  --CONTAINER_NAME=VALUE     Specify the container name (default: Node-1)"
        echo "  --NODE_NUMBER=VALUE        Specify the node number (default: 1)"
        echo "  --LOCAL_PORT=VALUE      Specify the local port number for JSON-RPC (default: 5660)"
        exit 0
        ;;
        *)
        echo "Error: unexpect argument { $arg }"
        echo "Please check and provide the input in the correct format."
        echo ""
        # Display script usage
        echo "Usage: ./node.sh [OPTIONS]"
        echo "Options:"
        echo "  --CONTAINER_NAME=VALUE     Specify the container name (default: Node-1)"
        echo "  --NODE_NUMBER=VALUE        Specify the node number (default: 1)"
        echo "  --LOCAL_PORT=VALUE      Specify the local port number for JSON-RPC (default: 5660)"
        exit 0
        # ignore unrecognized arguments
        ;;
    esac
done
IP_LOCAL_PORT2=$(($IP_LOCAL_PORT + 1))
IP_LOCAL_PORT3=30303

source ${ENV_PATH}

# check if container name already taken
PRE_CONTAINER_NAME=`docker ps -aqf name=${CONTAINER_NAME}`

if test -n "${PRE_CONTAINER_NAME}"; then
  read -r -p "Container name is already taken. Kill the container? [y/n]" response
  case "$response" in
      [yY][eE][sS]|[yY]) 
          docker stop ${PRE_CONTAINER_NAME}
          docker rm ${PRE_CONTAINER_NAME}
          ;;
      *)
          exit 1
          ;;
  esac
fi


# create node container
docker create --name ${CONTAINER_NAME} \
    -p ${IP_LOCAL_PORT}:8545 \
    -p ${IP_LOCAL_PORT2}:8546 \
    -p ${IP_LOCAL_PORT3}:30303 \
    --net host \
    hyperledger/besu:21.10.9 \
    --genesis-file=/genesis.json \
    --rpc-http-enabled \
    --rpc-http-api=ETH,NET,IBFT \
    --rpc-http-cors-origins="all" \
    --rpc-ws-enabled \
    --rpc-ws-host=0.0.0.0 \
    --rpc-ws-apis=ADMIN,ETH,MINER,WEB3,NET,PRIV,EEA \
    --host-allowlist="*" \
    --bootnodes=${BOOT_NODE_ENODE} \
    --min-gas-price=0

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
