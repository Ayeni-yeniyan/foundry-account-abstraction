// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    address public DEFAULT = makeAddr("DEFAULT");
    address public MY_ACCOUNT = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address public ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    //  0x688ce0CCf27a0D0B2b578199ACf3125a1F31f1c0;

    NetworkConfig public localNetworkConfig;

    mapping(uint256 chainId => NetworkConfig config) networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaNetworkConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncNetworkConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilNetworkConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthSepoliaNetworkConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x0576a174D229E3cFA37253523E645A78A0C91B57, account: MY_ACCOUNT});
    }

    function getZkSyncNetworkConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: MY_ACCOUNT});
    }

    function getOrCreateAnvilNetworkConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        } else {
            // Deploy mocks

            EntryPoint mockEntryPoint = new EntryPoint();

            localNetworkConfig = NetworkConfig({entryPoint: address(mockEntryPoint), account: ANVIL_DEFAULT_ACCOUNT});
            return localNetworkConfig;
        }
    }
}
