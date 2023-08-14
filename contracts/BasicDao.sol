// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IBasicDao } from "contracts/interface/IBasicDao.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";

contract BasicDao is IBasicDao {
    function isUnlocked(bytes32 daoId) public view override returns (bool) {
        return D4AFeePool(payable(ID4AProtocolReadable(address(this)).getDaoFeePool(daoId))).turnover() >= 2 ether;
    }
}
