// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { LibString } from "solady/utils/LibString.sol";

import { IDaoFeePoolFactory } from "src/interfaces/IDaoFeePoolFactory.sol";
import { DaoFeePoolUpgradeable } from "src/dao-fee-pool/DaoFeePoolUpgradeable.sol";

contract DaoFeePoolFactory is IDaoFeePoolFactory {
    using ClonesUpgradeable for address;

    DaoFeePoolUpgradeable public implementation;
    address public proxyAdmin;

    constructor() {
        proxyAdmin = address(new ProxyAdmin());
        ProxyAdmin(proxyAdmin).transferOwnership(msg.sender);
        implementation = new DaoFeePoolUpgradeable();
    }

    event NewD4AFeePool(address proxy, address admin);

    function createDaoFeePool(
        uint256 daoIndex,
        address admin,
        address autoTransferer
    )
        public
        returns (address daoFeePool)
    {
        string memory name = string.concat("Asset Pool for DAO4Art Project ", LibString.toString(daoIndex));
        bytes memory data =
            abi.encodeWithSelector(DaoFeePoolUpgradeable.initialize.selector, name, admin, autoTransferer);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(implementation), proxyAdmin, data);
        DaoFeePoolUpgradeable(payable(address(proxy))).changeAdmin(msg.sender);

        emit NewD4AFeePool(address(proxy), proxyAdmin);

        return address(proxy);
    }
}
