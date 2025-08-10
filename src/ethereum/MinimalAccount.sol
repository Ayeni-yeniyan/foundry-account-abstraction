// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.28;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract MinimalAccount is IAccount, Ownable {
    IEntryPoint private immutable i_entryPoint;
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier entryPointOnly() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    modifier entryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function execute(address dest, uint256 value, bytes calldata functionData) external entryPointOrOwner {
        (bool success, bytes memory returnData) = dest.call{value: value}(functionData);
        if (!success) {
            revert MinimalAccount__CallFailed(returnData);
        }
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        entryPointOnly
        returns (uint256 validationData)
    {
        validationData = _validateUserOp(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSignedMessage = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessage, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
        }
    }
}
