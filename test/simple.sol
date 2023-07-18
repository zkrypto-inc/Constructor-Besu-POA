// SPDX-License-Identifier: MIT
pragma solidity ^0.5.12;

contract simple {
    mapping(string => int) private accounts;
    event vote(uint256[] input);
    // logging uint256 array
    function transfer(uint256[] memory input) public {
        emit vote(input);
    }
    function open(string memory acc_id, int amount) public {
        accounts[acc_id] = amount;
    }

    function query(string memory acc_id) public view returns (int amount) {
        amount = accounts[acc_id];
    }
}