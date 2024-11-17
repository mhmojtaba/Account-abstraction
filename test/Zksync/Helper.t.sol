// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Transaction, MemoryTransactionHelper} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";

// function signTransaction()

function createUnsignedTransaction(
    address from,
    uint8 txType,
    address to,
    uint256 value,
    uint256 nonce,
    bytes memory data
) pure returns (Transaction memory) {
    bytes32[] memory factoryDeps = new bytes32[](0);
    return
        Transaction({
            txType: txType, // transcation type 113 (0x71)
            from: uint256(uint160(from)),
            to: uint256(uint160(to)),
            gasLimit: 16777216,
            gasPerPubdataByteLimit: 16777216,
            maxFeePerGas: 16777216,
            maxPriorityFeePerGas: 16777216,
            paymaster: 0,
            nonce: nonce,
            value: value,
            reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
            data: data,
            signature: hex"",
            factoryDeps: factoryDeps,
            paymasterInput: hex"",
            reservedDynamic: hex""
        });
}
