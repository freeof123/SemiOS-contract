// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";
import { ERC20SigUtils } from "test/foundry/utils/ERC20SigUtils.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

// import { PDProtocolCanvas } from "contracts/PDProtocolCanvas.sol";
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
        vars.canvasCreator = daoCreator.addr;
        vars.tokenUri = "test token2 uri";
        vars.nftSignature = signature;

        vars.flatPrice = 0.01 ether;
        vars.proof = new bytes32[](0);
        vars.canvasProof = new bytes32[](0);
        vars.nftOwner = nftMinter.addr;
        // vm.expectRevert(abi.encodeWithSelector(D4ACanvasAlreadyExist.selector, canvasId));
        protocol.mintNFT{ value: 0.01 ether }(vars);
    }

    function test_create_canvas_newLogic_shouldWork() public {
        //deploy a new contract for implementation
        // PDProtocolCanvas protocolCanvasImpl = new PDProtocolCanvas();
        // vm.startPrank(protocolOwner.addr);
        // D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolCanvasImpl));

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
        vars.canvasUri = "test canvas2 uri2";
        vars.canvasCreator = daoCreator.addr;
        vars.nftSignature = signature;

        vars.flatPrice = 0.01 ether;
        vars.proof = new bytes32[](0);
        vars.canvasProof = new bytes32[](0);
        vars.nftOwner = nftMinter.addr;

        vars.tokenUri = "test token2 uri";
        protocol.mintNFT{ value: 0.01 ether }(vars);

        vars.tokenUri = "test token3 uri";
        protocol.mintNFT{ value: 0.01 ether }(vars);

        vars.tokenUri = "test token4 uri";
        protocol.mintNFT{ value: 0.01 ether }(vars);
    }

    function test_outputPayment_without_approve() public {
        // PDProtocolCanvas protocolCanvasImpl = new PDProtocolCanvas();
        // vm.startPrank(protocolOwner.addr);
        // D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolCanvasImpl));

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 50;
        param.selfRewardOutputRatio = 10_000;
        param.outputPaymentMode = true;
        param.thirdPartyToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(nftMinter.addr, 1 ether);

        startHoax(nftMinter.addr);
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, "token uri 2", 0.01 ether);
        bytes memory nftSig;
        bytes memory erc20Sig;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
        nftSig = abi.encodePacked(r, s, v);

        ERC20SigUtils erc20SigUtils = new ERC20SigUtils(address(_testERC20));
        digest = erc20SigUtils.getTypedDataHash(nftMinter.addr, address(protocol), 0.01 ether, block.timestamp + 1 days);
        (v, r, s) = vm.sign(nftMinter.key, digest);
        uint256 value = 0;
        erc20Sig = abi.encode(v, r, s);

        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId;
        mintNftTransferParam.tokenUri = "token uri 2";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = nftSig;
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = erc20Sig;
        mintNftTransferParam.deadline = block.timestamp + 1 days;
        protocol.mintNFT{ value: value }(mintNftTransferParam);
        erc20SigUtils.incNonce(nftMinter.addr);
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0.99 ether);
    }

    function test_outputPayment_without_approve_expectRevert_invalidSignature() public {
        // PDProtocolCanvas protocolCanvasImpl = new PDProtocolCanvas();
        // vm.startPrank(protocolOwner.addr);
        // D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolCanvasImpl));

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 50;
        param.selfRewardOutputRatio = 10_000;
        param.outputPaymentMode = true;
        param.thirdPartyToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(nftMinter.addr, 1 ether);

        startHoax(nftMinter.addr);
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, "token uri 2", 0.01 ether);
        bytes memory nftSig;
        bytes memory erc20Sig;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
        nftSig = abi.encodePacked(r, s, v);

        uint256 deadline = block.timestamp + 1 days;
        ERC20SigUtils erc20SigUtils = new ERC20SigUtils(address(_testERC20));
        digest = erc20SigUtils.getTypedDataHash(nftMinter.addr, address(protocol), 0.01 ether, deadline);
        (v, r, s) = vm.sign(nftMinter.key, digest);
        erc20Sig = abi.encode(v, r, s);
        uint256 value = 0;

        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId;
        mintNftTransferParam.tokenUri = "token uri 2";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = nftSig;
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = erc20Sig;
        mintNftTransferParam.deadline = deadline + 1 days;

        vm.warp(block.timestamp + 2 days);
        vm.expectRevert("ERC20Permit: invalid signature");
        protocol.mintNFT{ value: value }(mintNftTransferParam);
    }

    function test_outputPayment_without_approve_expectRevert_expiredDeadline() public {
        // PDProtocolCanvas protocolCanvasImpl = new PDProtocolCanvas();
        // vm.startPrank(protocolOwner.addr);
        // D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolCanvasImpl));

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 50;
        param.selfRewardOutputRatio = 10_000;
        param.outputPaymentMode = true;
        param.thirdPartyToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(nftMinter.addr, 1 ether);

        startHoax(nftMinter.addr);
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, "token uri 2", 0.01 ether);
        bytes memory nftSig;
        bytes memory erc20Sig;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
        nftSig = abi.encodePacked(r, s, v);

        uint256 deadline = block.timestamp + 1 days;
        ERC20SigUtils erc20SigUtils = new ERC20SigUtils(address(_testERC20));
        digest = erc20SigUtils.getTypedDataHash(nftMinter.addr, address(protocol), 0.01 ether, deadline);
        (v, r, s) = vm.sign(nftMinter.key, digest);
        erc20Sig = abi.encode(v, r, s);
        uint256 value = 0;

        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId;
        mintNftTransferParam.tokenUri = "token uri 2";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = nftSig;
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = erc20Sig;
        mintNftTransferParam.deadline = deadline;

        vm.warp(block.timestamp + 2 days);
        vm.expectRevert("ERC20Permit: expired deadline");
        protocol.mintNFT{ value: value }(mintNftTransferParam);
    }

    function test_outputPayment_twice_permit() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.daoUri = "topup dao uri";
        param.mintableRound = 50;
        param.selfRewardOutputRatio = 10_000;
        param.outputPaymentMode = true;
        param.thirdPartyToken = address(_testERC20);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        vm.prank(protocolOwner.addr);
        _testERC20.transfer(nftMinter.addr, 1 ether);

        startHoax(nftMinter.addr);
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, "token uri 2", 0.01 ether);
        bytes memory nftSig;
        bytes memory erc20Sig;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
        nftSig = abi.encodePacked(r, s, v);

        ERC20SigUtils erc20SigUtils = new ERC20SigUtils(address(_testERC20));
        digest = erc20SigUtils.getTypedDataHashV2(
            nftMinter.addr, address(protocol), 0.01 ether, block.timestamp + 1 days, address(_testERC20)
        );
        (v, r, s) = vm.sign(nftMinter.key, digest);
        uint256 value = 0;
        erc20Sig = abi.encode(v, r, s);

        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId;
        mintNftTransferParam.tokenUri = "token uri 2";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = nftSig;
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = erc20Sig;
        mintNftTransferParam.deadline = block.timestamp + 1 days;
        protocol.mintNFT{ value: value }(mintNftTransferParam);
        // erc20SigUtils.incNonce(nftMinter.addr);
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0.99 ether);

        // mint again using permit
        digest = erc20SigUtils.getTypedDataHashV2(
            nftMinter.addr, address(protocol), 0.01 ether, block.timestamp + 1 days, address(_testERC20)
        );
        (v, r, s) = vm.sign(nftMinter.key, digest);
        erc20Sig = abi.encode(v, r, s);

        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId;
        mintNftTransferParam.tokenUri = "token uri 3";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = nftSig;
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = erc20Sig;
        mintNftTransferParam.deadline = block.timestamp + 1 days;
        protocol.mintNFT{ value: value }(mintNftTransferParam);
        // erc20SigUtils.incNonce(nftMinter.addr);
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0.98 ether);
    }
}
