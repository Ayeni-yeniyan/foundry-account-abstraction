// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import {
    ACCOUNT_VALIDATION_SUCCESS_MAGIC,
    IAccount
} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {
    MemoryTransactionHelper,
    Transaction
} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from
    "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {Utils} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/Utils.sol";
import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    DEPLOYER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS
} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract ZkSyncMinimalAccount is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;

    error ZkSyncMinimalAccount__NotEnoughBalanceToPayForTransaction();
    error ZkSyncMinimalAccount__NotFromBootloaderOrOwner();
    error ZkSyncMinimalAccount__NotFromBootloader();
    error ZkSyncMinimalAccount__CallFailed();
    error ZkSyncMinimalAccount__NotAValidTransaction();

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    modifier requireFromBootLoader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert ZkSyncMinimalAccount__NotFromBootloader();
        }
        _;
    }

    modifier requireFromBootLoaderOrOwner() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS && msg.sender != owner()) {
            revert ZkSyncMinimalAccount__NotFromBootloaderOrOwner();
        }
        _;
    }

    function validateTransaction(
        bytes32, /* _txHash */
        bytes32, /*  _suggestedSignedHash */
        Transaction memory _transaction
    ) external payable requireFromBootLoader returns (bytes4 magic) {
        return _validateTransaction(_transaction);
    }

    function executeTransaction(
        bytes32, /* _txHash */
        bytes32, /*  _suggestedSignedHash */
        Transaction memory _transaction
    ) external payable {
        _executeTransaction(_transaction);
    }

    function executeTransactionFromOutside(Transaction memory _transaction) external payable {
        bytes4 transactionValidity = _validateTransaction(_transaction);
        if (transactionValidity == ACCOUNT_VALIDATION_SUCCESS_MAGIC) {
            _executeTransaction(_transaction);
        } else {
            revert ZkSyncMinimalAccount__NotAValidTransaction();
        }
    }

    function payForTransaction(
        bytes32, /* _txHash */
        bytes32, /*  _suggestedSignedHash */
        Transaction memory _transaction
    ) external payable {
        bool success = _transaction.payToTheBootloader();
        if (!success) {
            revert ZkSyncMinimalAccount__NotFromBootloader();
        }
    }

    function prepareForPaymaster(
        bytes32, /* _txHash */
        bytes32, /*  _suggestedSignedHash */
        Transaction memory _transaction
    ) external payable {}

    function _validateTransaction(Transaction memory _transaction) internal  returns (bytes4 magic) {
        uint32 gas=Utils.safeCastToU32( uint32(gasleft()));
        // Increase nonce
        SystemContractsCaller.systemCallWithPropagatedRevert(
           gas,
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );
        // check fee to pay for the transaction
        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        if (totalRequiredBalance > address(this).balance) {
            revert ZkSyncMinimalAccount__NotEnoughBalanceToPayForTransaction();
        }
        bytes32 txHash = _transaction.encodeHash();
        address signer = ECDSA.recover(txHash, _transaction.signature);
        if (signer == owner()) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
    }

    function _executeTransaction(Transaction memory _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint256 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;
        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            SystemContractsCaller.systemCallWithPropagatedRevert(uint32(gasleft()), to, 0, data);
        } else {
            bool success;
            assembly {
                success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }
            if (!success) {
                revert ZkSyncMinimalAccount__CallFailed();
            }
        }
    }
}
