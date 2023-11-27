// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { PriceTemplateType, RewardTemplateType, TemplateChoice } from "contracts/interface/D4AEnums.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoPriceTest is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    function test_PDCreateFunding_CanvasNextPrice() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.uniPriceModeOff = true;
        param.floorPriceRank = 1;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        bytes32 canvasId1 = "0abcd";
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.02 ether);
        drb.changeRound(2);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.01 ether);
    }

    function test_PDCreateFunding_SetPriceFactor() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;

        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.uniPriceModeOff = true;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        console2.log(protocol.getCanvasNextPrice(canvasId1));

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        console2.log(protocol.getCanvasNextPrice(canvasId1));
        vm.prank(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType(0), 15_000);
        console2.log(protocol.getCanvasNextPrice(canvasId1));
    }

    function test_PDCreateFunding_SetPriceFactorAndPass() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;

        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.uniPriceModeOff = true;
        param.needMintableWork = true;
        param.reserveNftNumber = 500;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        console2.log(protocol.getCanvasNextPrice(canvasId1));

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
        console2.log(protocol.getCanvasNextPrice(canvasId1));
        vm.prank(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType(0), 15_000);
        console2.log(protocol.getCanvasNextPrice(canvasId1));
    }

    // testcase 1.3-15
    function test_PDCreateFunding_1_3_90exp() public {
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
        param.uniPriceModeOff = true;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 0.009 ether);
        //address token = protocol.getDaoToken(daoId);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.019 ether);
        drb.changeRound(2);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
    }

    function test_PDCreateFunding_1_3_90Linear() public {
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
        param.uniPriceModeOff = true;
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 0.02 ether;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 0.009 ether);
        //address token = protocol.getDaoToken(daoId);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.019 ether);
        drb.changeRound(2);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
    }

    function test_PDCreateFunding_1_3_89exp() public {
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
        param.uniPriceModeOff = true;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 15_000);
        //address token = protocol.getDaoToken(daoId);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.015 ether);
        drb.changeRound(2);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
    }

    function test_PDCreateFunding_1_3_89Linear() public {
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
        param.uniPriceModeOff = true;
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 0.02 ether;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 0.015 ether);
        //address token = protocol.getDaoToken(daoId);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.025 ether);
        drb.changeRound(2);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
    }

    function test_PDCreateFunding_1_3_88() public {
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
        param.uniPriceModeOff = true;
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 0.02 ether;
        param.floorPriceRank = 4;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        //address token = protocol.getDaoToken(daoId);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.12 ether);
        vm.prank(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.12 ether);
    }

    function test_PDCreateFunding_1_3_87() public {
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
        param.uniPriceModeOff = true;
        param.floorPriceRank = 1;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        //address token = protocol.getDaoToken(daoId);
        drb.changeRound(2);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.02 ether);
        vm.prank(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.05 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.05 ether);
    }

    function test_PDCreateFunding_1_3_86() public {
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
        param.uniPriceModeOff = true;
        //param.floorPriceRank = 1;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        vm.prank(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.02 ether);
        //address token = protocol.getDaoToken(daoId);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.02 ether);
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
