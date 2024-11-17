// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ZkMinimalAccount} from "src/Zksync/ZkMinimalAccount.sol";
import {Transaction, MemoryTransactionHelper} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {createUnsignedTransaction} from "test/Zksync/Helper.t.sol";
import {ERC20Mock} from "openzeppelin-contracts/mocks/token/ERC20Mock.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "openzeppelin-contracts/utils/cryptography/MessageHashUtils.sol";
import {BOOTLOADER_FORMAL_ADDRESS} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";

contract ZkMinimalTest is Test {
    using MessageHashUtils for bytes32;

    ZkMinimalAccount minimalAccount;
    ERC20Mock public dai;

    address public constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant AMOUNT = 1e18;
    bytes32 constant EMPTY_BYTES = bytes32(0);
    uint256 nonce = vm.getNonce(address(minimalAccount));

    function setUp() public {
        minimalAccount = new ZkMinimalAccount();
        minimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);
        dai = new ERC20Mock();
        vm.deal(address(minimalAccount), AMOUNT);
    }

    function testZkOwnerCanExecute() public {
        // arrange
        address destination = address(dai);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );

        Transaction memory transaction = createUnsignedTransaction(
            minimalAccount.owner(),
            113,
            destination,
            value,
            nonce,
            data
        );
        // act
        vm.prank(minimalAccount.owner());
        minimalAccount.executeTransaction(
            EMPTY_BYTES,
            EMPTY_BYTES,
            transaction
        );
        // assert
        assertEq(dai.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testZkValidateTransaction() public {
        // arrange
        address destination = address(dai);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );

        Transaction memory transaction = createUnsignedTransaction(
            minimalAccount.owner(),
            113,
            destination,
            value,
            nonce,
            data
        );
        transaction = signTransaction(transaction);
        // act
        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic = minimalAccount.validateTransaction(
            EMPTY_BYTES,
            EMPTY_BYTES,
            transaction
        );
        // assert
        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC);
    }

    /**helper */
    function signTransaction(
        Transaction memory transaction
    ) internal view returns (Transaction memory) {
        bytes32 resultHash = MemoryTransactionHelper.encodeHash(transaction);
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        (v, r, s) = vm.sign(ANVIL_DEFAULT_PRIVATE_KEY, resultHash);
        Transaction memory signedTransaction = transaction;
        signedTransaction.signature = abi.encodePacked(r, s, v);
        return signedTransaction;
    }
}
