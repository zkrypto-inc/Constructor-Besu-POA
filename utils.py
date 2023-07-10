from web3 import Web3
from rlp import encode
from rlp import decode
import csv
import json
import argparse
import os
import ecdsa
import shutil
def read_key_pair(path, key_name):
    file_path = os.path.join(path, key_name)
    result = []
    with open(file_path, 'r') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # 첫 번째 행은 헤더로 건너뛰기
        for row in reader:
            result.append(( remove_prefix(row[0]), remove_prefix(row[1])))
    return result
def make_key_pair(number):
    accounts = []
    w3 = Web3()
    for i in range(number):
        acc = w3.eth.account.create()
        private_key = w3.to_hex(acc._private_key)
        address = acc.address
        accounts.append((private_key, address))
    return accounts

def extraData_qbft(path, key_name):
    csv_file = os.path.join(path, key_name)

    # format https://besu.hyperledger.org/stable/private-networks/how-to/configure/consensus/qbft
    qbft_array = [b'\x00' * 32, [], [], b'', []]

        
    # CSV 파일에서 개인 키 읽기
    with open(csv_file, 'r') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # 첫 번째 행은 헤더로 건너뛰기
        for row in reader:
            private_key_hex = remove_prefix(row[1])  # '0x' 접두사 제거
            qbft_array[1].append(bytes.fromhex(private_key_hex))  # account in 2'th row
    # 개인 키 목록을 RLP 인코딩
    encoded_data = encode(qbft_array)
    return add_prefix(encoded_data.hex())

def extraData_ibft2(path, key_name):
    csv_file = os.path.join(path, key_name)

    # format https://besu.hyperledger.org/23.4.0/private-networks/how-to/configure/consensus/ibft#extra-data
    ibft_array = [b'\x00' * 32, [], b'',b'\x00' * 4, []]
        
    # CSV 파일에서 개인 키 읽기
    with open(csv_file, 'r') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # 첫 번째 행은 헤더로 건너뛰기
        for row in reader:
            private_key_hex = remove_prefix(row[1])  # '0x' 접두사 제거
            ibft_array[1].append(bytes.fromhex(private_key_hex))  # account in 2'th row
    # 개인 키 목록을 RLP 인코딩
    encoded_data = encode(ibft_array)
    return add_prefix(encoded_data.hex())

def extraData_clique(path, key_name):
    csv_file = os.path.join(path, key_name)
    # format https://besu.hyperledger.org/23.4.0/private-networks/tutorials/clique
    clique_extraData = '0x0000000000000000000000000000000000000000000000000000000000000000'
    clique_last = '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
    # CSV 파일에서 개인 키 읽기
    with open(csv_file, 'r') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)  # 첫 번째 행은 헤더로 건너뛰기
        for row in reader:
            private_key_hex = remove_prefix(row[1])
            clique_extraData = clique_extraData + private_key_hex
    return clique_extraData + clique_last


def decode_rlp_hex(encoded_data):
    # 16진수 문자열을 바이트로 변환
    encoded_bytes = bytes.fromhex(encoded_data)

    # RLP 데이터 디코드
    decoded_data = decode(encoded_bytes)

    return decoded_data

def parse_key_pair_list(indexer):
    validator_list = []
    values = indexer.split(',')
    for value in values:
        if '~' in value:
            start, end = value.split('~')
            start = int(start)
            end = int(end)
            validator_list.extend(range(start, end + 1))
        else:
            validator_list.append(int(value))
            validator_list.sort()
    return validator_list

def get_key_pair_list(accounts, indexer):
    result = []
    validator_number = parse_key_pair_list(indexer)
    count = 1
    i = 0
    for row in accounts:
        if count == validator_number[i]:
            i+=1
            result.append({"privateKey": remove_prefix(row[0]), "account": remove_prefix(row[1]), "column": count})
        count+=1
    return result

def write_key_pair(path, key_name, accounts):
    file_path = os.path.join(path, key_name)
    with open(file_path, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Private Key', 'Address'])
        writer.writerows(accounts)

def write_genesis(path, file_name, genesis):
    file_path = os.path.join(path, file_name)

    with open(file_path, 'w') as json_file:
        json.dump(genesis, json_file, indent=4)


def allocation(genesis, allocation_list, balance, path, file_name):
    file_path = os.path.join(path, file_name)
    genesis["alloc"] = {}
    for alloc in allocation_list:
        genesis["alloc"][alloc["account"]] = {
            "privateKey": alloc["privateKey"],
            "comment": f"path: {file_path}, column: {alloc['column']} // private key and this comment are ignored. In a real chain, the private key should NOT be stored.",
            "balance": balance
        }
    return genesis

def rewrite_node_key(path, accounts):
    number = 1
    directory = os.path.join(path, 'nodeKeys')
    os.makedirs(directory, exist_ok=True)
    
    # 기존 파일 삭제
    for filename in os.listdir(directory):
        if os.path.exists(os.path.join(directory, filename)):
            shutil.rmtree(os.path.join(directory, filename))
    # 새로운 파일 생성
    for acc in accounts:
        filepath = os.path.join(directory, 'Node-' + str(number))
        os.makedirs(filepath, exist_ok=True)

        private_key=acc[0]
        # 비밀 키를 바이트열로 변환
        private_key_bytes = bytes.fromhex(private_key)

        # 비밀 키 생성
        private_key_curve = ecdsa.SigningKey.from_string(private_key_bytes, curve=ecdsa.SECP256k1)
        
        # 공개 키 생성
        public_key = private_key_curve.get_verifying_key().to_string().hex()
        with open(os.path.join(filepath, 'key'), 'w', newline='') as key_file:
            key_file.write(add_prefix(acc[0]))
        with open(os.path.join(filepath, 'key.pub'), 'w', newline='') as key_pub_file:
            key_pub_file.write(add_prefix(public_key))
        number += 1

def remove_prefix(hexstring):
    return hexstring[2:]

def add_prefix(hexstring):
    return '0x' + hexstring