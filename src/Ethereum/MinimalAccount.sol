// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {MessageHashUtils} from "openzeppelin-contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_SUCCESS, SIG_VALIDATION_FAILED} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    error MinimalAccount__Failed_to_pay_prefund();
    error MinimalAccount__Not_From_EntryPoint();
    error MinimalAccount__Not_From_EntryPoint_or_Owner();
    error MinimalAccount__Failed_to_execute_call(bytes);

    IEntryPoint private immutable i_entryPoint;

    constructor(address enteryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(enteryPoint);
    }

    modifier requiredFromEnteryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__Not_From_EntryPoint();
        }
        _;
    }

    modifier requiredFromEnteryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__Not_From_EntryPoint_or_Owner();
        }
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    function execute(
        address destination,
        uint256 value,
        bytes calldata data
    ) external requiredFromEnteryPointOrOwner {
        (bool success, bytes memory result) = destination.call{value: value}(
            data
        );
        if (!success) {
            revert MinimalAccount__Failed_to_execute_call(result);
        }
    }

    // a signature is valid, if it's MinimalAccount owner
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requiredFromEnteryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        _payPreFund(missingAccountFunds);
    }

    // EIP-191 version of signed hash
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        //    Return the keccak256 digest of an ERC-191 signed data with version `0x45` (`personal_sign` messages).
        bytes32 EthSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            userOpHash
        );
        address signer = ECDSA.recover(EthSignedMessageHash, userOp.signature);

        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        } else {
            return SIG_VALIDATION_SUCCESS;
        }
    }

    function _payPreFund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            (bool ok, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            (ok);
        }
    }

    //                  getters                      //

    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}
