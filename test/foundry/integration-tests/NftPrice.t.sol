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
        // DeployHelper.CreateDaoParam memory param;
        // param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        // param.priceFactor = 0.3 ether;
        // bytes32 daoId = _createDao(param);

        // hoax(canvasCreator.addr);
        // bytes32 canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0),
        // 0);

        // hoax(canvasCreator2.addr);
        // bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0),
        // 0);

        // hoax(canvasCreator3.addr);
        // bytes32 canvasId3 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0),
        // 0);

        // drb.changeRound(2);

        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.005 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.005 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.005 ether);

        // hoax(daoCreator.addr);
        // protocol.setDaoFloorPrice(daoId, 0.01 ether);

        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.005 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.005 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.005 ether);

        // _mintNft(daoId, canvasId1, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.01 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.01 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.01 ether);

        // _mintNft(daoId, canvasId1, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);
        // _mintNft(daoId, canvasId1, "test token uri 3", 0, canvasCreator.key, nftMinter.addr);
        // _mintNft(daoId, canvasId1, "test token uri 4", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.91 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.01 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.01 ether);

        // hoax(daoCreator.addr);
        // protocol.setDaoFloorPrice(daoId, 0.03 ether);

        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.91 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.03 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.03 ether);

        // hoax(daoCreator.addr);
        // protocol.setDaoFloorPrice(daoId, 0.05 ether);

        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.91 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.05 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.05 ether);

        // hoax(daoCreator.addr);
        // protocol.setDaoFloorPrice(daoId, 0.02 ether);

        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId1), 0.91 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId2), 0.05 ether);
        // assertEq(protocol.getCanvasNextPrice(daoId, canvasId3), 0.05 ether);
    }

    function test_Lpv() public {
        // DeployHelper.CreateDaoParam memory param;
        // param.floorPrice = 4;
        // param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        // param.priceFactor = 3 ether;
        // bytes32 daoId = _createDao(param);

        // hoax(canvasCreator.addr);
        // bytes32 canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0),
        // 0);

        // hoax(canvasCreator2.addr);
        // bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0),
        // 0);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.1 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        // drb.changeRound(3);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.05 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.05 ether);

        // _mintNft(daoId, canvasId1, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.1 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        // _mintNft(daoId, canvasId1, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 3.1 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        // _mintNft(daoId, canvasId1, "test token uri 3", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 6.1 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        // hoax(daoCreator.addr);
        // protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 10 ether);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 13.1 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);
    }

    function test_Epv() public {
        // DeployHelper.CreateDaoParam memory param;
        // param.floorPriceRank = 0.1 ether;
        // param.priceFactor = 1.4e4;
        // bytes32 daoId = _createDao(param);

        // hoax(canvasCreator.addr);
        // bytes32 canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0),
        // 0);

        // hoax(canvasCreator2.addr);
        // bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0),
        // 0);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.1 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        // drb.changeRound(3);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.05 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.05 ether);

        // _mintNft(daoId, canvasId1, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.1 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        // _mintNft(daoId, canvasId1, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.14 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        // _mintNft(daoId, canvasId1, "test token uri 3", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.196 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);

        // hoax(daoCreator.addr);
        // protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 5e4);

        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.7 ether);
        // assertEq(protocol.getCanvasNextPrice(canvasId2), 0.1 ether);
    }

    function test_PriceUnderDfpShouldElevateToDfpAfterMint() public {
        // DeployHelper.CreateDaoParam memory param;
        // param.floorPriceRank = 2;
        // bytes32 daoId = _createDao(param);

        // hoax(canvasCreator.addr);
        // bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        // _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        // (uint256 round, uint256 price) = protocol.getDaoMaxPriceInfo(daoId);
        // assertEq(round, 1);
        // assertEq(price, 0.03 ether);
        // (round, price) = protocol.getCanvasLastPrice(canvasId);
        // assertEq(round, 1);
        // assertEq(price, 0.03 ether);

        // drb.changeRound(6);

        // hoax(daoCreator.addr);
        // protocol.setDaoFloorPrice(daoId, 0.03 ether);
        // hoax(daoCreator.addr);
        // protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 0.0017 ether);
        // // protocol.setDaoParams(
        // //     daoId, 1, 5, 2, PriceTemplateType.LINEAR_PRICE_VARIATION, 1_700_000_000_000_000, 2800, 5000, 2000,
        // 300,
        // // 800
        // // );

        // _mintNft(daoId, canvasId, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);

        // (round, price) = protocol.getDaoMaxPriceInfo(daoId);
        // assertEq(round, 1);
        // assertEq(price, 0.03 ether);
        // (round, price) = protocol.getCanvasLastPrice(canvasId);
        // assertEq(round, 6);
        // assertEq(price, 0.015 ether);

        // assertEq(protocol.getCanvasNextPrice(canvasId), 0.03 ether);

        // _mintNft(daoId, canvasId, "test token uri 3", 0, canvasCreator.key, nftMinter.addr);

        // assertEq(protocol.getCanvasNextPrice(canvasId), 0.0317 ether);
    }
}
