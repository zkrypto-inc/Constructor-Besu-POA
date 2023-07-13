# Construct Besu POA
This project covers the process of configuring IBFT (Istanbul BFT) using Hyperledger Besu. Hyperledger Besu is an open-source Ethereum client used for building Ethereum-based and Ethereum-compatible blockchain networks.

For detailed information about Hyperledger Besu, please refer to [here](https://besu.hyperledger.org/en/stable/). The provided link contains comprehensive details about Besu's features, architecture, documentation, and community.
# install besu


## **MacOS**
### Prerequisites
- [Homebrew](https://brew.sh/)
- Java JDK
- python3 library(web3, ecdsa)
```bash
brew install openjdk
pip3 install web3
pip3 install ecdsa
```
### If using Podman instead of Docker Desktop
```
brew install podman
podman machine init -v ${HOME}:${HOME} --cpus [NUMBER] --disk-size [NUMER : GB] --memory [NUMBER : MB]
podman machine start
```

### install besu using Homebrew
```bash
brew tap hyperledger/besu
brew install hyperledger/besu/besu
```
## **Linux / Unix**

### Prerequisites
- [Java JDK 17+](https://www.oracle.com/java/technologies/downloads/)

### Install pip3 and python3 library
```bash
sudo apt install python3-pip
pip3 install web3
pip3 install ecdsa
```

### Install jdk 20.0.1
```bash
wget https://download.oracle.com/java/20/latest/jdk-20_linux-x64_bin.tar.gz && sudo tar -zxvf jdk-20_linux-x64_bin.tar.gz -C /usr/lib/
echo 'export JAVA_HOME=/usr/lib/jdk-20.0.1/' | sudo tee -a /etc/profile && source /etc/profile
```

### Besu setting
```bash
wget https://hyperledger.jfrog.io/hyperledger/besu-binaries/besu/23.4.1/besu-23.4.1.tar.gz && sudo tar -zxvf besu-23.4.1.tar.gz -C /usr/lib/
```

### Bash alias
```bash
echo -e 'alias java="/usr/lib/jdk-20.0.1/bin/java"\nalias javac="/usr/lib/jdk-20.0.1/bin/javac"\nalias besu="/usr/lib/besu-23.4.1/bin/besu"' | sudo tee -a /etc/bashrc && source /etc/bashrc
```

### Install docker
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
### Docker authentication
```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
id
```

If the text printed on the terminal is not similar to the following, relaunch the terminal or log in again.
```
uid=1000(ubuntu) ...,999(docker)
```
### Install from packaged binaries
Download the [Besu packaged binaries](https://github.com/hyperledger/besu/releases).

# Create a private network using QBFT
## Prerequisites
- install [Docker Desktop](https://docs.docker.com/get-docker/)
- download docker image
```bash
docker pull hyperledger/besu:latest
```
- to use another version of besu image, change the line in .env.defaults
```bash
### change here
BESU_IMAGE="hyperledger/besu:21.10.9"
```
### 1. Generate node keys and a genesis file
```bash
python3 generation.py -n 4 -c qbft -al 1~4
```

### 2. Construct IBFT Network in local
```bash
./run_all.sh
```
This script runs all procedures below.


#### 2-1. Start bootnode in local
```bash
./bootnode.sh --CONTAINER_NAME="boot_node" --NODE_NAME=Node-1
```
This generates .env.production file which contains contents of .env.defaults as well as boot node information.  
example:
```bash
BOOT_NODE_ENODE=enode://ddbf969239f2f5d2199856626128d082b03b270544fd4ffa03a30a9de35bdf1719525fc4e4bfc205e9cb32851199f43a1e1b93b48dd12582d9e7fba0fb19529b@172.17.0.2:30303
```

#### 2-2. Start Node-2,3,4 in local
```bash
./node.sh --CONTAINER_NAME="Node-2" --NODE_NAME=Node-2 --RPC_HTTP_PORT=8555 --RPC_WS_PORT=8556 --P2P_PORT=30313 --LOCAL
./node.sh --CONTAINER_NAME="Node-3" --NODE_NAME=Node-3 --RPC_HTTP_PORT=8565 --RPC_WS_PORT=8566 --P2P_PORT=30323 --LOCAL
./node.sh --CONTAINER_NAME="Node-4" --NODE_NAME=Node-4 --RPC_HTTP_PORT=8575 --RPC_WS_PORT=8576 --P2P_PORT=30333 --LOCAL
```

### 3. Construct Network
Run the 'configure_network.sh' script to set up a network with four hosts on the same network.  
Before running the script, make sure to specify your hosts' information in the '.env.network' file.

> **Note.** This script executes commands such as 'sshpass' and 'scp' to transfer configuration files to each host.  
Please note that since sshpass does not automatically generate RSA key fingerprints, the user needs to manually connect to each host at first time.
```bash
### Specify your node's account and password
### example:
### NODE1="account@your.ip.addr"
### NODE1_PWD="password"
NODE2=""
NODE2_PWD=""
NODE3=""
NODE3_PWD=""
NODE4=""
NODE4_PWD=""

### Specify your node directory
### example:
### NODE_DIR="/home/ubuntu/Constructor-Besu-IBFT/"
NODE2_DIR=""
NODE3_DIR=""
NODE4_DIR=""
```

```bash
# Run this script
./configure_network.sh
```

#### 3-1. Start Node-2,3,4 each host
he configuration script launches the boot node (Node-1). To start the remaining nodes, run the following command on each host.
```bash
./node.sh --NODE_NAME=Node-2 # In Node-2
./node.sh --NODE_NAME=Node-3 # In Node-3
./node.sh --NODE_NAME=Node-4 # In Node-4
```

### 4. Reset Network
This script deletes all containers created from the Besu image and removes the associated configuration files (e.g., genesis file, Node directory, ...).  
If you have configured a network across distributed hosts using configure_network.sh, you should execute this step on each host.
```bash
./reset.sh
```

# Test Validator
For more information, see [hyperledger besu doc](https://besu.hyperledger.org/en/stable/private-networks/reference/api/#ibft_getvalidatorsbyblocknumber)

## ibft_proposeValidatorVote
Propose to add or remove a validator with the specified address.

Parameters
- address: string- account address
- proposal: boolean - true to propose adding validator or false to propose removing validator
```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"ibft_proposeValidatorVote","params":["42d4287eac8078828cf5f3486cfe601a275a49a5",true], "id":1}' http://127.0.0.1:[LOCAL_PORT]
```

### ibft_getValidatorsByBlockNumber
Lists the validators defined in the specified block.

Parameters
- blockNumber: string - integer representing a block number or one of the string tags latest, earliest, or pending, as described in Block Parameter
```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"ibft_getValidatorsByBlockNumber","params":["latest"], "id":1}' http://127.0.0.1:[LOCAL_PORT]
```
