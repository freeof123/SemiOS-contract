// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { FixedPointMathLib as Math } from "solmate/utils/FixedPointMathLib.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";

contract GetCanvasNextPriceTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_linear_price_variation() public {
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
        param.priceFactor = 0.0069 ether;
        daoId = _createDaoForFunding(param, daoCreator.addr);

        vm.roll(1);
        bytes32 canvasId = bytes32(uint256(1));
        super._createCanvasAndMintNft(
            daoId,
            canvasId,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        vm.roll(3);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.005 ether);

        {
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);

            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.01 ether);

        {
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0169 ether);

        {
            string memory tokenUri = "test token uri 3";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0238 ether);

        vm.roll(4);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0169 ether);
        vm.roll(5);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.01 ether);
    }

    function test_linear_price_variation_three_canvases() public {
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
        param.priceFactor = 0.0399 ether;
        daoId = _createDaoForFunding(param, daoCreator.addr);

        vm.roll(1);

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
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.005 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.005 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId3), 0.005 ether);

        {
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId1;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.01 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId3), 0.01 ether);

        {
            string memory tokenUri = "test token uri 1.2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId1;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.0499 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.01 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId3), 0.01 ether);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.02 ether);

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.0499 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.02 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId3), 0.02 ether);
    }

    function test_exponential_price_variation() public {
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
        param.priceFactor = 12_345;
        daoId = _createDaoForFunding(param, daoCreator.addr);

        vm.roll(1);
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

        vm.roll(3);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.005 ether);

        {
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId1;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.01 ether);

        {
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId1;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.012345 ether);

        {
            string memory tokenUri = "test token uri 3";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId1;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        vm.roll(4);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.012345 ether);
        vm.roll(5);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.01 ether);
        vm.roll(6);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1), 0.005 ether);
    }
}
