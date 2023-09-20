// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";

contract D4AProtocolSetterTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_setDaoParams_when_daoFloorPrice_is_zero() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 9999;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(daoCreator.addr);
        // 需要先构造一个结构体然后传递参数，否则栈溢出
        // D4AProtocolSetter(address(protocol)).setDaoParams(
        //     daoId, 0, 1, 9999, PriceTemplateType(0), 20_000, 300, 9500, 0, 250, 750, 10, 10_000_000
        // );
    }

    /**
     * dev when current price is lower than new floor price, should increase current round price to new floor price
     * instead of floor price / 2
     */
    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3 ETH
        // canvas price now should be 0.3 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.3 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.3 ether);
    }

    /**
     * dev when current price is higher than new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_higher_than_new_price() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
    }

    /**
     * dev when current price is equal to new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_equal_to_new_price() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.25 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
    }

    /**
     * dev when current price is lower than new floor price, should increase current round price to new floor price
     * instead of floor price / 2
     */
    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price_two_canvases() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3 ETH
        // canvas price now should be 0.3 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        drb.changeRound(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.69 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.69 ether);
    }

    /**
     * dev when current price is higher than new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_higher_than_new_price_two_canvases() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        drb.changeRound(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
    }

    /**
     * dev when current price is equal to new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_equal_to_new_price_two_canvases() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        drb.changeRound(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.5 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
    }

    /**
     * dev when current price is lower than new floor price, should increase current round price to new floor price
     * instead of floor price / 2
     */
    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3 ETH
        // canvas price now should be 0.3 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.3 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.3 ether);
    }

    /**
     * dev when current price is higher than new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_higher_than_new_price_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
    }

    /**
     * dev when current price is equal to new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_equal_to_new_price_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.25 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
    }

    /**
     * dev when current price is lower than new floor price, should increase current round price to new floor price
     * instead of floor price / 2
     */
    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price_two_canvases_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3 ETH
        // canvas price now should be 0.3 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        drb.changeRound(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoPriceTemplate(
            daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 10_000
        );

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.69 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.69 ether);
    }

    /**
     * dev when current price is higher than new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_higher_than_new_price_two_canvases_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        drb.changeRound(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoPriceTemplate(
            daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 10_000
        );

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
    }

    /**
     * dev when current price is equal to new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_equal_to_new_price_two_canvases_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 7;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        drb.changeRound(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoPriceTemplate(
            daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 10_000
        );

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.5 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.5 ether);
    }

    function test_RevertIf_setDaoPriceTemplate_ExponentialPriceVariation_priceFactor_less_than_10001() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 12_600;
        createDaoParam.isProgressiveJackpot = true;
        bytes32 daoId = _createDao(createDaoParam);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoPriceTemplate(
            daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 10_000
        );
        vm.expectRevert();
        D4AProtocolSetter(address(protocol)).setDaoPriceTemplate(
            daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 10_000
        );
    }

    function test_RevertIf_setDaoMintableRound_when_exceed_mintable_round_isProgressiveJackpot() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 12_600;
        createDaoParam.isProgressiveJackpot = true;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(31);
        vm.expectRevert(ExceedDaoMintableRound.selector);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 69);
    }

    function test_RevertIf_setDaoMintableRound_when_new_end_round_less_than_current_round_isProgressiveJackpot()
        public
    {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 69;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 12_600;
        createDaoParam.isProgressiveJackpot = true;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(51);
        vm.expectRevert(NewMintableRoundsFewerThanRewardIssuedRounds.selector);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 42);
    }

    function test_RevertIf_setDaoMintableRound_when_exceed_mintable_round_notProgressiveJackpot() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 12_600;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        for (uint256 i; i < 30; ++i) {
            drb.changeRound(2 * i + 1);
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        {
            startHoax(daoCreator.addr);
            D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 69);
            D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 30);
            vm.stopPrank();
        }

        drb.changeRound(60);
        vm.expectRevert(ExceedDaoMintableRound.selector);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 69);
    }

    function test_RevertIf_setDaoMintableRound_when_new_end_round_less_than_current_round_notProgressiveJackpot()
        public
    {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 69;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 12_600;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        for (uint256 i; i < 30; ++i) {
            drb.changeRound(2 * i + 1);
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        {
            startHoax(daoCreator.addr);
            D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 69);
            D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 30);
            vm.stopPrank();
        }

        vm.expectRevert(NewMintableRoundsFewerThanRewardIssuedRounds.selector);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 28);
    }

    function test_setDaoMintableRound_new_mints_should_update_active_rounds_in_old_checkpoint() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 69;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 12_600;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        {
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0).length, 1);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[0], 1);

        drb.changeRound(2);
        {
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0).length, 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[0], 1);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[1], 2);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 42);

        {
            string memory tokenUri = "test token uri 3";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0).length, 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[0], 1);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[1], 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 1).length, 0);

        drb.changeRound(3);

        {
            string memory tokenUri = "test token uri 4";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        drb.changeRound(4);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 30);

        {
            string memory tokenUri = "test token uri 5";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0).length, 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[0], 1);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[1], 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 1).length, 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 1)[0], 3);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 1)[1], 4);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 2).length, 0);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardStartRound(daoId, 2), 5);
    }

    function test_setDaoMintableRound_take_effect_at_current_round_when_no_mint_happened() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 90;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 10_801;
        bytes32 daoId = _createDao(createDaoParam);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 120);

        assertEq(D4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1), 74_166_953_780_930_718_901_381_592);
    }

    function test_setDaoFloorPrice_case_1() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 90;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.0098 ether;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 10_801;
        bytes32 daoId = _createDao(createDaoParam);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3500);

        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.01 ether);

        {
            string memory tokenUri = "test token uri 1";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0198 ether);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.02 ether);

        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.02 ether);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.03 ether);

        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.03 ether);

        {
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0398 ether);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoPriceTemplate(
            daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 17_000
        );

        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.051 ether);
    }

    function test_setDaoMintableRound_SetThenMintInTheSameRound() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 90;
        bytes32 daoId = _createDao(createDaoParam);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 120);

        _mintNft(daoId, canvasId, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);

        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardTotalRound(daoId, 0), 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardTotalRound(daoId, 1), 118);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0).length, 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[0], 1);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[1], 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 1).length, 0);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoTotalReward(daoId, 0), 22_222_222_222_222_222_222_222_222);
        assertEq(
            D4AProtocolReadable(address(protocol)).getDaoTotalReward(daoId, 1), 977_777_777_777_777_777_777_777_778
        );
        assertEq(
            D4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 1), 11_111_111_111_111_111_111_111_111
        );
        assertEq(
            D4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 2), 22_222_222_222_222_222_222_222_222
        );
    }

    function test_setDaoMintableRound_MintThenSetInTheSameRound() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 90;
        bytes32 daoId = _createDao(createDaoParam);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        _mintNft(daoId, canvasId, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 120);

        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardTotalRound(daoId, 0), 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardTotalRound(daoId, 1), 118);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0).length, 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[0], 1);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[1], 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 1).length, 0);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoTotalReward(daoId, 0), 22_222_222_222_222_222_222_222_222);
        assertEq(
            D4AProtocolReadable(address(protocol)).getDaoTotalReward(daoId, 1), 977_777_777_777_777_777_777_777_778
        );
        assertEq(
            D4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 1), 11_111_111_111_111_111_111_111_111
        );
        assertEq(
            D4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 2), 22_222_222_222_222_222_222_222_222
        );
    }

    function test_setDaoMintableRound_DaoStartAtNextRoundAndMintThenSetInTheSameRound() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.startDrb = 2;
        createDaoParam.mintableRound = 90;
        createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        createDaoParam.rewardDecayFactor = 10_801;
        bytes32 daoId = _createDao(createDaoParam);

        drb.changeRound(2);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 120);

        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardTotalRound(daoId, 0), 1);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardTotalRound(daoId, 1), 119);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0).length, 1);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 0)[0], 2);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoRewardActiveRounds(daoId, 1).length, 0);
        assertEq(D4AProtocolReadable(address(protocol)).getDaoTotalReward(daoId, 0), 74_232_049_461_655_383_750_589_661);
        assertEq(
            D4AProtocolReadable(address(protocol)).getDaoTotalReward(daoId, 1), 925_767_950_538_344_616_249_410_339
        );
        assertEq(
            D4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 2), 74_232_049_461_655_383_750_589_661
        );
    }
}