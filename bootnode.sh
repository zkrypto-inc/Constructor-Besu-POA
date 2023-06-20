#!/bin/bash

# default values
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_NUMBER="Node-1"
CONTAINER_NAME="Node-1"
IP_LOCAL_PORT=5660
ENV_PATH=${__dir}/.env.defaults

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

# create boot_node container
docker create --name ${CONTAINER_NAME} -p ${IP_LOCAL_PORT}:8545 -p ${IP_LOCAL_PORT2}:8546 -p ${IP_LOCAL_PORT3}:30303 hyperledger/besu:latest --genesis-file=/genesis.json --rpc-http-enabled --rpc-http-api=ETH,NET,IBFT --host-allowlist="*" --rpc-http-cors-origins="all"

# setting boot_node container
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
sleep 3

# get ENODE KEY
BOOT_NODE_IP=`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ${CONTAINER_NAME}`
BOOT_NODE_KEY_PUB=`cat ${KEY_PUB}`
BOOT_NODE_ENODE=enode://${BOOT_NODE_KEY_PUB:2}@${BOOT_NODE_IP}:30303
echo "Boot Node Enode: ${BOOT_NODE_ENODE}"



# Check if env.defaults file exists and if it contains the BOOT_NODE_ENODE variable
if [[ -f ${ENV_PATH} && -n $(grep "BOOT_NODE_ENODE=" ${ENV_PATH}) ]]; then
  # Update the existing BOOT_NODE_ENODE value
  sed -i '' "s|BOOT_NODE_ENODE=.*|BOOT_NODE_ENODE=${BOOT_NODE_ENODE}|" ${ENV_PATH}
else
  # Check if the last character is a newline character
  if [[ -s ${ENV_PATH} ]] && [[ -z $(tail -c 1 ${ENV_PATH}) ]]; then
    echo "BOOT_NODE_ENODE=${BOOT_NODE_ENODE}" >> "${ENV_PATH}"
  else
    echo -e "\nBOOT_NODE_ENODE=${BOOT_NODE_ENODE}" >> "${ENV_PATH}"
  fi
fi