// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";

contract PermissionControlHarness is PermissionControl {
    constructor(address protocol_, address daoProxy_) PermissionControl(protocol_, daoProxy_) { }

    function exposed_verifySignature(
        bytes32 daoId,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        bytes calldata signature
    )
        external
        view
    {
        _verifySignature(daoId, whitelist, blacklist, signature);
    }

    function exposed_blacklisted(bytes32 daoId, address account) external view returns (uint256) {
        return _blacklisted[daoId][account];
    }

    function exposed_addPermission(
        bytes32 daoId,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist
    )
        external
    {
        _addPermission(daoId, whitelist, blacklist);
    }
}
