// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

contract EventMock is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_createFundingDao() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 existDaoId = bytes32(0);
        bool isBasicDao = true;
        bool uniPriceModeOff = true;
        bool topUpMode = false;
        //bytes32 daoId = _createDaoForFunding(param, existDaoId, false, uniPriceModeOff, 0, isBasicDao, topUpMode);
    }
}