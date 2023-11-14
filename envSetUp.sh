#!/bin/bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_PATH=${__dir}/.env.defaults
ENV_PD_PATH=${__dir}/.env.production
# 배열 초기화
NODE_NAMES=()
BOOT_NODE_ENODES=$(grep "BOOT_NODE_ENODE" "${ENV_PD_PATH}")

# 명령행 인수 처리
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --NODE_NAME)
    NODE_NAMES+=("$2")
    shift
    shift
    ;;
    *)
    echo "Unknown option: $key"
    echo "Usage: ./envSetUp.sh [OPTIONS]"
    echo "Options:"
    echo "  --NODE_NAMES=     Specify the container names (Node-1,Node-2,...)"
    exit 1
    ;;
  esac
done

# 배열 출력
for i in "${!NODE_NAMES[@]}"; do
  echo "Node name: ${NODE_NAMES[$i]}"

done