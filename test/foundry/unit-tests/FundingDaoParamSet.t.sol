// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

        SetDaoParam memory vars;
        vars.daoId = daoId;
        vars.nftMaxSupplyRank = 0;
        vars.remainingRound = 1;
        vars.daoFloorPrice = 0.03 ether;
        vars.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        vars.nftPriceFactor = 1000;
        vars.dailyMintCap = 100;
        vars.unifiedPrice = 1006;
        vars.setChildrenParam = SetChildrenParam(zeroBytes32Array, zeroUintArray, zeroUintArray, 0, 0, 0);
        vars.allRatioParam = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 800, 2000, 7000);

        // 修改MainDAO的参数
        hoax(daoCreator.addr);
        protocol.setDaoParams(vars);

        // 在上面创建的MainDAO基础上创建一个ContinuousDAO
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp + 1));
        param.daoUri = "continuous dao";
        param.existDaoId = daoId; // MainDAO的id
        param.isBasicDao = false; // 不是MainDAO，即为SubDAO
        param.uniPriceModeOff = true;
        param.topUpMode = false;

        bytes32 continuousDaoId = _createDaoForFunding(param, daoCreator2.addr);

        // 用ContinuousDAO创建者的地址尝试修改ContinuousDAO的参数,无法成功追加DAO Token
        vars.daoId = continuousDaoId;
        address daoToken = protocol.getDaoToken(daoId);
        hoax(daoCreator2.addr);
        protocol.setDaoParams(vars);
        assertEq(IERC20(daoToken).balanceOf(protocol.getDaoAssetPool(continuousDaoId)), 0 ether);

        // 用MainDAO创建者的地址尝试修改ContinuousDAO的参数，可以成功追加DAO Token
        // 1.6 已经更改, 只能daoCreator2 修改自己dao的参数, 相应的也不会获得DaoToken
        hoax(daoCreator2.addr);
        protocol.setDaoParams(vars);
        assertEq(IERC20(daoToken).balanceOf(protocol.getDaoAssetPool(continuousDaoId)), 0 ether);
    }
}
