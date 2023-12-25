// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam, SetChildrenParam } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoIntergrate14 is DeployHelper {
    error TransferFromFailed();

    function setUp() public {
        super.setUpEnv();
    }

    // testcase 1.4-34
    function test_PDCreateFunding_4_34() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.topUpMode = true;
        param.noPermission = true;
        param.mintableRound = 50;
        param.daoUri = "topup dao uri";

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

        //------------------
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = false;
        param.erc20PaymentMode = true;
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.daoUri = "normal dao uri";
        param.uniPriceModeOff = true;
        bytes32 canvasId2 = param.canvasId;
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        vm.roll(3);
        address token = protocol.getDaoToken(daoId2);
        deal(token, nftMinter.addr, 100_000_000 ether);
        {
            (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId2, nftMinter.addr);
            assertEq(topUpERC20, 1_000_000 ether);
            assertEq(topUpETH, 0.01 ether);
        }

        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId2, "a1234", 2_000_000 ether);
        bytes memory sig;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator2.key, digest);
            sig = abi.encodePacked(r, s, v);
        }

        vm.expectRevert(TransferFromFailed.selector);
        vm.prank(nftMinter.addr);
        uint256 tokenId = protocol.mintNFT(daoId2, canvasId2, "a1234", new bytes32[](0), 2_000_000 ether, sig);
        vm.startPrank(nftMinter.addr);

        IERC20(token).approve(address(protocol), 1_000_000 ether);
        tokenId = protocol.mintNFT(daoId2, canvasId2, "a1234", new bytes32[](0), 2_000_000 ether, sig);

        {
            (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId2, nftMinter.addr);
            assertEq(topUpERC20, 0);
            assertEq(topUpETH, 0);
        }
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 100_000_000 ether - 1_000_000 ether);
    }

    function test_PDCreateFunding_4_20() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.daoUri = "infiniteAndProgressive dao uri";
        param.isProgressiveJackpot = true;
        param.infiniteMode = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);
        assertGe(protocol.getDaoAssetPool(daoId).balance, 0);
        assertGe(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)) , 0);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp + 1));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.daoUri = "sub dao uri";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        SetChildrenParam memory vars;
        vars.childrenDaoId = new bytes32[](1);
        vars.childrenDaoId[0] = daoId2;
        vars.erc20Ratios = new uint256[](1);
        vars.erc20Ratios[0] = 3000;
        vars.ethRatios = new uint256[](1);
        vars.ethRatios[0] = 3000;
        vars.selfRewardRatioERC20 = 5000;
        vars.selfRewardRatioETH = 5000;
        vars.redeemPoolRatioETH = 1000;

        vm.prank(daoCreator.addr);
        protocol.setChildren(daoId, vars);

        deal(protocol.getDaoAssetPool(daoId), 10 ether);



        vm.roll(3);
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

        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId2)), 50_000_000 ether * 0.3);
        assertEq(protocol.getDaoAssetPool(daoId2).balance, 3 ether);

        assertEq(protocol.getRoundERC20Reward(daoId, 3), 5_000_000 ether * 5);
        assertEq(protocol.getRoundETHReward(daoId, 3), 5 ether);
        assertEq(protocol.getDaoFeePool(daoId).balance, 1 ether + 0.006 ether);
        assertEq(protocol.getDaoAssetPool(daoId).balance, 1 ether + 0.0035 ether);
        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)), 5_000_000 ether * 2);


        vm.roll(6);
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
        assertEq(
            IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId2)),
            50_000_000 ether * 0.3 + 5_000_000 ether * 2 * 0.3
        );
        assertEq(protocol.getDaoAssetPool(daoId2).balance, 3 ether + (1 ether + 0.0035 ether) * 0.3);
        assertEq(protocol.getRoundERC20Reward(daoId, 6), 5_000_000 ether * 2 * 0.5);
        assertEq(protocol.getRoundETHReward(daoId, 6), (1 ether + 0.0035 ether) * 0.5);
        assertEq(
            protocol.getDaoFeePool(daoId).balance,
            (1 ether + 0.006 ether) + ((1 ether + 0.0035 ether) * 0.1 + 0.01 ether * 0.6)
        );
        assertEq(protocol.getDaoAssetPool(daoId).balance, (1 ether + 0.0035 ether) * 0.1 + 0.01 ether * 0.35);
        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)), 5_000_000 ether * 2 * 0.2);
    }

    function test_PDCreateFunding_4_21() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.daoUri = "infiniteAndNotProgressive dao uri";
        param.isProgressiveJackpot = false;
        param.infiniteMode = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);
        assertGe(protocol.getDaoAssetPool(daoId).balance, 0);
        assertGe(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId)) , 0); 

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp + 1));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.daoUri = "sub dao uri";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        uint256 subDaoERC20Balance = IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId2));
        uint256 subDaoETHBalance = protocol.getDaoAssetPool(daoId2).balance;

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

        assertEq(IERC20(token).balanceOf(protocol.getDaoAssetPool(daoId2)), subDaoERC20Balance);
        assertEq(protocol.getDaoAssetPool(daoId2).balance, subDaoETHBalance);


    }
}
