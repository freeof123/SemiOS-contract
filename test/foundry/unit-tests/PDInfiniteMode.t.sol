// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

import "forge-std/Test.sol";

contract PDInfiniteModeTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_daoInfiniteModeBasic() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.infiniteMode = true;
        param.noPermission = true;
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.daoUri = "test dao uri 2";
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator.addr);

        SetChildrenParam memory vars;
        vars.childrenDaoId = new bytes32[](1);
        vars.childrenDaoId[0] = daoId2;
        vars.erc20Ratios = new uint256[](1);
        vars.erc20Ratios[0] = 5000;
        vars.ethRatios = new uint256[](1);
        vars.ethRatios[0] = 5000;
        vars.selfRewardRatioERC20 = 5000;
        vars.selfRewardRatioETH = 5000;
        protocol.setChildren(daoId, vars);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            50_000_000 ether
        );
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(2);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0.0035 ether
        );
        protocol.setDaoUnifiedPrice(daoId, 0.02 ether);
        mintNftTransferParam.tokenUri = "nft2";
        mintNftTransferParam.flatPrice = 0.02 ether;
        protocol.mintNFT{ value: 0.02 ether }(mintNftTransferParam);
        vm.roll(3);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0.007 ether
        );
    }

    function test_daoMintThenTurnOnInfiniteMode() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 10;
        param.selfRewardRatioERC20 = 10_000;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        assertEq(protocol.getDaoAssetPool(daoId).balance, 0.0035 ether);
        protocol.changeDaoInfiniteMode(daoId, 0);
        protocol.setDaoUnifiedPrice(daoId, 0.02 ether);
        mintNftTransferParam.tokenUri = "nft2";
        mintNftTransferParam.flatPrice = 0.02 ether;
        protocol.mintNFT{ value: 0.02 ether }(mintNftTransferParam);
        assertEq(protocol.getDaoAssetPool(daoId).balance, 0.0035 ether + 0.007 ether);
        // aeth amount
        vm.roll(2);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            45_000_000 ether
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0.0105 ether
        );
    }

    function test_daoMintThenTurnOnInfiniteMode_jackpot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 10;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        protocol.changeDaoInfiniteMode(daoId, 0);
        protocol.setDaoUnifiedPrice(daoId, 0.02 ether);
        mintNftTransferParam.tokenUri = "nft2";
        mintNftTransferParam.flatPrice = 0.02 ether;
        protocol.mintNFT{ value: 0.02 ether }(mintNftTransferParam);
        vm.roll(2);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            45_000_000 ether
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0.0105 ether
        );
    }

    function test_daoMintThenTurnOnInfiniteMode_jackpot2() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 10;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        vm.roll(2);

        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        protocol.changeDaoInfiniteMode(daoId, 0);
        protocol.setDaoUnifiedPrice(daoId, 0.02 ether);

        mintNftTransferParam.tokenUri = "nft2";
        mintNftTransferParam.flatPrice = 0.02 ether;
        protocol.mintNFT{ value: 0.02 ether }(mintNftTransferParam);
        vm.roll(3);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            40_000_000 ether
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0.0105 ether
        );
    }

    function test_daoMintTurnOnThenTurnOffInfiniteMode() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 10;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = false;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        vm.roll(3);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            5_000_000 ether
        );
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        protocol.changeDaoInfiniteMode(daoId, 0);

        vm.roll(5);

        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            45_000_000 ether
        );

        mintNftTransferParam.tokenUri = "nft2";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);

        vm.roll(8);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0 ether
        );

        mintNftTransferParam.tokenUri = "nft3";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(13);
        protocol.changeDaoInfiniteMode(daoId, 20);
        protocol.setInitialTokenSupplyForSubDao(daoId, 10_000_000 ether);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            500_000 ether
        );
        //0.035 * 3 / 20
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            525_000_000_000_000
        );
    }

    function test_daoMintTurnOnThenTurnOffInfiniteModeJackPot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 10;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        vm.roll(3);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            15_000_000 ether
        );
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        protocol.changeDaoInfiniteMode(daoId, 0);

        vm.roll(5);

        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            35_000_000 ether
        );

        mintNftTransferParam.tokenUri = "nft2";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);

        vm.roll(8);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0 ether
        );
        mintNftTransferParam.tokenUri = "nft3";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(13);
        protocol.changeDaoInfiniteMode(daoId, 20);

        protocol.setInitialTokenSupplyForSubDao(daoId, 10_000_000 ether);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            500_000 ether
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            525_000_000_000_000
        );
        mintNftTransferParam.tokenUri = "nft4";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(15);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            1_000_000 ether
        );
    }

    function test_daoMintInLastRoundThenTurnOffInfiniteModeJackPot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 10;
        param.infiniteMode = true;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        vm.roll(3);
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        protocol.changeDaoInfiniteMode(daoId, 20);
        assertEq(protocol.getDaoRemainingRound(daoId), 20);
        protocol.setInitialTokenSupplyForSubDao(daoId, 10_000_000 ether);

        vm.roll(5);
        assertEq(protocol.getDaoRemainingRound(daoId), 18);
        //since round 3 is active, so denominator is 19, numerator is 2
        uint256 a = uint256(10_000_000 ether * 2) / 19;
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            a
        );
    }

    function test_daoMintRoundBeforeLastThenTurnOffInfiniteModeJackPot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 10;
        param.infiniteMode = true;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        vm.roll(3);
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(4);
        protocol.changeDaoInfiniteMode(daoId, 20);
        assertEq(protocol.getDaoRemainingRound(daoId), 20);
        protocol.setInitialTokenSupplyForSubDao(daoId, 10_000_000 ether);

        vm.roll(5);
        assertEq(protocol.getDaoRemainingRound(daoId), 19);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            1_000_000 ether
        );
    }

    function test_daoDeadThenTurnOnInfiniteMode_roundShouldRestartNojack() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 1;
        param.duration = 3 ether;
        param.infiniteMode = false;
        param.selfRewardRatioERC20 = 10_000;

        bytes32 daoId = super._createDaoForFunding(param, address(this));

        vm.roll(31);
        assertEq(protocol.getDaoRemainingRound(daoId), 1, "a11");
        assertEq(protocol.getDaoCurrentRound(daoId), 11, "a12");
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = param.canvasId;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(35);
        protocol.changeDaoInfiniteMode(daoId, 0);
        assertEq(protocol.getDaoPassedRound(daoId), 1, "a13");
        assertEq(protocol.getDaoCurrentRound(daoId), 12, "a14");
        assertEq(protocol.getDaoRemainingRound(daoId), 1, "a15");
        //restart at block 35, round is 12
        vm.roll(37);
        //(35, 36, 37) all in round 12
        assertEq(protocol.getDaoPassedRound(daoId), 1, "a21");
        assertEq(protocol.getDaoCurrentRound(daoId), 12, "a22");
        assertEq(protocol.getDaoRemainingRound(daoId), 1, "a23");
        vm.roll(38);
        // enter round 13
        assertEq(protocol.getDaoPassedRound(daoId), 1, "a31");
        assertEq(protocol.getDaoCurrentRound(daoId), 13, "a32");
        assertEq(protocol.getDaoRemainingRound(daoId), 1, "a33");
        vm.roll(65);
        // enter round 22
        protocol.changeDaoInfiniteMode(daoId, 10);
        assertEq(protocol.getDaoPassedRound(daoId), 1, "a42");
        assertEq(protocol.getDaoCurrentRound(daoId), 22, "a43");
        assertEq(protocol.getDaoRemainingRound(daoId), 10, "a44");
    }

    function test_daoDeadThenTurnOnInfiniteMode_roundShouldRestartJackPot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.duration = 3 ether;
        param.infiniteMode = false;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = super._createDaoForFunding(param, address(this));

        vm.roll(31);
        assertEq(protocol.getDaoRemainingRound(daoId), 0, "a11");
        assertEq(protocol.getDaoCurrentRound(daoId), 11, "a12");

        vm.roll(35);
        protocol.changeDaoInfiniteMode(daoId, 0);
        assertEq(protocol.getDaoPassedRound(daoId), 11, "a13");
        assertEq(protocol.getDaoCurrentRound(daoId), 12, "a14");
        assertEq(protocol.getDaoRemainingRound(daoId), 1, "a15");
        //restart at block 35, round is 12
        vm.roll(37);
        assertEq(protocol.getDaoPassedRound(daoId), 11, "a21");
        assertEq(protocol.getDaoCurrentRound(daoId), 12, "a22");
        assertEq(protocol.getDaoRemainingRound(daoId), 1, "a23");
        vm.roll(38);
        // enter round 13
        assertEq(protocol.getDaoPassedRound(daoId), 12, "a31");
        assertEq(protocol.getDaoCurrentRound(daoId), 13, "a32");
        assertEq(protocol.getDaoRemainingRound(daoId), 1, "a33");
        vm.roll(65);
        protocol.changeDaoInfiniteMode(daoId, 10);
        assertEq(protocol.getDaoPassedRound(daoId), 21, "a42");
        assertEq(protocol.getDaoCurrentRound(daoId), 22, "a43");
        assertEq(protocol.getDaoRemainingRound(daoId), 10, "a44");
    }

    function test_infiniteModeShouldNotAffectPriceInfo() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.infiniteMode = false;
        param.selfRewardRatioERC20 = 10_000;
        param.uniPriceModeOff = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.08 ether);
        vm.prank(daoCreator.addr);
        protocol.changeDaoInfiniteMode(daoId, 0);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.08 ether);
        vm.roll(2);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.04 ether);
        vm.roll(3);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.02 ether);
        vm.prank(daoCreator.addr);

        protocol.changeDaoInfiniteMode(daoId, 10);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.02 ether);
        vm.roll(4);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
    }

    function test_daoDeadThenTurnOnInfiniteMode_shouldAffectPriceInfo() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 1;
        param.infiniteMode = false;
        param.selfRewardRatioERC20 = 10_000;
        param.uniPriceModeOff = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
            ),
            0,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.08 ether);
        vm.roll(2);
        vm.prank(daoCreator.addr);
        protocol.changeDaoInfiniteMode(daoId, 0);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        // vm.roll(3);
        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether, "a11");
        // vm.roll(4);
        // assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether, "a12");
    }

    function test_daoInfiniteMode_transfer_noJack() public {
        uint256 erc20Reward;
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 5;
        param.selfRewardRatioERC20 = 10_000;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        address token = protocol.getDaoToken(daoId);
        vm.roll(2);
        startHoax(nftMinter.addr);
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(4);
        mintNftTransferParam.tokenUri = "nft2";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(5);
        mintNftTransferParam.tokenUri = "nft3";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.stopPrank();
        vm.roll(6);
        // (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        // assertEq(erc20Reward, 30_000_000 ether * 0.08, "test_daoInfiniteMode_transfer_noJack test 1");
        (erc20Reward,) = protocol.claimDaoNftOwnerReward(daoId);
        assertEq(erc20Reward, 30_000_000 ether * 0.7, "test_daoInfiniteMode_transfer_noJack test 2");
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(erc20Reward, 30_000_000 ether * 0.2, "test_daoInfiniteMode_transfer_noJack test 3");

        //from normal to inifiteMode
        protocol.changeDaoInfiniteMode(daoId, 0);
        vm.roll(7);
        startHoax(nftMinter.addr);
        mintNftTransferParam.tokenUri = "nft4";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(8);
        mintNftTransferParam.tokenUri = "nft5";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.stopPrank();
        vm.roll(10);
        // (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        // assertEq(erc20Reward, 20_000_000 ether * 0.08, "test_daoInfiniteMode_transfer_noJack test 4");
        (erc20Reward,) = protocol.claimDaoNftOwnerReward(daoId);
        assertEq(erc20Reward, 20_000_000 ether * 0.7, "test_daoInfiniteMode_transfer_noJack test 5");
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(erc20Reward, 20_000_000 ether * 0.2, "test_daoInfiniteMode_transfer_noJack test 6");

        //from inifiteMode to normal
        protocol.changeDaoInfiniteMode(daoId, 3);
        deal(token, protocol.getDaoAssetPool(daoId), 300 ether);
        startHoax(nftMinter.addr);
        mintNftTransferParam.tokenUri = "nft6";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);

        vm.roll(12);
        mintNftTransferParam.tokenUri = "nft7";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.stopPrank();
        (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(
            erc20Reward, (100 + 20_000_000 + 30_000_000) * 1e18 * 0.08, "test_daoInfiniteMode_transfer_noJack test 7"
        );
        (erc20Reward,) = protocol.claimDaoNftOwnerReward(daoId);
        assertEq(erc20Reward, 100 ether * 0.7, "test_daoInfiniteMode_transfer_noJack test 8");
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(erc20Reward, 100 ether * 0.2, "test_daoInfiniteMode_transfer_noJack test 9");
    }

    function test_daoInfiniteMode_transfer_Jackpot() public {
        uint256 erc20Reward;
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.noPermission = true;
        param.mintableRound = 5;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        address token = protocol.getDaoToken(daoId);
        vm.roll(2);
        startHoax(nftMinter.addr);
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(4);
        mintNftTransferParam.tokenUri = "nft2";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(5);
        mintNftTransferParam.tokenUri = "nft3";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.stopPrank();
        vm.roll(6);
        // (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        // assertEq(erc20Reward, 50_000_000 ether * 0.08, "test_daoInfiniteMode_transfer_Jackpot test 1");
        (erc20Reward,) = protocol.claimDaoNftOwnerReward(daoId);
        assertEq(erc20Reward, 50_000_000 ether * 0.7, "test_daoInfiniteMode_transfer_Jackpot test 2");
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(erc20Reward, 50_000_000 ether * 0.2, "test_daoInfiniteMode_transfer_Jackpot test 3");

        //from normal to inifiteMode
        protocol.changeDaoInfiniteMode(daoId, 0);
        deal(token, protocol.getDaoAssetPool(daoId), 1000 ether);
        vm.roll(7);
        startHoax(nftMinter.addr);
        mintNftTransferParam.tokenUri = "nft4";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.roll(8);
        mintNftTransferParam.tokenUri = "nft5";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.stopPrank();
        vm.roll(10);
        // (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        // assertEq(erc20Reward, 1000 ether * 0.08, "test_daoInfiniteMode_transfer_Jackpot test 4");
        (erc20Reward,) = protocol.claimDaoNftOwnerReward(daoId);
        assertEq(erc20Reward, 1000 ether * 0.7, "test_daoInfiniteMode_transfer_Jackpot test 5");
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(erc20Reward, 1000 ether * 0.2, "test_daoInfiniteMode_transfer_Jackpot test 6");

        //from inifiteMode to normal
        protocol.changeDaoInfiniteMode(daoId, 3);
        deal(token, protocol.getDaoAssetPool(daoId), 300 ether);
        startHoax(nftMinter.addr);
        mintNftTransferParam.tokenUri = "nft6";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);

        vm.roll(12);
        mintNftTransferParam.tokenUri = "nft7";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        vm.stopPrank();
        vm.roll(13);
        (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(erc20Reward, (300 + 50_000_000 + 1000) * 1e18 * 0.08, "test_daoInfiniteMode_transfer_Jackpot test 7");
        (erc20Reward,) = protocol.claimDaoNftOwnerReward(daoId);
        assertEq(erc20Reward, 300 ether * 0.7, "test_daoInfiniteMode_transfer_Jackpot test 8");
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(erc20Reward, 300 ether * 0.2, "test_daoInfiniteMode_transfer_Jackpot test 9");
    }

    receive() external payable { }
}
