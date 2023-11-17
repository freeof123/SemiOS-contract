// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoTopUpTest is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    // testcase 1.3-15
    function test_PDCreateFunding_1_3_55() public {
        // dao: daoCreator
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
        address token = protocol.getDaoToken(daoId);
        //step 2
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
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, nftMinter.addr);
        assertEq(topUpERC20, 0);
        assertEq(topUpETH, 0);
        drb.changeRound(2);
        //step 4
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nftMinter.addr);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60));
        assertEq(topUpETH, 0.01 ether);

        deal(nftMinter.addr, 1 ether);
        uint256 balBefore = nftMinter.addr.balance;
        //step 6
        super._mintNftChangeBal(
            daoId2,
            canvasId2,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.005 ether,
            daoCreator2.key,
            nftMinter.addr
        );
        assertEq(nftMinter.addr.balance, balBefore);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nftMinter.addr);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60) - 50_000_000 ether / uint256(60) / 2);
        assertEq(topUpETH, 0.005 ether);

        //step 11
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        //step 12
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter2.addr
        );
        drb.changeRound(3);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nftMinter.addr);
        uint256 a = (50_000_000 ether - 50_000_000 ether / uint256(60)) / 59;
        assertEq(topUpERC20, 50_000_000 ether / uint256(60) - 50_000_000 ether / uint256(60) / 2 + a * 2 / 3);
        assertEq(topUpETH, 0.005 ether + 0.02 ether);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nftMinter2.addr);
        assertEq(topUpERC20, a / 3);
        assertEq(topUpETH, 0.01 ether);
    }

    function test_PDCreateFunding_1_3_62() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.topUpMode = true;
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.selfRewardRatioETH = 0;
        param.selfRewardRatioERC20 = 0;
        param.noPermission = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.uniPriceModeOff = true;
        param.daoUri = "continuous dao uri";

        param.childrenDaoId = new bytes32[](1);
        param.childrenDaoId[0] = daoId;
        // erc20 ratio
        param.childrenDaoRatiosERC20 = new uint256[](1);
        param.childrenDaoRatiosERC20[0] = 7000;
        // eth ratio
        param.childrenDaoRatiosETH = new uint256[](1);
        param.childrenDaoRatiosETH[0] = 7000;

        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        vm.prank(daoCreator.addr);
        protocol.setInitialTokenSupplyForSubDao(daoId2, 10_000_000 ether);
        vm.prank(daoCreator.addr);
        protocol.setDaoUnifiedPrice(daoId, 0.1 ether);

        address token = protocol.getDaoToken(daoId);
        address pool1 = protocol.getDaoAssetPool(daoId);
        //step 2
        super._mintNft(
            daoId2,
            canvasId2,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator2.key,
            nftMinter.addr
        );
        assertEq(IERC20(token).balanceOf(pool1), 50_000_000 ether + 700_000 ether);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.1 ether,
            daoCreator.key,
            nftMinter.addr
        );
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.1 ether,
            daoCreator.key,
            nftMinter2.addr
        );
        drb.changeRound(2);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, nftMinter.addr);
        assertEq(topUpERC20, (50_000_000 ether + 700_000 ether) / 10 / 2);
        assertEq(topUpETH, 0.1 ether);

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nftMinter2.addr);
        assertEq(topUpERC20, (50_000_000 ether + 700_000 ether) / 10 / 2);
        assertEq(topUpETH, 0.1 ether);
    }
}

/*
vars.allRatioForFundingParam = AllRatioForFundingParam({
            // l.protocolMintFeeRatioInBps = 250
            // sum = 9750
            // !!! enable when param.uniPriceModeOff = true
            canvasCreatorMintFeeRatio: 750,
            assetPoolMintFeeRatio: 2000,
            redeemPoolMintFeeRatio: 7000,


            // * 1.3 add
            // l.protocolMintFeeRatioInBps = 250
            // sum = 9750
            // !!! enable when param.uniPriceModeOff = false, default is false
            canvasCreatorMintFeeRatioFiatPrice: 250,
            assetPoolMintFeeRatioFiatPrice: 3500,
            redeemPoolMintFeeRatioFiatPrice: 6000,


            // l.protocolERC20RatioInBps = 200
            // sum = 9800
            // !!! ratio for param.selfRewardRatioERC20
            minterERC20RewardRatio: 800,
            canvasCreatorERC20RewardRatio: 2000,
            daoCreatorERC20RewardRatio: 7000,


            // sum = 9800
            // !!! ratio for param.selfRewardRatioETH
            minterETHRewardRatio: 800,
            canvasCreatorETHRewardRatio: 2000,
            daoCreatorETHRewardRatio: 7000
        });
*/
