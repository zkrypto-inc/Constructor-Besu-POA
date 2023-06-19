#!/bin/bash

# Default values
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${__dir}/networkFiles/keys"

# Initialize counter
counter=1

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
