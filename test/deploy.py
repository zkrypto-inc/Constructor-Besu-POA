from web3 import Web3
import json
import time
# read contract abi, bytecode file
abi_file = open('./abi.abi', mode='r')
bytecode_file = open('bytecode.bin', mode='r')
abi = json.loads(abi_file.read())
bytecode = bytecode_file.read()

# setting defaults values
endpoint_url = 'http://127.0.0.1:8545'
private_key = '0x674345ebd620ed468053871790785be37757a07d41563d126b17789d1f8d51ac'
address = '0x439185D92645C7A912D4C3B50f9aF97cB6e97A84'
function_inputs = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
]

# http connection
w3 = Web3(Web3.HTTPProvider(endpoint_url, request_kwargs={'timeout': 60}))

# Create contract instance
contract = w3.eth.contract(abi=abi, bytecode=bytecode)

# build constructor tx
construct_txn = contract.constructor().build_transaction({
        'from': address,
        'nonce':  w3.eth.get_transaction_count(address),
        'gasPrice': w3.to_wei('0', 'gwei'),
    })

# sign tx with privatekey
tx_create = w3.eth.account.sign_transaction(construct_txn, private_key)

# send tx and wait for receipt
tx_hash = w3.eth.send_raw_transaction(tx_create.rawTransaction)
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

print(f'Contract deployed at address: { tx_receipt.contractAddress }')



# send transfer function to blockchain
deployed_contract = w3.eth.contract(address=tx_receipt.contractAddress, abi=abi, bytecode=bytecode)
print(deployed_contract)
transfer_txn = deployed_contract.functions.transfer(function_inputs).build_transaction({
        'from': address,
        'nonce': w3.eth.get_transaction_count(address),
        'gasPrice': w3.to_wei('0', 'gwei'),
    })

tx_create = w3.eth.account.sign_transaction(transfer_txn, private_key)

# send tx and wait for receipt
tx_hash = w3.eth.send_raw_transaction(tx_create.rawTransaction)
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

print(f'transaction receipt: { tx_receipt }')