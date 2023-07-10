import argparse
import utils



# argparse 객체 생성
parser = argparse.ArgumentParser(description='') #, formatter_class=utils.CustomHelpFormatter

# --number 옵션 추가
parser.add_argument('-n', '--number', type=int, help='generation number of key-pair')

parser.add_argument('-p', '--path', default='.', help='work directory')

# --path 옵션 추가
parser.add_argument('-k', '--key-name', default='accounts.csv', help='key-pair path')

parser.add_argument('-g', '--genesis-name', default='genesis.json', help='genesis.json path')

# --consensus 옵션 추가
parser.add_argument('-c', '--consensus', choices=["clique", "qbft", "ibft2"], help='consensus mode')

# --validator 옵션 추가
parser.add_argument('-v','--validator', help='validator column index. Specify the column index of key-pair file for validators. Example: 1,2,3,4,5 or 1~5')

# --alloc 옵션 추가
parser.add_argument('-al','--alloc', help='allocation column index. Specify the column index of key-pair file for allocation. Example: 1,2,3,4,5 or 1~5')

# --amount
parser.add_argument('-am','--amount', default="ad78ebc5ac6200000", type=lambda x: f"0x{x}", help="allocation amount. Hex string with '0x' prefix.")

# 명령줄 인수 구문 분석
args = parser.parse_args()

# default value
function_name = f'extraData_{args.consensus}'
validator_list = []



# 각 옵션에 따라 작업 수행
if args.number:
    accounts = utils.make_key_pair(args.number)
    # write key-pair to args.path
    utils.write_key_pair(args.path, args.key_name, accounts)

if args.consensus:
    accounts = utils.read_key_pair(args.path, args.key_name)
    utils.rewrite_node_key(args.path, accounts)
    genesis = {
        "config" : {
            "chainId" : 1337,
            "berlinBlock" : 0,
            "contractSizeLimit": 2147483647,
            args.consensus : {
                "blockperiodseconds" : 1,
                "epochlength" : 30000,
                "requesttimeoutseconds" : 4
            }
        },
        "nonce" : "0x0",
        "timestamp" : "0x58ee40ba",
        "gasLimit" : "0x1fffffffffffff",
        "difficulty" : "0x1",
        "mixHash" : "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
        "coinbase" : "0x0000000000000000000000000000000000000000",
    }
    # args.validator 값을 사용하여 작업 수행
    if args.validator:
        validator_list = utils.get_key_pair_list(accounts, args.validator)
    else :
        validator = '1~' + str(len(accounts))
        validator_list = utils.get_key_pair_list(accounts, validator)
    
    if args.alloc:
        allocation_list = utils.get_key_pair_list(accounts, args.alloc)
        genesis = utils.allocation(genesis, allocation_list, args.amount, args.path, args.key_name)
    extraData_func = getattr(utils, function_name)
    encodedData = extraData_func(args.path, args.key_name)
    genesis["extraData"] = encodedData
    utils.write_genesis(args.path, args.genesis_name, genesis)