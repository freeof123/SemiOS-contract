// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

import "forge-std/Test.sol";

contract ProtoDaoResurrectionTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_daoResurrection_basic() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 10;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, address(this));
        protocol.setDaoRemainingRound(daoId, 1);
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

        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0.01 ether * 3500 / 10_000,
            "Distribution about ETH at first amount should be 0.01 * 35%"
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            50_000_000 ether,
            "Distribution about erc20 token at first amount should be 50M"
        );
        //dao become dead
        vm.roll(2);
        vm.expectRevert(ExceedMaxMintableRound.selector);
        hoax(nftMinter.addr);
        mintNftTransferParam.tokenUri = "nft2";
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0,
            "Distribution about ETH should be 0 before resurrection"
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0 ether,
            "Distribution about erc20 token should be 0 before resurrection"
        );
        //dao had dead and resurrect
        protocol.setDaoRemainingRound(daoId, 20);
        assertEq(protocol.getDaoCurrentRound(daoId), 2);
        assertEq(protocol.getDaoRemainingRound(daoId), 20);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            protocol.getDaoAssetPool(daoId).balance / 20,
            "Distribution about ETH should be 1/20 of asset pool"
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            2_500_000 ether,
            "Distribution about erc20 token should be 2.5M after resurrection"
        );
    }

    function test_daoResurrection_multiRounds_noJack() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 5;
        param.noPermission = true;
        param.selfRewardRatioERC20 = 10_000;

        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);
        uint256 erc20Reward;
        super._mintNft(
            daoId, param.canvasId, string.concat("test token uri1"), 0.01 ether, canvasCreator.key, nftMinter.addr
        );
        for (uint256 i = 2; i < param.mintableRound + 1; i++) {
            vm.roll(i);
            (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
            assertEq(
                erc20Reward,
                10_000_000 * 0.08 ether,
                string.concat("test_daoResurrection_multiRounds_noJack dead zero nftMinter reward _", vm.toString(i))
            );
            (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
            assertEq(
                erc20Reward,
                10_000_000 * 0.2 ether,
                string.concat(
                    "test_daoResurrection_multiRounds_noJack dead zero canvasCreator reward _", vm.toString(i)
                )
            );
            (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
            assertEq(
                erc20Reward,
                10_000_000 * 0.7 ether,
                string.concat("test_daoResurrection_multiRounds_noJack dead zero daoCreator reward _", vm.toString(i))
            );

            super._mintNft(
                daoId,
                param.canvasId,
                string.concat("test token uri", vm.toString(i + 2)),
                0.01 ether,
                canvasCreator.key,
                nftMinter.addr
            );
        }

        vm.roll(6);
        (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(
            erc20Reward,
            10_000_000 * 0.08 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead zero nftMinter reward _6")
        );
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(
            erc20Reward,
            10_000_000 * 0.2 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead zero canvasCreator reward _6")
        );
        (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
        assertEq(
            erc20Reward,
            10_000_000 * 0.7 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead zero daoCreator reward _6")
        );

        //dead one
        assertEq(
            protocol.getDaoRemainingRound(daoId),
            0,
            "test_daoResurrection_multiRounds_noJack dead one remaing round start"
        );
        deal(token, protocol.getDaoAssetPool(daoId), 100 ether);
        vm.prank(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 10);
        for (uint256 i = 0; i < 10; i++) {
            vm.roll(6 + i);
            super._mintNft(
                daoId,
                param.canvasId,
                string.concat("test token uri", vm.toString(6 + i + 2)),
                0.01 ether,
                canvasCreator.key,
                nftMinter.addr
            );
        }
        vm.roll(16);
        assertEq(
            protocol.getDaoRemainingRound(daoId),
            0,
            "test_daoResurrection_multiRounds_noJack dead one remaing round end"
        );

        vm.roll(106);
        (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(
            erc20Reward,
            100 * 0.08 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead 1 nftMinter reward end")
        );
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(
            erc20Reward,
            100 * 0.2 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead 1 canvasCreator reward end")
        );
        (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
        assertEq(
            erc20Reward,
            100 * 0.7 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead 1 daoCreator reward end")
        );

        //dead two
        assertEq(
            protocol.getDaoRemainingRound(daoId),
            0,
            "test_daoResurrection_multiRounds_noJack dead two remaing round start"
        );
        vm.prank(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 5);
        deal(token, protocol.getDaoAssetPool(daoId), 50 ether);
        super._mintNft(daoId, param.canvasId, "test token uri 106", 0.01 ether, canvasCreator.key, nftMinter.addr);

        for (uint256 i = 1; i < 5; i++) {
            vm.roll(106 + i);
            (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
            assertEq(
                erc20Reward,
                10 * 0.08 ether,
                string.concat(
                    "test_daoResurrection_multiRounds_noJack dead 2 nftMinter reward _ ", vm.toString(106 + i)
                )
            );
            (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
            assertEq(
                erc20Reward,
                10 * 0.2 ether,
                string.concat(
                    "test_daoResurrection_multiRounds_noJack dead 2 canvasCreator reward _ ", vm.toString(106 + i)
                )
            );
            (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
            assertEq(
                erc20Reward,
                10 * 0.7 ether,
                string.concat(
                    "test_daoResurrection_multiRounds_noJack dead 2 daoCreator reward _ ", vm.toString(106 + i)
                )
            );

            super._mintNft(
                daoId,
                param.canvasId,
                string.concat("test token uri", vm.toString(106 + i + 2)),
                0.01 ether,
                canvasCreator.key,
                nftMinter.addr
            );
        }
        vm.roll(112);
        assertEq(
            protocol.getDaoRemainingRound(daoId),
            0,
            "test_daoResurrection_multiRounds_noJack dead two remaing round end"
        );

        (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(erc20Reward, 10 * 0.08 ether, "test_daoResurrection_multiRounds_noJack dead 2 nftMinter reward _ 112");
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(erc20Reward, 10 * 0.2 ether, "test_daoResurrection_multiRounds_noJack dead 2 nftMinter reward _ 112");
        (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
        assertEq(erc20Reward, 10 * 0.7 ether, "test_daoResurrection_multiRounds_noJack dead 2 nftMinter reward _ 112");
        assertEq(IERC20(token).balanceOf(nftMinter.addr), (50_000_000 + 100 + 50) * 0.08 ether);
        assertEq(IERC20(token).balanceOf(daoCreator.addr), (50_000_000 + 100 + 50) * 0.9 ether);
    }

    function test_daoResurrection_claim_2times_noJack() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 5;
        param.noPermission = true;
        param.selfRewardRatioERC20 = 10_000;

        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = param.canvasId;
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        //erc20 = 50000000 ether
        for (uint256 i = 0; i < 5; i++) {
            hoax(nftMinter.addr);
            mintNftTransferParam.tokenUri = string.concat("nft", vm.toString(i));
            protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
            assertEq(
                IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)),
                50_000_000 ether - (i + 1) * 10_000_000 ether,
                string.concat("test_daoResurrection_claim_2times_noJack Item balance check_", vm.toString(i))
            );
            vm.roll(i + 2);
        }
        vm.roll(8);
        assertEq(protocol.getDaoRemainingRound(daoId), 0);

        vm.prank(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 10);

        deal(token, protocol.getDaoAssetPool(daoId), 100 ether);

        super._mintNft(
            daoId, param.canvasId, string.concat("test token 8"), 0.01 ether, canvasCreator.key, nftMinter.addr
        );

        vm.roll(9);
        super._mintNft(
            daoId, param.canvasId, string.concat("test token 9"), 0.01 ether, canvasCreator.key, nftMinter.addr
        );

        vm.roll(10);

        // round 1-5: 50000000 * 0.08
        // round 8-9: 10 * 0.08 * 2
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(
            IERC20(token).balanceOf(nftMinter.addr),
            4_000_000 ether + 1.6 ether,
            "test_daoResurrection_claim_2times_noJack nft minter reward check"
        );
        protocol.claimDaoCreatorReward(daoId);
        // 50000000 * 0.7 + 10 * 0.7 *2
        assertEq(
            IERC20(token).balanceOf(daoCreator.addr),
            35_000_000 ether + 14 ether,
            "test_daoResurrection_claim_2times_noJack dao creator reward check"
        );
        protocol.claimCanvasReward(param.canvasId);
        // 50000000 * 0.2 + 10 * 0.2 * 2
        assertEq(
            IERC20(token).balanceOf(daoCreator.addr),
            35_000_000 ether + 14 ether + 10_000_000 ether + 4 ether,
            "test_daoResurrection_claim_2times_noJack dao creator reward check"
        );
    }

    function test_daoResurrection_multiRounds_Jackpot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 5;
        param.noPermission = true;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);
        uint256 erc20Reward;
        super._mintNft(
            daoId, param.canvasId, string.concat("test token uri1"), 0.01 ether, canvasCreator.key, nftMinter.addr
        );
        for (uint256 i = 2; i < param.mintableRound + 1; i++) {
            vm.roll(i);
            (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
            assertEq(
                erc20Reward,
                10_000_000 * 0.08 ether,
                string.concat("test_daoResurrection_multiRounds_noJack dead zero nftMinter reward _", vm.toString(i))
            );
            (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
            assertEq(
                erc20Reward,
                10_000_000 * 0.2 ether,
                string.concat(
                    "test_daoResurrection_multiRounds_noJack dead zero canvasCreator reward _", vm.toString(i)
                )
            );
            (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
            assertEq(
                erc20Reward,
                10_000_000 * 0.7 ether,
                string.concat("test_daoResurrection_multiRounds_noJack dead zero daoCreator reward _", vm.toString(i))
            );

            super._mintNft(
                daoId,
                param.canvasId,
                string.concat("test token uri", vm.toString(i + 2)),
                0.01 ether,
                canvasCreator.key,
                nftMinter.addr
            );
        }

        vm.roll(6);
        (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(
            erc20Reward,
            10_000_000 * 0.08 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead zero nftMinter reward _6")
        );
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(
            erc20Reward,
            10_000_000 * 0.2 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead zero canvasCreator reward _6")
        );
        (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
        assertEq(
            erc20Reward,
            10_000_000 * 0.7 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead zero daoCreator reward _6")
        );

        //dead one
        assertEq(
            protocol.getDaoRemainingRound(daoId),
            0,
            "test_daoResurrection_multiRounds_noJack dead one remaing round start"
        );
        deal(token, protocol.getDaoAssetPool(daoId), 100 ether);
        vm.prank(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 10);
        for (uint256 i = 0; i < 10; i++) {
            vm.roll(6 + i);
            super._mintNft(
                daoId,
                param.canvasId,
                string.concat("test token uri", vm.toString(6 + i + 2)),
                0.01 ether,
                canvasCreator.key,
                nftMinter.addr
            );
        }
        vm.roll(16);
        assertEq(
            protocol.getDaoRemainingRound(daoId),
            0,
            "test_daoResurrection_multiRounds_noJack dead one remaing round end"
        );

        vm.roll(106);
        (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(
            erc20Reward,
            100 * 0.08 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead 1 nftMinter reward end")
        );
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(
            erc20Reward,
            100 * 0.2 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead 1 canvasCreator reward end")
        );
        (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
        assertEq(
            erc20Reward,
            100 * 0.7 ether,
            string.concat("test_daoResurrection_multiRounds_noJack dead 1 daoCreator reward end")
        );

        //dead two
        assertEq(
            protocol.getDaoRemainingRound(daoId),
            0,
            "test_daoResurrection_multiRounds_noJack dead two remaing round start"
        );
        vm.prank(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 5);
        deal(token, protocol.getDaoAssetPool(daoId), 50 ether);
        super._mintNft(daoId, param.canvasId, "test token uri 106", 0.01 ether, canvasCreator.key, nftMinter.addr);

        for (uint256 i = 1; i < 5; i++) {
            vm.roll(106 + i);
            (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
            assertEq(
                erc20Reward,
                10 * 0.08 ether,
                string.concat(
                    "test_daoResurrection_multiRounds_noJack dead 2 nftMinter reward _ ", vm.toString(106 + i)
                )
            );
            (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
            assertEq(
                erc20Reward,
                10 * 0.2 ether,
                string.concat(
                    "test_daoResurrection_multiRounds_noJack dead 2 canvasCreator reward _ ", vm.toString(106 + i)
                )
            );
            (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
            assertEq(
                erc20Reward,
                10 * 0.7 ether,
                string.concat(
                    "test_daoResurrection_multiRounds_noJack dead 2 daoCreator reward _ ", vm.toString(106 + i)
                )
            );

            super._mintNft(
                daoId,
                param.canvasId,
                string.concat("test token uri", vm.toString(106 + i + 2)),
                0.01 ether,
                canvasCreator.key,
                nftMinter.addr
            );
        }
        vm.roll(112);
        assertEq(
            protocol.getDaoRemainingRound(daoId),
            0,
            "test_daoResurrection_multiRounds_noJack dead two remaing round end"
        );

        (erc20Reward,) = protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(erc20Reward, 10 * 0.08 ether, "test_daoResurrection_multiRounds_noJack dead 2 nftMinter reward _ 112");
        (erc20Reward,) = protocol.claimCanvasReward(param.canvasId);
        assertEq(erc20Reward, 10 * 0.2 ether, "test_daoResurrection_multiRounds_noJack dead 2 nftMinter reward _ 112");
        (erc20Reward,) = protocol.claimDaoCreatorReward(daoId);
        assertEq(erc20Reward, 10 * 0.7 ether, "test_daoResurrection_multiRounds_noJack dead 2 nftMinter reward _ 112");
        assertEq(IERC20(token).balanceOf(nftMinter.addr), (50_000_000 + 100 + 50) * 0.08 ether);
        assertEq(IERC20(token).balanceOf(daoCreator.addr), (50_000_000 + 100 + 50) * 0.9 ether);
    }

    function test_daoResurrection_claim_2times_Jackpot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 5;
        param.noPermission = true;
        param.selfRewardRatioERC20 = 10_000;
        param.isProgressiveJackpot = true;

        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = param.canvasId;

        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        //erc20 = 50000000 ether
        for (uint256 i = 0; i < 5; i++) {
            hoax(nftMinter.addr);
            mintNftTransferParam.tokenUri = string.concat("nft", vm.toString(i));
            protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
            assertEq(
                IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)),
                50_000_000 ether - (i + 1) * 10_000_000 ether,
                string.concat("test_daoResurrection_claim_2times_noJack Item balance check_", vm.toString(i))
            );
            vm.roll(i + 2);
        }
        vm.roll(8);
        assertEq(protocol.getDaoRemainingRound(daoId), 0);

        vm.prank(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 10);

        deal(token, protocol.getDaoAssetPool(daoId), 100 ether);

        super._mintNft(
            daoId, param.canvasId, string.concat("test token 8"), 0.01 ether, canvasCreator.key, nftMinter.addr
        );

        vm.roll(9);
        super._mintNft(
            daoId, param.canvasId, string.concat("test token 9"), 0.01 ether, canvasCreator.key, nftMinter.addr
        );

        vm.roll(10);
        super._mintNft(
            daoId, param.canvasId, string.concat("test token 10"), 0.01 ether, canvasCreator.key, nftMinter.addr
        );

        // round 1-5: 50000000 * 0.08
        // round 8-9: 10 * 0.08 * 2
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(
            IERC20(token).balanceOf(nftMinter.addr),
            4_000_000 ether + 1.6 ether,
            "test_daoResurrection_claim_2times_noJack nft minter reward check"
        );
        protocol.claimDaoCreatorReward(daoId);
        // 50000000 * 0.7 + 10 * 0.7 *2
        assertEq(
            IERC20(token).balanceOf(daoCreator.addr),
            35_000_000 ether + 14 ether,
            "test_daoResurrection_claim_2times_noJack dao creator reward check"
        );
        protocol.claimCanvasReward(param.canvasId);
        // 50000000 * 0.2 + 10 * 0.2 * 2
        assertEq(
            IERC20(token).balanceOf(daoCreator.addr),
            35_000_000 ether + 14 ether + 10_000_000 ether + 4 ether,
            "test_daoResurrection_claim_2times_noJack dao creator reward check"
        );
    }

    receive() external payable { }
}
