// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/interface/D4AErrors.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { IBasicDao } from "contracts/interface/IBasicDao.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";

contract BasicDao is IBasicDao {
    function unlock(bytes32 daoId) public {
        if (ableToUnlock(daoId)) revert UnableToUnlock();
        BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked = true;
        emit BasicDaoUnlocked(daoId);
    }

    function ableToUnlock(bytes32 daoId) public view returns (bool) {
        return D4AFeePool(payable(ID4AProtocolReadable(address(this)).getDaoFeePool(daoId))).turnover() < 2 ether;
    }

    function isUnlocked(bytes32 daoId) public view returns (bool) {
        return BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked;
    }
}
