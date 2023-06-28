// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { UserMintCapParam } from "contracts/interface/D4AStructs.sol";

import { D4ACreateProjectProxy } from "contracts/proxy/D4ACreateProjectProxy.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";

contract D4ACreateProjectProxyHarness is D4ACreateProjectProxy {
    constructor(address WETH_) D4ACreateProjectProxy(WETH_) { }

    function exposed_setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        IPermissionControl.Whitelist calldata whitelist,
        IPermissionControl.Blacklist calldata blacklist,
        IPermissionControl.Blacklist memory unblacklist
    )
        public
    {
        _setMintCapAndPermission(daoId, daoMintCap, userMintCapParams, whitelist, blacklist, unblacklist);
    }

    function exposed_addPermission(
        bytes32 daoId,
        IPermissionControl.Whitelist calldata whitelist,
        IPermissionControl.Blacklist calldata blacklist
    )
        public
    {
        _addPermission(daoId, whitelist, blacklist);
    }

    function exposed_createSplitter(bytes32 daoId) public returns (address splitter) {
        return _createSplitter(daoId);
    }
}
