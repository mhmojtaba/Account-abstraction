// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAINID = 300;
    uint256 constant LOCAL_CHAINNID = 31337;
    address constant BURNER_WALLET = 0x918b0DB5d32b963977a18bD14f1004be80C2D71F;
    address constant FOUNDRY_DEFAULT_ACCOUNT =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainid => NetworkConfig) public networkConfigs;

    address public constant entryPoint =
        0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAINID] = getEthSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainid
    ) public returns (NetworkConfig memory) {
        if (chainid == LOCAL_CHAINNID) {
            return getOrCreateAnvilConfig();
        } else if (networkConfigs[chainid].account != address(0)) {
            return networkConfigs[chainid];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: entryPoint, account: BURNER_WALLET});
    }

    function getZksyncSepoliaConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        // otherwise deploy a mock entrypoint contract
        console2.log("Deploying mock entrypoint contract");
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPointContract = new EntryPoint();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entryPoint: address(entryPointContract),
            account: ANVIL_DEFAULT_ACCOUNT
        });
        return localNetworkConfig;
    }
}
