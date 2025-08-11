// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ZkSyncMinimalAccount} from "../../src/zkSync/ZkSyncMinimalAccount.sol";
import {Transaction} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "../../script/SendPackedUserOp.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
// import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
// import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract ZkSyncMinimalAccountTest is Test {
    ZkSyncMinimalAccount public zkSyncMinimalAccount;
    ERC20Mock public usdc;
    bytes32 constant EMPTY_BTYES32 = bytes32(0);
    uint256 constant AMOUNT = 1e18;

    function setUp() public {
        zkSyncMinimalAccount = new ZkSyncMinimalAccount();
        usdc = new ERC20Mock();
    }

    function test_OwnerCanExecuteCommands() public {
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

    function test_NonOwnerReverts() public {
        // // Arrange
        // assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        // address dest = address(usdc);
        // uint256 value = 0;
        // bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // // Act
        // vm.expectRevert(abi.encodeWithSelector(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector));
        // vm.prank(unknown);
        // minimalAccount.execute(dest, value, functionData);
    }

    function test_RecoverSignedOp() public {
        // // Arrange
        // assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        // address dest = address(usdc);
        // uint256 value = 0;
        // bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // bytes memory executeCalldata =
        //     abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        // PackedUserOperation memory packedUserOp =
        //     sendPackedUserOp.generateSignedUserOperation(executeCalldata, config.getConfig(), address(minimalAccount));
        // bytes32 userOperationHash = IEntryPoint(config.getConfig().entryPoint).getUserOpHash(packedUserOp);
        // // Act
        // address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);
        // // Assert
        // assertEq(actualSigner, minimalAccount.owner());
    }

    function test_ValidationOfUserOps() public {
        // // Arrange
        // assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        // address dest = address(usdc);
        // uint256 value = 0;
        // bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // bytes memory executeCalldata =
        //     abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        // PackedUserOperation memory packedUserOp =
        //     sendPackedUserOp.generateSignedUserOperation(executeCalldata, config.getConfig(), address(minimalAccount));
        // bytes32 userOperationHash = IEntryPoint(config.getConfig().entryPoint).getUserOpHash(packedUserOp);
        // uint256 missingAccountFunds = 1e18;
        // // Act
        // vm.prank(config.getConfig().entryPoint);
        // uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);
        // assertEq(validationData, 0);
    }

    function test_EntryPointCanExecute() public {
        // // Arrange
        // assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        // address dest = address(usdc);
        // uint256 value = 0;
        // bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // bytes memory executeCalldata =
        //     abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        // HelperConfig.NetworkConfig memory configData = config.getConfig();
        // // DEBUG: Check the account state before creating UserOp
        // console.log("MinimalAccount address:", address(minimalAccount));
        // console.log("EntryPoint address:", configData.entryPoint);
        // PackedUserOperation memory packedUserOp =
        //     sendPackedUserOp.generateSignedUserOperation(executeCalldata, configData, address(minimalAccount));
        // PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        // ops[0] = packedUserOp;
        // vm.deal(address(minimalAccount), 1e18);
        // // Act
        // console.log("EntryPoint address: ", configData.entryPoint);
        // vm.prank(randomUser);
        // IEntryPoint(configData.entryPoint).handleOps(ops, payable(randomUser));
        // // Assert
        // assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
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
    ) internal returns (Transaction memory transaction) {
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
}
