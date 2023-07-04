#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_NAME="Node"
CONTAINER_NAME="Node"

# default ports
RPC_HTTP_PORT=8545
RPC_WS_PORT=$(($RPC_HTTP_PORT + 1))
P2P_PORT=30303

ENV_PATH=${__dir}/.env.production

HOST=false

# parse command-line arguments
for arg in "$@"
do
    case $arg in
        --CONTAINER_NAME=*)
        CONTAINER_NAME="${arg#*=}"
        ;;
        --NODE_NAME=*)
        NODE_NAME="${arg#*=}"
        ;;
        --RPC_HTTP_PORT=*)
        RPC_HTTP_PORT="${arg#*=}"
        ;;
        --RPC_WS_PORT=*)
        RPC_WS_PORT="${arg#*=}"
        ;;
        --P2P_PORT=*)
        P2P_PORT="${arg#*=}"
        ;;
        --HOST)
        HOST=true
        ;;
        --help)
        # Display script usage
        echo "Usage: ./node.sh [OPTIONS]"
        echo "Options:"
        echo "  --CONTAINER_NAME=VALUE     Specify the container name (default: Node)"
        echo "  --NODE_NAME=VALUE          Specify the node name (default: Node)"
        echo "  --RPC_HTTP_PORT=VALUE      Specify the local port number for HTTP JSON-RPC (default: 8545)"
        echo "  --RPC_WS_PORT=VALUE        Specify the local port number for WS JSON-RPC (default: 8546)"
        echo "  --RPC_HTTP_PORT=VALUE      Specify the local port number for P2P (default: 30303)"
        echo "  --HOST                     Run docker container has host network"
        exit 0
        ;;
        *)
        echo "Error: unexpect argument { $arg }"
        echo "Please check and provide the input in the correct format."
        echo ""
        # Display script usage
        echo "Usage: ./node.sh [OPTIONS]"
        echo "Options:"
        echo "  --CONTAINER_NAME=VALUE     Specify the container name (default: Node)"
        echo "  --NODE_NAME=VALUE          Specify the node name (default: Node)"
        echo "  --RPC_HTTP_PORT=VALUE      Specify the local port number for HTTP JSON-RPC (default: 8545)"
        echo "  --RPC_WS_PORT=VALUE        Specify the local port number for WS JSON-RPC (default: 8546)"
        echo "  --RPC_HTTP_PORT=VALUE      Specify the local port number for P2P (default: 30303)"
        echo "  --HOST                     Run docker container has host network"
        exit 0
        # ignore unrecognized arguments
        ;;
    esac
done

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
CMD_DOCKER_CREATE="docker create --name ${CONTAINER_NAME} \
    -p ${RPC_HTTP_PORT}:${RPC_HTTP_PORT} \
    -p ${RPC_WS_PORT}:${RPC_WS_PORT} \
    -p ${P2P_PORT}:${P2P_PORT} "

if [ "${HOST}" = true ]; then
  CMD_DOCKER_CREATE+="--net host "
fi

CMD_DOCKER_CREATE+="${BESU_IMAGE} \
    --genesis-file=/genesis.json \
    --rpc-http-enabled \
    --rpc-http-api=ETH,NET,IBFT \
    --rpc-http-cors-origins="all" \
    --rpc-ws-enabled \
    --rpc-ws-host=0.0.0.0 \
    --rpc-ws-apis=ADMIN,ETH,MINER,WEB3,NET,PRIV,EEA \
    --host-allowlist="*" \
    --bootnodes=${BOOT_NODE_ENODE} \
    --min-gas-price=0"

if eval ${CMD_DOCKER_CREATE}; then
        echo "Successfully create docker container: ${CONTAINER_NAME}"
    else
        echo "Error: Cannot create docker container: ${CONTAINER_NAME}"
fi

# setting node container
docker cp ${GENESIS} ${CONTAINER_NAME}:/genesis.json
docker cp ${KEY} ${CONTAINER_NAME}:/opt/besu/key
docker cp ${KEY_PUB} ${CONTAINER_NAME}:/opt/besu/key.pub

# print local port information
echo "Local Port for JSON-RPC: ${RPC_HTTP_PORT}"
echo "Local Port for WebSocket (WS): ${RPC_WS_PORT}"
echo "Local Port for Peer-to-Peer (P2P) communication: ${P2P_PORT}"

# start docker
if docker start ${CONTAINER_NAME}; then
    echo "Successfully start docker container: ${CONTAINER_NAME}"
else
  exit 1
fi
