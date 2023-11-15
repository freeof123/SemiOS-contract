// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam } from "contracts/interface/D4AStructs.sol";
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

        super._mintNftDaoFunding(
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

        super._mintNftDaoFunding(
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

        super._mintNftDaoFunding(
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
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        param.daoUri = "continuous dao uri";
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;

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
        protocol.setInitialTokenSupplyForSubDao(subDaoId2, 10_000_000 ether);
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

        drb.changeRound(2);
        protocol.claimDaoCreatorRewardFunding(subDaoId2);
        //1000000 * 20% * 70%
        assertEq(IERC20(token).balanceOf(daoCreator3.addr), 140_000 ether);
        protocol.claimCanvasRewardFunding(canvasId3);
        //add 1000000 * 20% * 20%
        assertEq(IERC20(token).balanceOf(daoCreator3.addr), 180_000 ether);
        protocol.claimNftMinterRewardFunding(subDaoId2, nftMinter.addr);
        //1000000 * 20% * 8%
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 16_000 ether);
        assertEq(IERC20(token).balanceOf(protocol.protocolFeePool()), 4000 ether);
        assertEq(IERC20(token).balanceOf(address(protocol)), 0);
    }

    function test_PDCreateFunding_createTopUpDaoAndMintToNormalDao() public {
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
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = false;
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.daoUri = "normal dao uri";

        bytes32 canvasId2 = param.canvasId;
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        //protocol.claimNftMinterRewardFunding(daoId, nftMinter.addr);
        //deal(nftMinter.addr.balance);
        super._mintNftDaoFunding(
            daoId2,
            canvasId2,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator2.key,
            nftMinter.addr
        );
        console2.log(nftMinter.addr.balance);
    }
}
