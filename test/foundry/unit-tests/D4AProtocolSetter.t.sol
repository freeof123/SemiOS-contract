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
        DeployHelper.CreateDaoParam memory param;
        param.floorPrice = 0;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;

        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        SetDaoParam memory vars;
        vars.daoId = daoId;
        vars.nftMaxSupplyRank = 0;
        vars.remainingRound = 1;
        vars.daoFloorPrice = 0;
        vars.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        vars.nftPriceFactor = 1000;
        vars.dailyMintCap = 100;
        vars.initialTokenSupply = 1 ether;
        vars.unifiedPrice = 1006;
        vars.setChildrenParam = SetChildrenParam(new bytes32[](0), new uint256[](0), new uint256[](0), 0, 0, 0);
        vars.allRatioParam = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 800, 2000, 7000);

        // 修改MainDAO的参数
        vm.expectRevert(CannotUseZeroFloorPrice.selector);
        hoax(daoCreator.addr);
        protocol.setDaoParams(vars);
    }
    /**
     * dev when current price is lower than new floor price, should increase current round price to new floor
     * price
     * instead of floor price / 2
     */

    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3 ETH
        // canvas price now should be 0.3 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;

        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        // super._createCanvasAndMintNft(
        //     daoId, canvasId1, "nft1", "canvas1", 0, canvasCreator.key, canvasCreator.addr, nftMinter.addr
        // );
        // bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.3 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.3 ether);
    }

    /**
     * dev when current price is higher than new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_higher_than_new_price() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;

        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
    }

    //     /**
    //      * dev when current price is equal to new floor price, current price should stay the same
    //      */
    function test_setDaoFloorPrice_when_current_price_is_equal_to_new_price() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;

        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.25 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
    }

    //     /**
    //      * dev when current price is lower than new floor price, should increase current round price to new floor
    // price
    //      * instead of floor price / 2
    //      */
    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price_two_canvases() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3 ETH
        // canvas price now should be 0.3 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;

        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        vm.roll(1);
        bytes32 canvasId2 = bytes32(uint256(222));
        super._createCanvasAndMintNft(
            daoId, canvasId2, "nft1", "canvas2", 0, canvasCreator2.key, canvasCreator2.addr, nftMinter.addr
        );

        vm.roll(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.69 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.69 ether);
    }

    /**
     * dev when current price is higher than new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_higher_than_new_price_two_canvases() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        bytes32 canvasId2 = bytes32(uint256(222));
        super._createCanvasAndMintNft(
            daoId, canvasId2, "nft1", "canvas2", 0, canvasCreator2.key, canvasCreator2.addr, nftMinter.addr
        );

        vm.roll(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
    }

    /**
     * dev when current price is equal to new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_equal_to_new_price_two_canvases() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        vm.roll(1);
        bytes32 canvasId2 = bytes32(uint256(222));
        super._createCanvasAndMintNft(
            daoId, canvasId2, "nft1", "canvas2", 0, canvasCreator2.key, canvasCreator2.addr, nftMinter.addr
        );

        vm.roll(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.5 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 128);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
    }

    /**
     * dev when current price is lower than new floor price, should increase current round price to new floor
     * price
     * instead of floor price / 2
     */
    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3ETH
        // canvas price now should be 0.3 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.3 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.3 ether);
    }

    /**
     * dev when current price is higher than new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_higher_than_new_price_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
    }

    /**
     * dev when current price is equal to new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_equal_to_new_price_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.25 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.25 ether);
    }

    /**
     * dev when current price is lower than new floor price, should increase current round price to new floor
     * price
     * instead of floor price / 2
     */
    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price_two_canvases_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3 ETH
        // canvas price now should be 0.3 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        bytes32 canvasId2 = bytes32(uint256(222));
        super._createCanvasAndMintNft(
            daoId, canvasId2, "nft1", "canvas2", 0, canvasCreator2.key, canvasCreator2.addr, nftMinter.addr
        );

        vm.roll(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 10_000);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.69 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.69 ether);
    }

    /**
     * dev when current price is higher than new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_higher_than_new_price_two_canvases_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        bytes32 canvasId2 = bytes32(uint256(222));
        super._createCanvasAndMintNft(
            daoId, canvasId2, "nft1", "canvas2", 0, canvasCreator2.key, canvasCreator2.addr, nftMinter.addr
        );
        vm.roll(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 10_000);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
    }

    /**
     * dev when current price is equal to new floor price, current price should stay the same
     */
    function test_setDaoFloorPrice_when_current_price_is_equal_to_new_price_two_canvases_1x_priceFactor() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.01 ETH
        // canvas price now should be 0.25 ETH
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        bytes32 canvasId2 = bytes32(uint256(222));
        super._createCanvasAndMintNft(
            daoId, canvasId2, "nft1", "canvas2", 0, canvasCreator2.key, canvasCreator2.addr, nftMinter.addr
        );

        vm.roll(3);
        for (uint256 i; i < 10; ++i) {
            string memory tokenUri = string.concat("test token uri", vm.toString(i));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 10_000);

        vm.roll(5);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.5 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether * 2 ** 8);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.5 ether);
    }

    function test_RevertIf_setDaoPriceTemplate_ExponentialPriceVariation_priceFactor_less_than_10000() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.isProgressiveJackpot = true;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 10_000);
        vm.expectRevert();
        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 9999);
    }

    // 以下几个注释掉的测试均为setDaoMintableRound对应的测试，setDaoMintableRound已被删除
    // function test_RevertIf_setDaoMintableRound_when_exceed_mintable_round_isProgressiveJackpot() public {
    //     DeployHelper.CreateDaoParam memory createDaoParam;
    //     createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
    //     createDaoParam.priceFactor = 0.01 ether;
    //     createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
    //     createDaoParam.rewardDecayFactor = 12_600;
    //     createDaoParam.isProgressiveJackpot = true;
    //     bytes32 daoId = _createDaoForFunding(createDaoParam);

    //     vm.roll(31);
    //     vm.expectRevert(ExceedDaoMintableRound.selector);
    //     hoax(daoCreator.addr);
    //     protocol.setDaoMintableRound(daoId, 69);
    // }

    // function test_RevertIf_setDaoMintableRound_when_new_end_round_less_than_current_round_isProgressiveJackpot()
    //     public
    // {
    //     DeployHelper.CreateDaoParam memory createDaoParam;
    //     createDaoParam.mintableRound = 69;
    //     createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
    //     createDaoParam.priceFactor = 0.01 ether;
    //     createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
    //     createDaoParam.rewardDecayFactor = 12_600;
    //     createDaoParam.isProgressiveJackpot = true;
    //     bytes32 daoId = _createDaoForFunding(createDaoParam);

    //     vm.roll(51);
    //     vm.expectRevert(NewMintableRoundsFewerThanRewardIssuedRounds.selector);
    //     hoax(daoCreator.addr);
    //     protocol.setDaoMintableRound(daoId, 42);
    // }

    //     function test_RevertIf_setDaoMintableRound_when_exceed_mintable_round_notProgressiveJackpot() public {
    //         DeployHelper.CreateDaoParam memory createDaoParam;
    //         createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
    //         createDaoParam.priceFactor = 0.01 ether;
    //         createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
    //         createDaoParam.rewardDecayFactor = 12_600;
    //         bytes32 daoId = _createDaoForFunding(createDaoParam);

    //         vm.roll(1);
    //         hoax(canvasCreator.addr);
    //         bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0),
    // 3000);

    //         for (uint256 i; i < 30; ++i) {
    //             vm.roll(2 * i + 1);
    //             string memory tokenUri = string.concat("test token uri", vm.toString(i));
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             uint256 price = protocol.getCanvasNextPrice(canvasId);
    //             hoax(nftMinter.addr);
    //             protocol.mintNFT{ value: price }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //         }

    //         {
    //             startHoax(daoCreator.addr);
    //             protocol.setDaoMintableRound(daoId, 69);
    //             protocol.setDaoMintableRound(daoId, 30);
    //             vm.stopPrank();
    //         }

    //         vm.roll(60);
    //         vm.expectRevert(ExceedDaoMintableRound.selector);
    //         hoax(daoCreator.addr);
    //         protocol.setDaoMintableRound(daoId, 69);
    //     }

    //     function test_RevertIf_setDaoMintableRound_when_new_end_round_less_than_current_round_notProgressiveJackpot()
    //         public
    //     {
    //         DeployHelper.CreateDaoParam memory createDaoParam;
    //         createDaoParam.mintableRound = 69;
    //         createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
    //         createDaoParam.priceFactor = 0.01 ether;
    //         createDaoParam.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
    //         createDaoParam.rewardDecayFactor = 12_600;
    //         bytes32 daoId = _createDaoForFunding(createDaoParam);

    //         vm.roll(1);
    //         hoax(canvasCreator.addr);
    //         bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0),
    // 3000);

    //         for (uint256 i; i < 30; ++i) {
    //             vm.roll(2 * i + 1);
    //             string memory tokenUri = string.concat("test token uri", vm.toString(i));
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             uint256 price = protocol.getCanvasNextPrice(canvasId);
    //             hoax(nftMinter.addr);
    //             protocol.mintNFT{ value: price }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //         }

    //         {
    //             startHoax(daoCreator.addr);
    //             protocol.setDaoMintableRound(daoId, 69);
    //             protocol.setDaoMintableRound(daoId, 30);
    //             vm.stopPrank();
    //         }

    //         vm.expectRevert(NewMintableRoundsFewerThanRewardIssuedRounds.selector);
    //         hoax(daoCreator.addr);
    //         protocol.setDaoMintableRound(daoId, 28);
    //     }

    function test_setDaoRemainingRound_new_mints_should_update_active_rounds() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 69;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;
        createDaoParam.floorPrice = 0.5 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        vm.roll(1);

        {
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(protocol.getDaoActiveRounds(daoId).length, 1);
        assertEq(protocol.getDaoActiveRounds(daoId)[0], 1);

        vm.roll(2);
        {
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(protocol.getDaoActiveRounds(daoId).length, 2);
        assertEq(protocol.getDaoActiveRounds(daoId)[0], 1);
        assertEq(protocol.getDaoActiveRounds(daoId)[1], 2);

        hoax(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 41);

        {
            string memory tokenUri = "test token uri 3";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(protocol.getDaoActiveRounds(daoId).length, 2);
        assertEq(protocol.getDaoActiveRounds(daoId)[0], 1);
        assertEq(protocol.getDaoActiveRounds(daoId)[1], 2);

        vm.roll(3);

        {
            string memory tokenUri = "test token uri 4";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        vm.roll(4);

        hoax(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 27);

        {
            string memory tokenUri = "test token uri 5";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(protocol.getDaoActiveRounds(daoId).length, 4);
        assertEq(protocol.getDaoActiveRounds(daoId)[0], 1);
        assertEq(protocol.getDaoActiveRounds(daoId)[1], 2);
        assertEq(protocol.getDaoActiveRounds(daoId)[2], 3);
        assertEq(protocol.getDaoActiveRounds(daoId)[3], 4);
        assertEq(protocol.getDaoStartBlock(daoId), 1);
    }

    function test_setDaoMintableRound_take_effect_at_current_round_when_no_mint_happened() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 90;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.01 ether;

        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        //bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        hoax(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 120);

        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            416_666_666_666_666_666_666_666
        );
    }

    function test_setDaoFloorPrice_case_1() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 90;
        createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        createDaoParam.priceFactor = 0.0098 ether;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether);

        {
            string memory tokenUri = "test token uri 1";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.0198 ether);

        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.02 ether);

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.02 ether);

        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 0.03 ether);

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.03 ether);

        {
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            uint256 price = protocol.getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.0398 ether);

        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 17_000);

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.051 ether);
    }

    function test_setDaoMintableRound_SetThenMintInTheSameRound() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 90;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.selfRewardRatioERC20 = 10_000;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        _mintNft(daoId, canvasId, "test token uri 1", 0, daoCreator.key, nftMinter.addr);

        vm.roll(2);

        hoax(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 119);

        _mintNft(daoId, canvasId, "test token uri 2", 0, daoCreator.key, nftMinter.addr);

        assertEq(protocol.getDaoActiveRounds(daoId).length, 2);
        assertEq(protocol.getDaoActiveRounds(daoId)[0], 1);
        assertEq(protocol.getDaoActiveRounds(daoId)[1], 2);
        assertEq(protocol.getRoundERC20Reward(daoId, 1), 555_555_555_555_555_555_555_555);
        assertEq(protocol.getRoundERC20Reward(daoId, 2), 415_499_533_146_591_970_121_381);
        assertEq(protocol.getERC20RewardTillRound(daoId, 2), 971_055_088_702_147_525_676_936);
    }

    function test_setDaoMintableRound_MintThenSetInTheSameRound() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 90;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.selfRewardRatioERC20 = 10_000;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        _mintNft(daoId, canvasId, "test token uri 1", 0, daoCreator.key, nftMinter.addr);

        vm.roll(2);

        _mintNft(daoId, canvasId, "test token uri 2", 0, daoCreator.key, nftMinter.addr);

        hoax(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 119);

        assertEq(protocol.getDaoActiveRounds(daoId).length, 2);
        assertEq(protocol.getDaoActiveRounds(daoId)[0], 1);
        assertEq(protocol.getDaoActiveRounds(daoId)[1], 2);
        assertEq(protocol.getRoundERC20Reward(daoId, 1), 555_555_555_555_555_555_555_555);
        assertEq(protocol.getRoundERC20Reward(daoId, 2), 555_555_555_555_555_555_555_555);
        assertEq(protocol.getERC20RewardTillRound(daoId, 2), 1_111_111_111_111_111_111_111_110);
    }

    function test_setDaoMintableRound_DaoStartAtNextRoundAndMintThenSetInTheSameRound() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.startBlock = 2;
        createDaoParam.mintableRound = 90;
        createDaoParam.isBasicDao = true;
        createDaoParam.uniPriceModeOff = true;
        createDaoParam.noPermission = true;
        createDaoParam.selfRewardRatioERC20 = 10_000;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = createDaoParam.canvasId;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);
        vm.roll(2);

        _mintNft(daoId, canvasId, "test token uri 1", 0, daoCreator.key, nftMinter.addr);

        hoax(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 120);

        assertEq(protocol.getDaoActiveRounds(daoId).length, 1);
        assertEq(protocol.getDaoActiveRounds(daoId)[0], 1);
        assertEq(protocol.getRoundERC20Reward(daoId, 1), 555_555_555_555_555_555_555_555);
        assertEq(protocol.getERC20RewardTillRound(daoId, 1), 555_555_555_555_555_555_555_555);
    }
}
