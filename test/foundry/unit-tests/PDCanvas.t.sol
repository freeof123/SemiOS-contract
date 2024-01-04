// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import { PDProtocolCanvas, CreateCanvasAndMintNFTCanvasParam } from "contracts/PDProtocolCanvas.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

contract PDCanvasTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    function setUp() public {
        super.setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_create_canvas_shouldWork() public {
        bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes memory signature;
        DeployHelper.CreateDaoParam memory param;
        string memory tokenUri = "test token uri";
        param.canvasId = canvasId;

        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 50;
        param.daoUri = tokenUri;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        //-----------------------
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, param.daoUri, 0.01 ether);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        signature = abi.encodePacked(r, s, v);

        CreateCanvasAndMintNFTParam memory vars;
        vars.daoId = daoId;
        vars.canvasId = canvasId;
        vars.canvasUri = "test canvas2 uri";
        vars.to = daoCreator.addr;
        vars.tokenUri = "test token2 uri";
        vars.signature = signature;

        vars.flatPrice = 0.01 ether;
        vars.proof = new bytes32[](0);
        vars.canvasProof = new bytes32[](0);
        vars.nftOwner = nftMinter.addr;
        vm.expectRevert(abi.encodeWithSelector(D4ACanvasAlreadyExist.selector, canvasId));
        protocol.createCanvasAndMintNFT{ value: 0.01 ether }(vars);
    }

    function test_create_canvas_expectRevert() public {
        PDProtocolCanvas protocolCanvasImpl = new PDProtocolCanvas();
        vm.startPrank(protocolOwner.addr);
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolCanvasImpl));

        bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes memory signature;
        DeployHelper.CreateDaoParam memory param;
        string memory tokenUri = "test token uri";
        param.canvasId = canvasId;

        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 50;
        param.daoUri = tokenUri;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        //-----------------------
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, param.daoUri, 0.01 ether);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        signature = abi.encodePacked(r, s, v);

        CreateCanvasAndMintNFTCanvasParam memory vars;
        vars.daoId = daoId;
        vars.canvasId = canvasId;
        vars.canvasUri = "test canvas2 uri";
        vars.to = daoCreator.addr;
        vars.signature = signature;

        vars.flatPrice = 0.01 ether;
        vars.proof = new bytes32[](0);
        vars.canvasProof = new bytes32[](0);
        vars.nftOwner = nftMinter.addr;

        //here interface need change IPDProtocol  add function
        //IPDProtocol need change as import struct, change D4Struct
        vars.tokenUri = "test token2 uri";
        protocol.createCanvasAndMintNFT{ value: 0.01 ether }(vars);

        vars.tokenUri = "test token3 uri";
        protocol.createCanvasAndMintNFT{ value: 0.01 ether }(vars);

        vars.tokenUri = "test token4 uri";
        protocol.createCanvasAndMintNFT{ value: 0.01 ether }(vars);
    }
}
