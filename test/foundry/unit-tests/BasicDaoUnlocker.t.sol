// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import "contracts/interface/D4AStructs.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";

import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { IPDBasicDao } from "contracts/interface/IPDBasicDao.sol";

import "contracts/interface/D4AEnums.sol";

contract BasicDaoUnlockerTest is Test, DeployHelper {
    bytes32 basicDaoId1;
    bytes32 basicDaoId2;

    D4AFeePool basicDaoFeePool1;
    D4AFeePool basicDaoFeePool2;
    address basicDaoFeePoolAddress1;
    address basicDaoFeePoolAddress2;
    address payable basicDaoFeePoolAddress1Payable;
    address payable basicDaoFeePoolAddress2Payable;

    BasicDaoUnlocker public unlocker;

    bool upkeepNeeded;
    bytes performData;

    event emitDaoId(bytes32 daoId);

    function setUp() public {
        setUpEnv();

        DeployHelper.CreateDaoParam memory basicDaoParam1;
        DeployHelper.CreateDaoParam memory basicDaoParam2;

        basicDaoParam1.daoUri = "basic dao1";
        basicDaoParam1.canvasId = "canvas1";
        basicDaoParam2.daoUri = "basic dao2";
        basicDaoParam2.canvasId = "canvas2";

        basicDaoId1 = _createBasicDao(basicDaoParam1);
        basicDaoId2 = _createBasicDao(basicDaoParam2);

        basicDaoFeePoolAddress1 = protocol.getDaoFeePool(basicDaoId1);
        basicDaoFeePoolAddress2 = protocol.getDaoFeePool(basicDaoId2);
        basicDaoFeePoolAddress1Payable = payable(basicDaoFeePoolAddress1);
        basicDaoFeePoolAddress2Payable = payable(basicDaoFeePoolAddress2);

        basicDaoFeePool1 = D4AFeePool(basicDaoFeePoolAddress1Payable);
        basicDaoFeePool2 = D4AFeePool(basicDaoFeePoolAddress2Payable);

        unlocker = new BasicDaoUnlocker(address(protocol));
    }

    function test_UnlockStatus() public {
        (bool success1,) = basicDaoFeePoolAddress1.call{ value: 3 ether }("");
        (bool success2,) = basicDaoFeePoolAddress2.call{ value: 1 ether }("");
        require(success1, "Failed to increase turnover");
        require(success2, "Failed to increase turnover");

        (upkeepNeeded, performData) = unlocker.checkUpkeep("");

        console2.log(upkeepNeeded);
        emit emitDaoId(basicDaoId1);
        emit emitDaoId(basicDaoId2);
        emit emitDaoId(IPDProtocolReadable(protocol).getDaoId(uint8(DaoTag.BASIC_DAO), 0));
        emit emitDaoId(IPDProtocolReadable(protocol).getDaoId(uint8(DaoTag.BASIC_DAO), 1));

        if (upkeepNeeded) {
            unlocker.performUpkeep(performData);
        }
        console2.log("BasicDao1Unlocker:", IPDBasicDao(protocol).ableToUnlock(basicDaoId1));
        console2.log("BasicDao2Unlocker:", IPDBasicDao(protocol).ableToUnlock(basicDaoId2));
    }

    function test_CanUnlockAfterRaiseTo2ETH() public { }

    //
}
