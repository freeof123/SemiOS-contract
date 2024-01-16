// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import "forge-std/Test.sol";
import "contracts/interface/D4AStructs.sol";
import { console2 } from "forge-std/console2.sol";
import "contracts/interface/D4AErrors.sol";
import { IPDLock } from "contracts/interface/IPDLock.sol";

contract PDTopUpNFTStake is DeployHelper {
    event TopUpNftLock(bytes32 daoId, NftIdentifier nft, uint256 lockStartBlock, uint256 duration);

    function setUp() public {
        setUpEnv();
    }

    function test_TouUpNFTStake_basicStakeAndUnstake() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.topUpMode = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);

        vm.expectRevert(NotNftOwner.selector);
        protocol.lockTopUpNFT(daoId, nft1, 1 days);

        vm.prank(nftMinter.addr);
        protocol.lockTopUpNFT(daoId, nft1, 10);

        vm.roll(8);
        assertEq(protocol.checkTopUpNftLockedStatus(daoId, nft1), true, "Check A");

        vm.roll(12);
        assertEq(protocol.checkTopUpNftLockedStatus(daoId, nft1), false, "Check A");
    }

    function test_TouUpNFTStake_TopUpBalanceCheck() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.topUpMode = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.selfRewardRatioETH = 8000;
        param.selfRewardRatioERC20 = 8000;
        param.noPermission = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.uniPriceModeOff = true;
        param.daoUri = "continuous dao uri";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);
        vm.prank(nftMinter.addr);
        protocol.lockTopUpNFT(daoId, nft1, 10);

        vm.roll(2);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60), "Check A");
        assertEq(topUpETH, 0.01 ether, "Check B");

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60), "Check D");
        assertEq(topUpETH, 0.01 ether, "Check C");

        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        vm.roll(3);

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60) * 2, "Check E");
        assertEq(topUpETH, 0.02 ether, "Check F");

        // vm.warp(block.timestamp + 1 days + 1 seconds);
        // vm.prank(nftMinter.addr);
        // protocol.unstakeTopUpNFT(daoId, nft1);
        vm.roll(4);
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60) * 2, "Check G");
        assertEq(topUpETH, 0.02 ether, "Check H");

        vm.roll(16);
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(2)), ".json"
        );
        super._mintNftWithParam(nftParam, nftMinter.addr);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60), "Check H");
        assertEq(topUpETH, 0.01 ether, "Check H");
    }

    function test_TouUpNFTStake_eventEmit() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.topUpMode = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);
        vm.expectEmit(true, true, true, true, address(protocol));
        emit TopUpNftLock(daoId, nft1, block.number, 10);

        vm.prank(nftMinter.addr);
        protocol.lockTopUpNFT(daoId, nft1, 10);

        vm.roll(8);
        assertEq(protocol.checkTopUpNftLockedStatus(daoId, nft1), true, "Check A");

        vm.roll(12);
        assertEq(protocol.checkTopUpNftLockedStatus(daoId, nft1), false, "Check A");
    }
}
