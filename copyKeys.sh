#!/bin/bash

# Default values
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${__dir}/networkFiles/keys"

# Copy networkFiles/genesis.json to the current directory
cp networkFiles/genesis.json ./genesis.json

# Find the highest numbered Node directory
highest_node_dir=$(find "${__dir}" -type d -name "Node-*" | sort -r | head -n 1)
echo ${highest_node_dir}
# Extract the highest node number from the directory name
highest_node_num=${highest_node_dir##*-}
echo ${highest_node_num}
# Initialize the counter with the next available number
counter=$((highest_node_num + 1))

# Loop through each subdirectory in KEYS_DIR
for subdirectory in "${KEYS_DIR}"/*; do
  # Extract the hex value from the subdirectory path
  hex_value=$(basename "${subdirectory}")
  echo ${subdirectory}
  echo ${hex_value}
  # Find key.pub file path
  key_pub_file="${subdirectory}/key.pub"
  
  # Create a corresponding Node directory under BASE_DIR with a numbered suffix
  node_dir="${__dir}/Node-${counter}"
  mkdir -p "${node_dir}/data"

  # Copy key.pub file to the Node directory
  cp "${key_pub_file}" "${node_dir}/data"
  
  # Find key file path
  key_file="${subdirectory}/key"

  # Copy key file to the Node directory
  cp "${key_file}" "${node_dir}/data"
  
  # Increment the counter
  ((counter++))
done
