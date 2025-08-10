// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
// import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory networkConfig,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        uint256 nonce = IEntryPoint(networkConfig.entryPoint).getNonce(minimalAccount, 0);

        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);
        bytes32 userOpHash = IEntryPoint(networkConfig.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        // sign it
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(networkConfig.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint256 verificationGasLimit = 16777216;
        uint256 callGasLimit = verificationGasLimit;
        uint256 maxPriorityFeePerGas = 256;
        uint256 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32((uint256(verificationGasLimit) << 128) | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32((uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
