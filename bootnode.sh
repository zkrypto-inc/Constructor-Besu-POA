#!/bin/bash

# default values
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_NAME="Node-1"
CONTAINER_NAME="BootNode"

# default ports
RPC_HTTP_PORT=8545
RPC_WS_PORT=$(($RPC_HTTP_PORT + 1))
P2P_PORT=30303

ENV_PATH=${__dir}/.env.defaults
ENV_PD_PATH=${__dir}/.env.production

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
        echo "Usage: ./bootnode.sh [OPTIONS]"
        echo "Options:"
        echo "  --CONTAINER_NAME=VALUE     Specify the container name (default: Node-1)"
        echo "  --NODE_NAME=VALUE          Specify the node number (default: BootNode)"
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
        echo "Usage: ./bootnode.sh [OPTIONS]"
        echo "Options:"
        echo "  --CONTAINER_NAME=VALUE     Specify the container name (default: Node-1)"
        echo "  --NODE_NAME=VALUE        Specify the node number (default: Node-1)"
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
          exit 0
          ;;
  esac
fi

# create boot node container
CMD_DOCKER_CREATE="docker create \
    --name ${CONTAINER_NAME} \
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
    --min-gas-price=0"

if eval ${CMD_DOCKER_CREATE}; then
        echo "Successfully create docker container: ${CONTAINER_NAME}"
    else
        echo "Error: Cannot create docker container: ${CONTAINER_NAME}"
        exit 1
fi

# setting boot_node container
docker cp ${GENESIS} ${CONTAINER_NAME}:/genesis.json && \
docker cp ${KEY} ${CONTAINER_NAME}:/opt/besu/key && \
docker cp ${KEY_PUB} ${CONTAINER_NAME}:/opt/besu/key.pub

if [ $? -ne 0 ]; then
  echo "Error: Cannot copy files into container: ${CONTAINER_NAME}"
  exit 2
fi

# print local port information
echo "Local Port for JSON-RPC: ${RPC_HTTP_PORT}"
echo "Local Port for WebSocket (WS): ${RPC_WS_PORT}"
echo "Local Port for Peer-to-Peer (P2P) communication: ${P2P_PORT}"

# start docker
if docker start ${CONTAINER_NAME}; then
  echo "Successfully start docker container: ${CONTAINER_NAME}"
else
  echo "Error: Cannot start docker container: ${CONTAINER_NAME}"
  exit 3
fi
sleep 3

# get ENODE KEY
if [ "${HOST}" = false ]; then
  BOOT_NODE_IP=`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ${CONTAINER_NAME}`
else
  BOOT_NODE_IP=`hostname -I | awk '{print $2}'` # m
  if [ -z "${BOOT_NODE_IP}" ]; then
    read -r -p "Cannot find external IP automatically. Type your IP manually: " BOOT_NODE_IP
  fi
fi

BOOT_NODE_KEY_PUB=`cat ${KEY_PUB}`
BOOT_NODE_ENODE=enode://${BOOT_NODE_KEY_PUB:2}@${BOOT_NODE_IP}:${P2P_PORT}
echo "Boot Node Enode: ${BOOT_NODE_ENODE}"
cp ${ENV_PATH} ${ENV_PD_PATH}

# Check if env.defaults file exists and if it contains the BOOT_NODE_ENODE variable
if [[ -f ${ENV_PD_PATH} && -n $(grep "BOOT_NODE_ENODE=" ${ENV_PD_PATH}) ]]; then
  # Update the existing BOOT_NODE_ENODE value
  sed -i '' "s|BOOT_NODE_ENODE=.*|BOOT_NODE_ENODE=${BOOT_NODE_ENODE}|" ${ENV_PD_PATH}
else
  # Check if the last character is a newline character
  if [[ -s ${ENV_PD_PATH} ]] && [[ -z $(tail -c 1 ${ENV_PD_PATH}) ]]; then
    echo "BOOT_NODE_ENODE=${BOOT_NODE_ENODE}" >> "${ENV_PD_PATH}"
  else
    echo -e "\nBOOT_NODE_ENODE=${BOOT_NODE_ENODE}" >> "${ENV_PD_PATH}"
  fi
fi
