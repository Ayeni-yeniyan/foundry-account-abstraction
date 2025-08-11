// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ACCOUNT_VALIDATION_SUCCESS_MAGIC, IAccount} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {ZkSyncMinimalAccount} from "../../src/zkSync/ZkSyncMinimalAccount.sol";
import {BOOTLOADER_FORMAL_ADDRESS} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {Transaction, MemoryTransactionHelper} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract ZkSyncMinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    ZkSyncMinimalAccount public zkSyncMinimalAccount;
    ERC20Mock public usdc;
    bytes32 constant EMPTY_BTYES32 = bytes32(0);
    uint256 constant AMOUNT = 1e18;
    address public unknown = makeAddr("UNKNOWN");
    address public ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        zkSyncMinimalAccount = new ZkSyncMinimalAccount();
        zkSyncMinimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);
        usdc = new ERC20Mock();
        vm.deal(address(zkSyncMinimalAccount),AMOUNT);
    }

    function test_ZkOwnerCanExecuteCommands() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(zkSyncMinimalAccount),
            AMOUNT
        );
        address owner = zkSyncMinimalAccount.owner();
        Transaction memory transaction = _createUnsignedTransaction(
            owner,
            113,
            dest,
            value,
            functionData
        );
        // Act
        vm.prank(owner);
        zkSyncMinimalAccount.executeTransaction(
            EMPTY_BTYES32,
            EMPTY_BTYES32,
            transaction
        );

        // Assert
        assertEq(usdc.balanceOf(address(zkSyncMinimalAccount)), AMOUNT);
    }

    function test_ZkNonOwnerReverts() public {
        // Arrange
        assertEq(usdc.balanceOf(address(zkSyncMinimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(zkSyncMinimalAccount),
            AMOUNT
        );
        Transaction memory transaction = _createUnsignedTransaction(
            unknown,
            113,
            dest,
            value,
            functionData
        );
        // Act
        vm.expectRevert(
            abi.encodeWithSelector(
                ZkSyncMinimalAccount
                    .ZkSyncMinimalAccount__NotFromBootloaderOrOwner
                    .selector
            )
        );
        vm.prank(unknown);
        zkSyncMinimalAccount.executeTransaction(
            EMPTY_BTYES32,
            EMPTY_BTYES32,
            transaction
        );
    }

    function test_ZkValidationTransaction() public {
        // Arrange
        assertEq(usdc.balanceOf(address(zkSyncMinimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        address owner = zkSyncMinimalAccount.owner();
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(zkSyncMinimalAccount),
            AMOUNT
        );
        Transaction memory transaction = _createUnsignedTransaction(
            owner,
            113,
            dest,
            value,
            functionData
        );
        _signTransaction(transaction);
        // Act
        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic=zkSyncMinimalAccount.validateTransaction(
            EMPTY_BTYES32,
            EMPTY_BTYES32,
            transaction);
        // Assert
        assertEq(magic,ACCOUNT_VALIDATION_SUCCESS_MAGIC);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _createUnsignedTransaction(
        address from,
        uint8 transactionType,
        address to,
        uint256 value,
        bytes memory data
    ) internal view returns (Transaction memory transaction) {
        uint256 nonce = vm.getNonce(address(zkSyncMinimalAccount));
        bytes32[] memory factoryDeps = new bytes32[](0);
        transaction = Transaction({
            txType: transactionType,
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

    function _signTransaction(
        Transaction memory transaction
    ) internal view returns (Transaction memory) {
        bytes32 unsigedTransactionHash = MemoryTransactionHelper.encodeHash(
            transaction
        );
        bytes32 digest = unsigedTransactionHash.toEthSignedMessageHash();
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        // sign it
        (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        transaction.signature = abi.encodePacked(r, s, v);
        return transaction;
    }
}
