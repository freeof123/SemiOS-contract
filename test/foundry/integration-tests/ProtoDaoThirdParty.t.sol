// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam, SetChildrenParam } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoThirdParty is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    // testcase 1.3-15
    function test_PDCreateFunding_1_3_81() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.thirdPartyToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        address token = protocol.getDaoToken(daoId);
        address pool = protocol.getDaoAssetPool(daoId);
        assertEq(token, address(_testERC20));
        console2.log(_testERC20.balanceOf(address(this)));
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(pool, 10_000);
        //step 6
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(_testERC20.balanceOf(pool), 10_000);
        vm.roll(2);
        deal(daoCreator.addr, 0);
        protocol.claimDaoCreatorReward(daoId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimCanvasReward(canvasId1);
        assertEq(daoCreator.addr.balance, 0);
        assertEq(IERC20(token).balanceOf(daoCreator.addr), 0);
        assertEq(nftMinter.addr.balance, 0);
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 0);
        assertEq(_testERC20.balanceOf(pool), 10_000);
    }

    function test_PDCreateFunding_1_3_82() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.selfRewardRatioERC20 = 10_000;
        param.selfRewardRatioETH = 10_000;
        param.thirdPartyToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        address token = protocol.getDaoToken(daoId);
        address pool = protocol.getDaoAssetPool(daoId);
        assertEq(token, address(_testERC20));
        console2.log(_testERC20.balanceOf(address(this)));
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(pool, 6_000_000);
        //step 6
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        vm.roll(2);

        assertEq(_testERC20.balanceOf(pool), 5_900_000);
        deal(daoCreator.addr, 0);
        protocol.claimDaoCreatorReward(daoId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimCanvasReward(canvasId1);
        assertEq(daoCreator.addr.balance, 0);
        assertEq(IERC20(token).balanceOf(daoCreator.addr), 90_000);
        assertEq(nftMinter.addr.balance, 0);
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 100_000 * 800 / 10_000);
        assertEq(_testERC20.balanceOf(pool), 5_900_000);
    }

    function test_PDCreateFunding_1_3_83() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.isProgressiveJackpot = true;
        param.selfRewardRatioERC20 = 10_000;
        param.selfRewardRatioETH = 10_000;

        param.thirdPartyToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.isProgressiveJackpot = false;
        param.daoUri = "continuous dao uri";

        // param.childrenDaoId = new bytes32[](1);
        // param.childrenDaoId[0] = daoId;
        // // erc20 ratio
        // param.childrenDaoRatiosERC20 = new uint256[](1);
        // param.childrenDaoRatiosERC20[0] = 8000;
        // // eth ratio
        // param.childrenDaoRatiosETH = new uint256[](1);
        // param.childrenDaoRatiosETH[0] = 8000;

        // param.selfRewardRatioETH = 0;
        // param.selfRewardRatioERC20 = 0;

        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);
        SetChildrenParam memory vars;

        vars.childrenDaoId = new bytes32[](1);
        vars.childrenDaoId[0] = daoId2;
        vars.erc20Ratios = new uint256[](1);
        vars.erc20Ratios[0] = 5000;
        vars.ethRatios = new uint256[](1);
        vars.ethRatios[0] = 5000;
        vars.selfRewardRatioERC20 = 5000;
        vars.selfRewardRatioETH = 5000;
        vm.prank(daoCreator.addr);
        protocol.setChildren(daoId, vars);

        address token = protocol.getDaoToken(daoId);
        address pool = protocol.getDaoAssetPool(daoId);
        address pool2 = protocol.getDaoAssetPool(daoId2);

        assertEq(token, address(_testERC20));
        console2.log(_testERC20.balanceOf(address(this)));
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(pool, 6_000_000);

        vm.roll(3);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        //100000 * 3 / 2
        assertEq(_testERC20.balanceOf(pool2), 150_000);
        vm.roll(4);

        deal(daoCreator.addr, 0);
        protocol.claimDaoCreatorReward(daoId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimCanvasReward(canvasId1);
        assertEq(daoCreator.addr.balance, 0);
        assertEq(IERC20(token).balanceOf(daoCreator.addr), 150_000 * 9 / 10);
        assertEq(nftMinter.addr.balance, 0);
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 150_000 * 800 / 10_000);
    }
}

/*
vars.allRatioForFundingParam = AllRatioForFundingParam({
            // l.protocolMintFeeRatioInBps = 250
            // sum = 9750
            // !!! enable when param.uniPriceModeOff = true
            canvasCreatorMintFeeRatio: 750,
            assetPoolMintFeeRatio: 2000,
            redeemPoolMintFeeRatio: 7000,


            // * 1.3 add
            // l.protocolMintFeeRatioInBps = 250
            // sum = 9750
            // !!! enable when param.uniPriceModeOff = false, default is false
            canvasCreatorMintFeeRatioFiatPrice: 250,
            assetPoolMintFeeRatioFiatPrice: 3500,
            redeemPoolMintFeeRatioFiatPrice: 6000,


            // l.protocolERC20RatioInBps = 200
            // sum = 9800
            // !!! ratio for param.selfRewardRatioERC20
            minterERC20RewardRatio: 800,
            canvasCreatorERC20RewardRatio: 2000,
            daoCreatorERC20RewardRatio: 7000,


            // sum = 9800
            // !!! ratio for param.selfRewardRatioETH
            minterETHRewardRatio: 800,
            canvasCreatorETHRewardRatio: 2000,
            daoCreatorETHRewardRatio: 7000
        });
*/
