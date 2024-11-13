// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "openzeppelin-contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOps is Script {
    using MessageHashUtils for bytes32;

    function run() public {}

    function generatePackedUserOps(
        bytes memory _callData,
        HelperConfig.NetworkConfig memory config
    ) public view returns (PackedUserOperation memory) {
        // generate unsigned data
        uint256 _nounce = vm.getNonce(config.account);
        PackedUserOperation memory userOp = _generateUnsignedData(
            _callData,
            config.account,
            _nounce
        );

        // get the userop hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(
            userOp
        );
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // sign data and return
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_PRIVATE_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedData(
        bytes memory _callData,
        address _sender,
        uint256 _nounce
    ) internal pure returns (PackedUserOperation memory) {
        // generate unsigned data of PackedUserOperation except signature
        // return PackedUserOperation(sender, nonce, initCode, callData, accountGasLimits, preVerificationGas, gasFees, paymasterAndData)
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return
            PackedUserOperation({
                sender: _sender,
                nonce: _nounce,
                initCode: hex"",
                callData: _callData,
                accountGasLimits: bytes32(
                    (uint256(verificationGasLimit) << 128) | callGasLimit
                ),
                preVerificationGas: verificationGasLimit,
                gasFees: bytes32(
                    (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
                ),
                paymasterAndData: hex"",
                signature: hex""
            });
    }
}

//     address sender;
//     uint256 nonce;
//     bytes initCode;
//     bytes callData;
//     bytes32 accountGasLimits;
//     uint256 preVerificationGas;
//     bytes32 gasFees;
//     bytes paymasterAndData;
//     bytes signature;
