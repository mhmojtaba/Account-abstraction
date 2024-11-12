// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MinimalAccount} from "src/Ethereum/MinimalAccount.sol";

contract DeployMinimalAccount is Script {
    HelperConfig public helperConfig;
    MinimalAccount public minimalAccount;

    function run() public {
        deployMinimalAccount();
    }

    function deployMinimalAccount()
        public
        returns (HelperConfig, MinimalAccount)
    {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address entryPoint = config.entryPoint;
        vm.startBroadcast(config.account);
        minimalAccount = new MinimalAccount(entryPoint);
        minimalAccount.transferOwnership(msg.sender);
        vm.stopBroadcast();
        return (helperConfig, minimalAccount);
    }
}
