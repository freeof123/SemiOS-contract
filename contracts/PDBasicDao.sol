// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { OPERATION_ROLE } from "contracts/interface/D4AConstants.sol";
import "contracts/interface/D4AErrors.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { IPDBasicDao } from "contracts/interface/IPDBasicDao.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";

contract PDBasicDao is IPDBasicDao {
    function unlock(bytes32 daoId) public {
        if (ableToUnlock(daoId)) revert UnableToUnlock();
        BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked = true;
        emit BasicDaoUnlocked(daoId);
    }

    function ableToUnlock(bytes32 daoId) public view returns (bool) {
        return D4AFeePool(payable(ID4AProtocolReadable(address(this)).getDaoFeePool(daoId))).turnover() < 2 ether;
    }

    function getTurnover(bytes32 daoId) public view returns (uint256) {
        return D4AFeePool(payable(ID4AProtocolReadable(address(this)).getDaoFeePool(daoId))).turnover();
    }

    function isUnlocked(bytes32 daoId) public view returns (bool) {
        return BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked;
    }

    function getCanvasIdOfSpecialNft(bytes32 daoId) public view returns (bytes32) {
        return BasicDaoStorage.layout().basicDaoInfos[daoId].canvasIdOfSpecialNft;
    }

    function setSpecialTokenUriPrefix(string memory prefix) public {
        if (!IAccessControl(address(this)).hasRole(OPERATION_ROLE, msg.sender)) revert NotOperationRole();

        BasicDaoStorage.layout().specialTokenUriPrefix = prefix;
    }

    function getSpecialTokenUriPrefix() public view returns (string memory) {
        return BasicDaoStorage.layout().specialTokenUriPrefix;
    }

    function setBasicDaoNftFlatPrice(uint256 price) public {
        if (!IAccessControl(address(this)).hasRole(OPERATION_ROLE, msg.sender)) revert NotOperationRole();

        BasicDaoStorage.layout().basicDaoNftFlatPrice = price;
    }

    function getBasicDaoNftFlatPrice() public view returns (uint256) {
        return BasicDaoStorage.layout().basicDaoNftFlatPrice;
    }
}
