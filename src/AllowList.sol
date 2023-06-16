// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { OwnableRoles } from "solady/auth/OwnableRoles.sol";

import { PROTOCOL_ROLE, OPERATION_ROLE, DAO_ROLE } from "./interfaces/D4AConstants.sol";

contract AllowList is OwnableRoles {
    function initializeAllowList(address owner) public payable {
        _initializeOwner(owner);
    }

    function grantDaoRole(address account) public onlyRoles(PROTOCOL_ROLE | OPERATION_ROLE) {
        _grantRoles(account, DAO_ROLE);
    }

    function protocolRole() public pure returns (uint256) {
        return PROTOCOL_ROLE;
    }

    function operationRole() public pure returns (uint256) {
        return OPERATION_ROLE;
    }

    function daoRole() public pure returns (uint256) {
        return DAO_ROLE;
    }
}
