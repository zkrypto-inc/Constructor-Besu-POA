#!/bin/bash

# parse command-line arguments
for arg in "$@"
do
    case $arg in
        --heap=*)
        MAX_HEAP_SIZE="${arg#*=}"
        ;;
        --help)
        # Display script usage
        echo "Usage: ./run_all.sh [OPTIONS]"
        echo "Options:"
        echo "  --heap        Specify the maximum heap size for besu (default: 8g)"
        exit 0
        ;;
        *)
        echo "Error: unexpect argument { $arg }"
        echo "Please check and provide the input in the correct format."
        echo ""
        # Display script usage
        echo "Usage: ./run_all.sh [OPTIONS]"
        echo "Options:"
        echo "  --heap        Specify the maximum heap size for besu (default: 8g)"
        exit 0
        # ignore unrecognized arguments
        ;;
    esac
done

if [ -z "${MAX_HEAP_SIZE}" ]; then
  echo "Maximum heap size is not specified, using default: 8g"
  MAX_HEAP_SIZE="8g"
fi

RESPONSE=`python3 generation.py -n 4 -c qbft -al 1~4`

./bootnode.sh --NODE_NAME=Node-1 --LOCAL --MAX_HEAP_SIZE=${MAX_HEAP_SIZE}
./node.sh --CONTAINER_NAME=Node-2 --NODE_NAME=Node-2 --RPC_HTTP_PORT=8555 --RPC_WS_PORT=8556 --P2P_PORT=30313 --LOCAL --MAX_HEAP_SIZE=${MAX_HEAP_SIZE}
./node.sh --CONTAINER_NAME=Node-3 --NODE_NAME=Node-3 --RPC_HTTP_PORT=8565 --RPC_WS_PORT=8566 --P2P_PORT=30323 --LOCAL --MAX_HEAP_SIZE=${MAX_HEAP_SIZE}
./node.sh --CONTAINER_NAME=Node-4 --NODE_NAME=Node-4 --RPC_HTTP_PORT=8575 --RPC_WS_PORT=8576 --P2P_PORT=30333 --LOCAL --MAX_HEAP_SIZE=${MAX_HEAP_SIZE}
