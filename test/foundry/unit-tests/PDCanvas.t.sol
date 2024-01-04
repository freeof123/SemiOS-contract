// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";
import { ERC20SigUtils } from "test/foundry/utils/ERC20SigUtils.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

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

    function test_create_canvas_newLogic_shouldWork() public {
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

        //q1.
        //here interface need change IPDProtocol  add function
        //IPDProtocol need change as import struct, change D4Struct

        vars.tokenUri = "test token2 uri";
        protocol.createCanvasAndMintNFT{ value: 0.01 ether }(vars);

        vars.tokenUri = "test token3 uri";
        protocol.createCanvasAndMintNFT{ value: 0.01 ether }(vars);

        vars.tokenUri = "test token4 uri";
        protocol.createCanvasAndMintNFT{ value: 0.01 ether }(vars);
    }

    function test_erc20Payment_without_approve() public {
        PDProtocolCanvas protocolCanvasImpl = new PDProtocolCanvas();
        vm.startPrank(protocolOwner.addr);
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolCanvasImpl));

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = param.canvasId;
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
        // vm.prank(nftMinter.addr);
        // _testERC20.approve(address(protocol), 0.01 ether);

        startHoax(nftMinter.addr);
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, "B", 0.01 ether);
        bytes memory sig;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
        sig = abi.encodePacked(r, s, v);

        ERC20SigUtils erc20SigUtils = new ERC20SigUtils(address(_testERC20));
        digest = erc20SigUtils.getTypedDataHash(nftMinter.addr, address(protocol), 1e6 ether, block.timestamp + 1 days);
        (v, r, s) = vm.sign(nftMinter.key, digest);
        // IERC20Permit(_testERC20).permit(nftMinter.addr, address(protocol), 1e6 ether, block.timestamp + 1 days, v, r,
        // s);
        uint256 value = 0;
        ERC20PermitParam memory erc20PermitParam =
            ERC20PermitParam({ r: r, s: s, v: v, deadline: block.timestamp + 1 days });

        protocol.mintNFT{ value: value }(daoId, canvasId, "B", new bytes32[](0), 0.01 ether, sig, erc20PermitParam);
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0.99 ether);
    }

    function test_erc20Payment_without_approve_expectRevert_expiredDeadline() public {
        PDProtocolCanvas protocolCanvasImpl = new PDProtocolCanvas();
        vm.startPrank(protocolOwner.addr);
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolCanvasImpl));

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = param.canvasId;
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

        startHoax(nftMinter.addr);
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, "B", 0.01 ether);
        bytes memory sig;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
        sig = abi.encodePacked(r, s, v);

        uint256 deadline = block.timestamp + 1 days;
        ERC20SigUtils erc20SigUtils = new ERC20SigUtils(address(_testERC20));
        digest = erc20SigUtils.getTypedDataHash(nftMinter.addr, address(protocol), 1e6 ether, deadline);
        (v, r, s) = vm.sign(nftMinter.key, digest);
        ERC20PermitParam memory erc20PermitParam = ERC20PermitParam({ r: r, s: s, v: v, deadline: deadline });
        uint256 value = 0;
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert("ERC20Permit: expired deadline");
        protocol.mintNFT{ value: value }(daoId, canvasId, "B", new bytes32[](0), 0.01 ether, sig, erc20PermitParam);
        //value could be maxSupply
    }

    function test_erc20Payment_without_approve_expectRevert_invalidSignature() public {
        PDProtocolCanvas protocolCanvasImpl = new PDProtocolCanvas();
        vm.startPrank(protocolOwner.addr);
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolCanvasImpl));

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = param.canvasId;
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

        startHoax(nftMinter.addr);
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, "B", 0.01 ether);
        bytes memory sig;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
        sig = abi.encodePacked(r, s, v);

        uint256 deadline = block.timestamp + 1 days;
        ERC20SigUtils erc20SigUtils = new ERC20SigUtils(address(_testERC20));
        digest = erc20SigUtils.getTypedDataHash(nftMinter.addr, address(protocol), 1e6 ether, deadline);
        (v, r, s) = vm.sign(nftMinter.key, digest);
        ERC20PermitParam memory erc20PermitParam = ERC20PermitParam({ r: r, s: s, v: v, deadline: deadline - 1 days });
        uint256 value = 0;
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert("ERC20Permit: expired deadline");
        protocol.mintNFT{ value: value }(daoId, canvasId, "B", new bytes32[](0), 0.01 ether, sig, erc20PermitParam);
        //value could be maxSupply
    }
}
