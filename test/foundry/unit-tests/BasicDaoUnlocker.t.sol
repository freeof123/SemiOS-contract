// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";

import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import "contracts/interface/D4AStructs.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";

import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { IPDBasicDao } from "contracts/interface/IPDBasicDao.sol";

contract BasicDaoUnlockerTest is Test, DeployHelper {
    bytes32 basicDaoId1;
    bytes32 basicDaoId2;
    address basicDaoFeePool1;
    address basicDaoFeePool2;
    BasicDaoUnlocker public unlocker;
    address public unlockerPROTOCOL;

    function setUp() public {
        setUpEnv();

        DeployHelper.CreateDaoParam memory basicDaoParam1;
        DeployHelper.CreateDaoParam memory basicDaoParam2;

        basicDaoParam1.daoUri = "basic dao1";
        basicDaoParam2.daoUri = "basic dao2";

        basicDaoId1 = _createDao(basicDaoParam1);
        basicDaoId2 = _createDao(basicDaoParam2);

        basicDaoFeePool1 = ID4AProtocolReadable(address(protocol)).getDaoFeePool(basicDaoId1);
        basicDaoFeePool2 = ID4AProtocolReadable(address(protocol)).getDaoFeePool(basicDaoId2);
    }

    // verify  Can't unlock when the turnover <2ETH.
    function test_UnlockStatus() public view { }

    // verify  When the turnover raise to 2ETH,can unlock the DAO.
    function test_CanUnlockAfterRaiseTo2ETH() public { }

    //
}
