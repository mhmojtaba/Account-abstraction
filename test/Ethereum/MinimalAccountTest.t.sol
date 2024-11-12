// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "src/Ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployMinimalAccount} from "script/DeployMinimalAccount.s.sol";
import {ERC20Mock} from "openzeppelin-contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
    DeployMinimalAccount public deployer;
    MinimalAccount public minimalAccount;
    HelperConfig public helperConfig;
    ERC20Mock public dai;

    address user = makeAddr("USER");

    uint256 constant AMOUNT = 1e18;

    function setUp() public {
        deployer = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployer.deployMinimalAccount();
        dai = new ERC20Mock();
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
            MinimalAccount.MinimalAccount_Not_From_EntryPoint_or_Owner.selector
        );
        minimalAccount.execute(destination, value, data);
    }
}
