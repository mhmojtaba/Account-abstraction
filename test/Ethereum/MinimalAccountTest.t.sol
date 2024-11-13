// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "src/Ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployMinimalAccount} from "script/DeployMinimalAccount.s.sol";
import {ERC20Mock} from "openzeppelin-contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOps, PackedUserOperation} from "script/SendPackedUserOps.s.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "openzeppelin-contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    DeployMinimalAccount public deployer;
    MinimalAccount public minimalAccount;
    HelperConfig public helperConfig;
    ERC20Mock public dai;
    SendPackedUserOps public sendPackedUserOps;

    address user = makeAddr("USER");

    uint256 constant AMOUNT = 10e18;

    function setUp() public {
        deployer = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployer.deployMinimalAccount();
        dai = new ERC20Mock();
        sendPackedUserOps = new SendPackedUserOps();
    }

    function testOwnerCanExecute() public {
        // arrange
        assertEq(dai.balanceOf(address(minimalAccount)), 0);
        console.log(
            "initial balance: ",
            dai.balanceOf(address(minimalAccount))
        );
        address destination = address(dai);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );
        // act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(destination, value, data);
        // assert
        assertEq(dai.balanceOf(address(minimalAccount)), AMOUNT);
        console.log(
            "balance after execute: ",
            dai.balanceOf(address(minimalAccount))
        );
    }

    function testNonOwnerCannotExecute() public {
        // arrange
        assertEq(dai.balanceOf(address(minimalAccount)), 0);
        console.log(
            "initial balance: ",
            dai.balanceOf(address(minimalAccount))
        );
        address destination = address(dai);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );
        // act
        vm.prank(user);
        vm.expectRevert(
            MinimalAccount.MinimalAccount__Not_From_EntryPoint_or_Owner.selector
        );
        minimalAccount.execute(destination, value, data);
    }

    function testRecoverSignedOp() public {
        // arrange
        assertEq(dai.balanceOf(address(minimalAccount)), 0);
        console.log(
            "initial balance: ",
            dai.balanceOf(address(minimalAccount))
        );
        address destination = address(dai);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            destination,
            value,
            data
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOps
            .generatePackedUserOps(executeCallData, helperConfig.getConfig());

        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint)
            .getUserOpHash(packedUserOp);

        // act
        address signer = ECDSA.recover(
            userOpHash.toEthSignedMessageHash(),
            packedUserOp.signature
        );

        // assert
        assertEq(signer, minimalAccount.owner());
    }

    function testValidationOfUserOp() public {
        // sign the userops
        // call validateUserOp
        // assert the return is correct

        // arrange
        assertEq(dai.balanceOf(address(minimalAccount)), 0);
        console.log(
            "initial balance: ",
            dai.balanceOf(address(minimalAccount))
        );
        address destination = address(dai);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(minimalAccount),
            AMOUNT
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            destination,
            value,
            data
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOps
            .generatePackedUserOps(executeCallData, helperConfig.getConfig());

        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint)
            .getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;
        // act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(
            packedUserOp,
            userOpHash,
            missingAccountFunds
        );
        // assert
        assertEq(validationData, 0);
    }
    // function testEntryPointCanExecute() public {}
}
