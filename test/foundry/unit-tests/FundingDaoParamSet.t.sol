// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { PDProtocolSetter } from "contracts/PDProtocolSetter.sol";
import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AEnums.sol";
import "forge-std/Test.sol";

contract FundingDaoParamSet is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_setDaoParamsFunding() public {
        bytes32[] memory zeroBytes32Array = new bytes32[](0);
        uint256[] memory zeroUintArray = new uint256[](0);

        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        SetDaoParamFunding memory vars;
        vars.daoId = daoId;
        vars.nftMaxSupplyRank = 0;
        vars.mintableRoundRank = 1;
        vars.daoFloorPriceRank = 2;
        vars.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        vars.nftPriceFactor = 1000;
        vars.dailyMintCap = 100;
        vars.initialTokenSupply = 1 ether;
        vars.unifiedPrice = 1006;
        vars.setChildrenParam = SetChildrenParam(zeroBytes32Array, zeroUintArray, zeroUintArray, 0, 0, 0);
        vars.allRatioForFundingParam =
            AllRatioForFundingParam(750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 800, 2000, 7000);

        // 修改MainDAO的参数
        hoax(daoCreator.addr);
        protocol.setDaoParamsFunding(vars);

        // 在上面创建的MainDAO基础上创建一个ContinuousDAO
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp + 1));
        param.daoUri = "continuous dao";
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        bytes32 continuousDaoId = _createDaoForFunding(param, daoCreator2.addr);

        // 修改ContinuousDAO的参数
        // PDProtocolSetter pdProtocolSetter = new PDProtocolSetter();
        // vm.prank(daoCreator.addr);
        // pdProtocolSetter.setDaoParamsFunding(vars);
    }
}