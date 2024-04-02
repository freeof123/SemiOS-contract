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

contract ProtoDaoRedeemTest is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    function test_circulateERC20Amount() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        bytes32 canvasId2 = param.canvasId;
        param.daoUri = "test dao uri 2";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator.addr);

        SetChildrenParam memory vars;

        vars.childrenDaoId = new bytes32[](1);
        vars.childrenDaoId[0] = daoId2;
        vars.erc20Ratios = new uint256[](1);
        vars.erc20Ratios[0] = 5000;
        vars.ethRatios = new uint256[](1);
        vars.ethRatios[0] = 5000;
        vars.selfRewardRatioERC20 = 5000;
        vars.selfRewardRatioETH = 5000;
        protocol.setChildren(daoId, vars);
        vars.childrenDaoId[0] = daoId;
        //question
        vm.prank(daoCreator.addr);
        protocol.setChildren(daoId2, vars);
        protocol.grantDaoAssetPool(daoId2, 10_000_000 ether, true, "uri");

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
        address token = protocol.getDaoToken(daoId);

        //after mint, dao1 left 45000000, dao2 have 12500000
        super._mintNft(
            daoId2,
            canvasId2,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        vm.roll(2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId2, nftMinter.addr);
        //eth.bal:0.012 ether, circu erc20: 5000000/2+1250000/2 = 3125000 ether
        assertEq(protocol.getDaoFeePool(daoId).balance, 0.012 ether);
        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)), 45_625_000 ether);
        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId2)), 11_250_000 ether);
        assertEq(protocol.getDaoCirculateTokenAmount(daoId), 3_125_000 ether);
        assertEq(protocol.getDaoCirculateTokenAmount(daoId2), 3_125_000 ether);

        vm.prank(nftMinter.addr);
        uint256 ethAmount = protocol.exchangeERC20ToETH(daoId, 100 ether, nftMinter2.addr);
        // 0.012/3125000 = ...384
        assertEq(ethAmount, 384_000_000_000);
        vm.prank(nftMinter.addr);
        ethAmount = protocol.exchangeERC20ToETH(daoId, 100 ether, nftMinter2.addr);
        assertEq(ethAmount, 384_000_000_000);
    }

    function test_InputToken_circulateERC20Amount() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.mintableRound = 10;
        param.inputToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        bytes32 canvasId2 = param.canvasId;
        param.daoUri = "test dao uri 2";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator.addr);

        SetChildrenParam memory vars;

        vars.childrenDaoId = new bytes32[](1);
        vars.childrenDaoId[0] = daoId2;
        vars.erc20Ratios = new uint256[](1);
        vars.erc20Ratios[0] = 5000;
        vars.ethRatios = new uint256[](1);
        vars.ethRatios[0] = 5000;
        vars.selfRewardRatioERC20 = 5000;
        vars.selfRewardRatioETH = 5000;
        protocol.setChildren(daoId, vars);
        vars.childrenDaoId[0] = daoId;
        //question
        vm.prank(daoCreator.addr);
        protocol.setChildren(daoId2, vars);
        protocol.grantDaoAssetPool(daoId2, 10_000_000 ether, true, "uri");

        deal(address(_testERC20), nftMinter.addr, 100 ether);
        vm.prank(nftMinter.addr);
        _testERC20.approve(address(protocol), 0.01 ether);
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
        address token = protocol.getDaoToken(daoId);

        //after mint, dao1 left 45000000, dao2 have 12500000
        vm.prank(nftMinter.addr);
        _testERC20.approve(address(protocol), 0.01 ether);
        super._mintNft(
            daoId2,
            canvasId2,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        vm.roll(2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId2, nftMinter.addr);
        //eth.bal:0.012 ether, circu erc20: 5000000/2+1250000/2 = 3125000 ether
        assertEq(IERC20(_testERC20).balanceOf(protocol.getDaoFeePool(daoId)), 0.012 ether);
        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)), 45_625_000 ether);
        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId2)), 11_250_000 ether);
        assertEq(protocol.getDaoCirculateTokenAmount(daoId), 3_125_000 ether);
        assertEq(protocol.getDaoCirculateTokenAmount(daoId2), 3_125_000 ether);

        vm.prank(nftMinter.addr);
        uint256 ethAmount = protocol.exchangeERC20ToETH(daoId, 100 ether, nftMinter2.addr);
        // 0.012/3125000 = ...384
        assertEq(ethAmount, 384_000_000_000);
        assertEq(IERC20(_testERC20).balanceOf(nftMinter.addr), 100 ether - 0.02 ether);
        assertEq(IERC20(_testERC20).balanceOf(nftMinter2.addr), 384_000_000_000);

        vm.prank(nftMinter.addr);
        ethAmount = protocol.exchangeERC20ToETH(daoId, 100 ether, nftMinter2.addr);
        assertEq(ethAmount, 384_000_000_000);
    }

    // testcase 1.3-15
    function test_PDCreateFunding_1_3_15() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.redeemPoolRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        address token = protocol.getDaoToken(daoId);
        //total
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
        //trigger reward distribution, fee pool bal = 0.01 * 0.35 = 0.0035 ether, distribute 0.0035 ether / 9 to redeem
        // pool
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter2.addr
        );

        vm.roll(3);

        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        //5000000 * minterratio(800) / 10000
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 400_000 ether);
        assertEq(IERC20(token).balanceOf(nftMinter2.addr), 400_000 ether);
        //circulate erc20 = 10000000 ether, available eth = 0.02 ether * 0.6 = 0.012 ether + 0.0035 ether / 9
        vm.prank(nftMinter.addr);
        uint256 a = protocol.exchangeERC20ToETH(daoId, 1 ether, nftMinter.addr);
        assertEq(a, (0.012 ether + 0.0035 ether / uint256(9)) / 10_000_000);

        vm.prank(nftMinter.addr);
        a = protocol.exchangeERC20ToETH(daoId, 1 ether, nftMinter.addr);
        assertEq(a, (0.012 ether + 0.0035 ether / uint256(9)) / 10_000_000);
    }

    receive() external payable { }
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


            // l.protocolERC20RewardRatio = 200
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
