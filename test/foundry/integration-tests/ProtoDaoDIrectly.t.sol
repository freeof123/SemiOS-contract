// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam, NftIdentifier } from "contracts/interface/D4AStructs.sol";
import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoTestDirectly is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    function test_PDCreateFunding_createBasicDAO_benchmark() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        uint256 preBalance = daoCreator.addr.balance;

        uint256 flatPrice = 0.01 ether;

        super._mintNftChangeBal(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            flatPrice,
            daoCreator.key,
            daoCreator.addr
        );

        uint256 balanceDiff = preBalance - daoCreator.addr.balance;

        // l.protocolMintFeeRatioInBps = 250
        assertEq(protocol.protocolFeePool().balance, flatPrice * 250 / 10_000);

        // canvasCreatorMintFeeRatioFiatPrice: 250
        assertEq(balanceDiff, flatPrice * (10_000 - 250) / 10_000);

        // assetPoolMintFeeRatioFiatPrice: 3500
        assertEq(protocol.getDaoAssetPool(daoId).balance, flatPrice * 3500 / 10_000);

        // redeemPoolMintFeeRatioFiatPrice: 6000
        assertEq(protocol.getDaoFeePool(daoId).balance, flatPrice * 6000 / 10_000);
    }

    function test_PDCreateFunding_createBasicDAO_OpenUnifiedPriceWithETH() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        uint256 preBalance = daoCreator.addr.balance;

        uint256 flatPrice = 0.01 ether;

        super._mintNftChangeBal(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            flatPrice,
            daoCreator.key,
            daoCreator.addr
        );

        uint256 balanceDiff = preBalance - daoCreator.addr.balance;

        // l.protocolMintFeeRatioInBps = 250
        assertEq(protocol.protocolFeePool().balance, flatPrice * 250 / 10_000);

        // canvasCreatorMintFeeRatioFiatPrice: 250
        assertEq(balanceDiff, flatPrice * (10_000 - 250) / 10_000);

        // assetPoolMintFeeRatioFiatPrice: 3500
        assertEq(protocol.getDaoAssetPool(daoId).balance, flatPrice * 3500 / 10_000);

        // redeemPoolMintFeeRatioFiatPrice: 6000
        assertEq(protocol.getDaoFeePool(daoId).balance, flatPrice * 6000 / 10_000);
    }

    function test_PDCreateFunding_createBasicDAO_OpenUnifiedModeWithZeroETH() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        uint256 preBalance = daoCreator.addr.balance;

        super._mintNftChangeBal(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            daoCreator.addr
        );

        uint256 balanceDiff = preBalance - daoCreator.addr.balance;

        // l.protocolMintFeeRatioInBps = 250
        assertEq(protocol.protocolFeePool().balance, 0.01 ether * 250 / 10_000);

        // canvasCreatorMintFeeRatio: 750
        assertEq(balanceDiff, 0.01 ether * (10_000 - 750) / 10_000);

        // assetPoolMintFeeRatio: 2000
        assertEq(protocol.getDaoAssetPool(daoId).balance, 0.01 ether * 2000 / 10_000);

        // redeemPoolMintFeeRatio: 7000
        assertEq(protocol.getDaoFeePool(daoId).balance, 0.01 ether * 7000 / 10_000);
    }

    //==============================================================================

    function test_PDCreateFunding_createContinuousDAO_benchmark() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        param.daoUri = "continuous dao uri";
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));

        param.isBasicDao = false;
        param.existDaoId = daoId;

        bytes32 subDaoId = super._createDaoForFunding(param, daoCreator2.addr);

        param.daoUri = "continuous dao uri2";
        param.canvasId = keccak256(abi.encode(daoCreator3.addr, block.timestamp));
        bytes32 canvasId3 = param.canvasId;

        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.childrenDaoId = new bytes32[](2);
        param.childrenDaoId[0] = daoId;
        param.childrenDaoId[1] = subDaoId;
        param.childrenDaoRatiosERC20 = new uint256[](2);
        param.childrenDaoRatiosERC20[0] = 4000;
        param.childrenDaoRatiosERC20[1] = 3000;
        param.childrenDaoRatiosETH = new uint256[](2);
        param.childrenDaoRatiosETH[0] = 1000;
        param.childrenDaoRatiosETH[1] = 2000;
        param.redeemPoolRatioETH = 3000;
        param.selfRewardRatioERC20 = 2000;
        param.selfRewardRatioETH = 3500;

        param.noPermission = true;
        param.mintableRound = 10;

        bytes32 subDaoId2 = super._createDaoForFunding(param, daoCreator3.addr);
        hoax(daoCreator.addr);
        protocol.grantDaoAssetPool(subDaoId2, 10_000_000 ether, true, "uri");
        uint256 flatPrice = 0.01 ether;

        super._mintNft(
            subDaoId2,
            canvasId3,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(subDaoId2)), "-", vm.toString(uint256(0)), ".json"
            ),
            flatPrice,
            daoCreator3.key,
            nftMinter.addr
        );

        address assetPool3 = protocol.getDaoAssetPool(subDaoId2);
        address assetPool1 = protocol.getDaoAssetPool(daoId);
        address assetPool2 = protocol.getDaoAssetPool(subDaoId);

        address token = protocol.getDaoToken(subDaoId2);
        assertEq(token, protocol.getDaoToken(daoId));
        assertEq(IERC20(token).balanceOf(assetPool3), 10_000_000 ether - 900_000 ether);
        assertEq(IERC20(token).balanceOf(assetPool1), 50_000_000 ether + 400_000 ether);
        assertEq(IERC20(token).balanceOf(assetPool2), 300_000 ether);
        assertEq(IERC20(token).balanceOf(address(protocol)), 200_000 ether);

        vm.roll(2);
        protocol.claimDaoNftOwnerReward(subDaoId2);
        //1000000 * 20% * 70%
        assertEq(IERC20(token).balanceOf(daoCreator3.addr), 140_000 ether);
        protocol.claimCanvasReward(canvasId3);
        //add 1000000 * 20% * 20%
        assertEq(IERC20(token).balanceOf(daoCreator3.addr), 180_000 ether);
        protocol.claimNftMinterReward(subDaoId2, nftMinter.addr);
        //1000000 * 20% * 8%
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 16_000 ether);
        assertEq(IERC20(token).balanceOf(protocol.protocolFeePool()), 4000 ether);
        assertEq(IERC20(token).balanceOf(address(protocol)), 0);
    }

    function test_PDCreateFunding_BasicOnwerCreaterTwoDaos() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.topUpMode = true;
        param.noPermission = true;
        param.daoUri = "basic dao uri";
        param.mintableRound = 10;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        param.daoUri = "continuous dao uri";
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        param.isBasicDao = false;
        param.existDaoId = daoId;
        console2.log("addr:", daoCreator.addr);
        bytes32 subDaoId = super._createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);

        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)), 50_000_000 ether, "basic dao fail");
        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(subDaoId)), 0 ether, "sub dao fail");
    }

    function test_PDCreateFunding_TopUpAccountShouldNotBeUsedWhenMintInSameRound() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.topUpMode = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
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
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = false;
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.daoUri = "normal dao uri";
        param.mintableRound = 0;

        bytes32 canvasId2 = param.canvasId;
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        //protocol.claimNftMinterRewardFunding(daoId, nftMinter.addr);
        deal(nftMinter.addr, 1 ether);
        super._mintNftChangeBal(
            daoId2,
            canvasId2,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator2.key,
            nftMinter.addr
        );
        assertEq(nftMinter.addr.balance, 0.99 ether);
    }

    event TopUpAmountUsed(address owner, bytes32 daoId, address redeemPool, uint256 erc20Amount, uint256 ethAmount);

    function test_PDCreateFunding_TopUpAccountShouldBeUsedWhenMintInFurtherRound() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.topUpMode = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
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
        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);

        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = false;
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.daoUri = "normal dao uri";

        bytes32 canvasId2 = param.canvasId;
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        vm.roll(2);
        address token = protocol.getDaoToken(daoId2);
        deal(nftMinter.addr, 1 ether);
        // vm.expectEmit(address(protocol));
        // emit TopUpAmountUsed(nftMinter.addr, daoId2, protocol.getDaoFeePool(daoId2), 5_000_000 ether, 0.01 ether);
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;

        super._mintNftWithParam(nftParam, nftMinter.addr);
        // super._mintNftChangeBal(
        //     daoId2,
        //     canvasId2,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator2.key,
        //     nftMinter.addr
        // );
        //default 60 drb,
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 833_333_333_333_333_333_333_333);
    }

    function test_PDCreateFunding_TopUpAccountShouldNotBeUsedWhenMintInTopUpDao() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.topUpMode = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
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

        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);

        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = true;
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.daoUri = "normal dao uri";
        param.mintableRound = 20;

        bytes32 canvasId2 = param.canvasId;
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);
        vm.prank(daoCreator.addr);
        protocol.grantDaoAssetPool(daoId2, 10_000_000 ether, true, "uri");
        vm.prank(daoCreator2.addr);
        protocol.setDaoUnifiedPrice(daoId2, 0.03 ether);
        vm.roll(2);
        address token = protocol.getDaoToken(daoId2);
        deal(nftMinter.addr, 1 ether);
        // vm.expectEmit(address(protocol));
        // emit TopUpAmountUsed(nftMinter.addr, daoId2, protocol.getDaoFeePool(daoId2), 5_000_000 ether, 0.01 ether);
        // super._mintNftChangeBal(
        //     daoId2,
        //     canvasId2,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        //     ),
        //     0.03 ether,
        //     daoCreator2.key,
        //     nftMinter.addr
        // );
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.03 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;

        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);

        //default 60 drb,
        // 1 - 0.03 ether
        assertEq(nftMinter.addr.balance, 0.97 ether);
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 0);
        vm.roll(3);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId2, nft1);
        //50000000/10 + 10000000/20
        assertEq(topUpERC20, 5_500_000 ether);
        assertEq(topUpETH, 0.04 ether);
    }

    function test_PDCreateFunding_GetReward() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.isProgressiveJackpot = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 50;
        param.selfRewardRatioERC20 = 10_000;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.roll(2);
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
        vm.roll(3);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        vm.roll(5);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(5)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        vm.roll(8);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(8)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getERC20RewardTillRound(daoId, 1), 0);
        assertEq(protocol.getERC20RewardTillRound(daoId, 2), 2_000_000 ether);
        assertEq(protocol.getERC20RewardTillRound(daoId, 3), 3_000_000 ether);
        assertEq(protocol.getERC20RewardTillRound(daoId, 4), 3_000_000 ether);
        assertEq(protocol.getERC20RewardTillRound(daoId, 5), 5_000_000 ether);
        assertEq(protocol.getERC20RewardTillRound(daoId, 6), 5_000_000 ether);
        assertEq(protocol.getERC20RewardTillRound(daoId, 7), 5_000_000 ether);
        assertEq(protocol.getERC20RewardTillRound(daoId, 8), 8_000_000 ether);
        assertEq(protocol.getERC20RewardTillRound(daoId, 9), 8_000_000 ether);
    }

    function test_erc20Payment_SimpleMint() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 50;
        param.selfRewardRatioERC20 = 10_000;
        param.erc20PaymentMode = true;
        param.thirdPartyToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(nftMinter.addr, 1 ether);
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
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0.99 ether);
    }

    function test_erc20Payment_topUpAccountShouldBeUsedWhenMintInFurtherRound() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.topUpMode = true;
        param.noPermission = true;
        param.mintableRound = 50;
        param.daoUri = "topup dao uri";

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
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
        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);

        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = false;
        param.erc20PaymentMode = true;
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.daoUri = "normal dao uri";
        param.thirdPartyToken = address(_testERC20); // no effect
        param.uniPriceModeOff = true;
        bytes32 canvasId2 = param.canvasId;
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);
        assertEq(protocol.getDaoToken(daoId), protocol.getDaoToken(daoId2));

        vm.roll(2);
        address token = protocol.getDaoToken(daoId2);
        deal(token, nftMinter.addr, 100_000_000 ether);
        // vm.expectEmit(address(protocol));
        // emit TopUpAmountUsed(nftMinter.addr, daoId2, protocol.getDaoFeePool(daoId2), 5_000_000 ether, 0.01 ether);
        {
            (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId2, nft1);
            assertEq(topUpERC20, 1_000_000 ether);
            assertEq(topUpETH, 0.01 ether);
        }

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 500_000 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;

        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);

        {
            (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId2, nft1);
            assertEq(topUpERC20, 500_000 ether, "Check C");
            assertEq(topUpETH, 0.005 ether, "Check B");
        }
        assertEq(nftMinter.addr.balance, 0.005 ether, "Check A");
    }

    function test_inputToken_SimpleMint() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 50;
        param.selfRewardRatioERC20 = 10_000;
        param.inputToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(nftMinter.addr, 1 ether);
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
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0.99 ether);
    }

    function test_inputToken_topUpAccountShouldBeUsedWhenMintInFurtherRound() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.topUpMode = true;
        param.noPermission = true;
        param.mintableRound = 50;
        param.inputToken = address(_testERC20);
        param.daoUri = "topup dao uri";

        vm.prank(protocolOwner.addr);
        _testERC20.transfer(nftMinter.addr, 1 ether);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
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
        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);

        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = false;
        param.erc20PaymentMode = true;
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.daoUri = "normal dao uri";
        //param.thirdPartyToken = address(_testERC20); //no effect
        param.uniPriceModeOff = true;
        bytes32 canvasId2 = param.canvasId;
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);
        assertEq(protocol.getDaoToken(daoId), protocol.getDaoToken(daoId2));

        vm.roll(2);
        address token = protocol.getDaoToken(daoId2);
        deal(token, nftMinter.addr, 100_000_000 ether);
        // vm.expectEmit(address(protocol));
        // emit TopUpAmountUsed(nftMinter.addr, daoId2, protocol.getDaoFeePool(daoId2), 5_000_000 ether, 0.01 ether);
        {
            (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId2, nft1);
            assertEq(topUpERC20, 1_000_000 ether, "c1");
            assertEq(topUpETH, 0.01 ether, "c2");
        }

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 500_000 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;

        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);

        {
            (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId2, nft1);
            assertEq(topUpERC20, 500_000 ether, "Check C");
            assertEq(topUpETH, 0.005 ether, "Check B");
        }
        //1 - 0.01 + 0.005
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0.995 ether, "Check A");

        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = false;
        param.erc20PaymentMode = false;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        param.daoUri = "normal subdao uri";
        //param.thirdPartyToken = address(_testERC20);
        param.uniPriceModeOff = true;
        bytes32 canvasId3 = param.canvasId;
        bytes32 daoId3 = super._createDaoForFunding(param, daoCreator.addr);

        nftParam.daoId = daoId3;
        nftParam.canvasId = canvasId3;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId3)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.16 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = nft1;

        super._mintNftRevert(nftParam, nftMinter.addr, 0x7939f424); //the selector of TransferFromFailed
        vm.prank(nftMinter.addr);
        _testERC20.approve(address(protocol), 0.1595 ether);
        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
        //0.995 - 0.16 + 0.005 = 0.84
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0.84 ether, "Check A");
    }
}
