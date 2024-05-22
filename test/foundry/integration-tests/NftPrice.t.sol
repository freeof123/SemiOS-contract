// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AConstants.sol";
import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { D4ASettingsReadable } from "contracts/D4ASettings/D4ASettingsReadable.sol";

contract NftPriceTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_setDaoFloorPrice_PriceShouldChangeCorrectly() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = false;
        param.needMintableWork = true;
        param.noPermission = true;

        // 变价设置
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 0.3 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        bytes32 canvasId1 = bytes32(uint256(1));
        bytes32 canvasId2 = bytes32(uint256(2));
        bytes32 canvasId3 = bytes32(uint256(3));

        super._createCanvasAndMintNft(
            daoId,
            canvasId1,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        super._createCanvasAndMintNft(
            daoId,
            canvasId2,
            "test token uri 2",
            "test canvas uri 2",
            0.01 ether,
            canvasCreator2.key,
            canvasCreator2.addr,
            nftMinter.addr
        );

        super._createCanvasAndMintNft(
            daoId,
            canvasId3,
            "test token uri 3",
            "test canvas uri 3",
            0.01 ether,
            canvasCreator3.key,
            canvasCreator3.addr,
            nftMinter.addr
        );

        vm.roll(3);

        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.005 ether);

        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.01 ether);

        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.005 ether);

        _mintNft(daoId, canvasId1, "test token uri 1.1", 0, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.01 ether);

        _mintNft(daoId, canvasId1, "test token uri 1.2", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId1, "test token uri 1.3", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId1, "test token uri 1.4", 0, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.91 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.01 ether);

        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.03 ether);

        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.91 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.03 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.03 ether);

        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.05 ether);

        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.91 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.05 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.05 ether);

        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.02 ether);

        assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.91 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.05 ether);
        assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.05 ether);
    }

    function test_Lpv() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = false;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 3 ether;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        bytes32 canvasId1 = bytes32(uint256(1));
        bytes32 canvasId2 = bytes32(uint256(2));

        super._createCanvasAndMintNft(
            daoId,
            canvasId1,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        super._createCanvasAndMintNft(
            daoId,
            canvasId2,
            "test token uri 2",
            "test canvas uri 2",
            0.01 ether,
            canvasCreator2.key,
            canvasCreator2.addr,
            nftMinter.addr
        );

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.1 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        vm.roll(2);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.05 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.05 ether);

        _mintNft(daoId, canvasId1, "test token uri 1.1", 0, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.1 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        _mintNft(daoId, canvasId1, "test token uri 1.2", 0, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 3.1 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        _mintNft(daoId, canvasId1, "test token uri 1.3", 0, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 6.1 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 10 ether);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 13.1 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);
    }

    function test_Epv() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = false;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.priceFactor = 1.4e4;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        bytes32 canvasId1 = bytes32(uint256(1));
        bytes32 canvasId2 = bytes32(uint256(2));

        super._createCanvasAndMintNft(
            daoId,
            canvasId1,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        super._createCanvasAndMintNft(
            daoId,
            canvasId2,
            "test token uri 2",
            "test canvas uri 2",
            0.01 ether,
            canvasCreator2.key,
            canvasCreator2.addr,
            nftMinter.addr
        );

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.1 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        vm.roll(3);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.05 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.05 ether);

        _mintNft(daoId, canvasId1, "test token uri 1.1", 0, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.1 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        _mintNft(daoId, canvasId1, "test token uri 1.2", 0, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.14 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        _mintNft(daoId, canvasId1, "test token uri 1.3", 0, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.196 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 5e4);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.7 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);
    }

    function test_PriceUnderDfpShouldElevateToDfpAfterMint() public {
        // DeployHelper.CreateDaoParam memory param;
        // param.floorPriceRank = 2;
        // bytes32 daoId = _createDaoForFunding(param);
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = false;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.floorPrice = 0.03 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        bytes32 canvasId1 = bytes32(uint256(1));
        super._createCanvasAndMintNft(
            daoId,
            canvasId1,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        _mintNft(daoId, canvasId1, "test token uri 1.1", 0, canvasCreator.key, nftMinter.addr);

        (uint256 round, uint256 price) = protocol.getDaoMaxPriceInfo(daoId);
        assertEq(round, 1);
        assertEq(price, 0.03 ether);
        (round, price) = protocol.getCanvasLastPrice(canvasId1);
        assertEq(round, 1);
        assertEq(price, 0.03 ether);

        vm.roll(6);

        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.03 ether);
        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 0.0017 ether);

        SetDaoParam memory vars;
        vars.daoId = daoId;
        vars.nftMaxSupplyRank = 1;
        vars.remainingRound = 5;
        vars.daoFloorPrice = 0.03 ether;
        vars.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        vars.nftPriceFactor = 0.0017 ether;
    }

    function test_fiatPriceLessThanFloorPrice() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = false;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.floorPrice = 0.03 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        vm.deal(nftMinter.addr, 1 ether);
        _mintNftChangeBal(daoId, param.canvasId, "test token uri 1.1", 0.02 ether, daoCreator.key, nftMinter.addr);
        assertEq(nftMinter.addr.balance, 0.98 ether);
    }
}
