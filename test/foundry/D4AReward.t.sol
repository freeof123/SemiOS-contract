// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { ID4ASettingsReadable, DeployHelper } from "./utils/DeployHelper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MintNftSigUtils } from "./utils/MintNftSigUtils.sol";

contract D4ARewardTest is DeployHelper {
    bytes32 daoId;
    bytes32 canvasId1;
    bytes32 canvasId2;
    IERC20 token;
    address daoFeePool;

    uint256 startDrb = 5;
    uint256 mintableRound = 50;
    uint256 rewardPerRound = 1e9 * 1e18 / mintableRound;
    uint256 protocolRewardPerRound = rewardPerRound * 2 / 100;
    uint256 daoRewardPerRound = rewardPerRound * 3 / 100;
    uint256 canvasRewardPerRound = rewardPerRound * 95 / 100;
    uint256 protocolTotalReward;
    uint256 daoTotalReward;
    uint256 canvasTotalReward1;
    uint256 canvasTotalReward2;

    MintNftSigUtils sigUtils;

    function setUp() public {
        setUpEnv();

        hoax(daoCreator.addr);
        daoId = _createTrivialDao(startDrb, mintableRound, 0, 0, 750, "test project uri");
        assertEq(daoCreator.addr, naiveOwner.ownerOf(daoId));

        drb.changeRound(startDrb);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0));
        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0));

        (address temp,) = protocol.getProjectTokens(daoId);
        token = IERC20(temp);
        (,,, daoFeePool,,,,) = protocol.getProjectInfo(daoId);
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_case_00_NoMintAndTryClaimReward() public {
        drb.changeRound(10);
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.balanceOf(protocolFeePool.addr), 0);
        assertEq(token.balanceOf(daoCreator.addr), 0);
        protocol.claimCanvasReward(canvasId1);
        assertEq(token.balanceOf(canvasCreator.addr), 0);
    }

    function test_case_01_OneMintAndClaimRewardInTheSameDrbShouldGetNothing() public {
        test_case_00_NoMintAndTryClaimReward();

        drb.changeRound(11);

        string memory tokenUri = "token uri 1";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        protocol.mintNFT{ value: 0.05 ether }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.balanceOf(protocolFeePool.addr), 0);
        assertEq(token.balanceOf(daoCreator.addr), 0);
        protocol.claimCanvasReward(canvasId1);
        assertEq(token.balanceOf(canvasCreator.addr), 0);
    }

    function test_case_02_ClaimInNextDrbShouldGetSomething() public {
        test_case_01_OneMintAndClaimRewardInTheSameDrbShouldGetNothing();

        drb.changeRound(12);

        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        assertEq(token.balanceOf(protocolFeePool.addr), protocolRewardPerRound);
        assertEq(token.balanceOf(daoCreator.addr), daoRewardPerRound);
        assertEq(token.balanceOf(canvasCreator.addr), canvasRewardPerRound);

        // tally rewards
        protocolTotalReward += protocolRewardPerRound;
        daoTotalReward += daoRewardPerRound;
        canvasTotalReward1 += canvasRewardPerRound;
    }

    function test_case_03_TwoMintsInTwoCanvases_RewardShoulSplit() public {
        test_case_02_ClaimInNextDrbShouldGetSomething();

        string memory tokenUri = "token uri 2";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        uint256 price1 = protocol.getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price1 }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        tokenUri = "token uri 3";
        digest = sigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator2.key, digest);

        hoax(nftMinter.addr);
        uint256 price2 = protocol.getCanvasNextPrice(canvasId2);
        protocol.mintNFT{ value: price2 }(
            daoId, canvasId2, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(13);
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        assertEq(
            token.balanceOf(protocolFeePool.addr), protocolTotalReward + protocolRewardPerRound, "protocol fee pool"
        );
        assertEq(token.balanceOf(daoCreator.addr), daoTotalReward + daoRewardPerRound, "dao creator");
        assertEq(
            token.balanceOf(canvasCreator.addr),
            canvasTotalReward1 + canvasRewardPerRound * price1 / (price1 + price2),
            "canvas creator 1"
        );
        assertEq(
            token.balanceOf(canvasCreator2.addr),
            canvasTotalReward2 + canvasRewardPerRound * price2 / (price1 + price2),
            "canvas creator 2"
        );

        // tally rewards
        protocolTotalReward += protocolRewardPerRound;
        daoTotalReward += daoRewardPerRound;
        canvasTotalReward1 += canvasRewardPerRound * price1 / (price1 + price2);
        canvasTotalReward2 += canvasRewardPerRound * price2 / (price1 + price2);
    }

    function test_case_10_MintAfterLongGap() public {
        // clean up rewards
        protocolTotalReward = 0;
        daoTotalReward = 0;
        canvasTotalReward1 = 0;
        canvasTotalReward2 = 0;

        drb.changeRound(1000);

        string memory tokenUri = "token uri 4";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        uint256 price = protocol.getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1001);

        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        assertEq(
            token.balanceOf(protocolFeePool.addr), protocolTotalReward + protocolRewardPerRound, "protocol fee pool"
        );
        assertEq(token.balanceOf(daoCreator.addr), daoTotalReward + daoRewardPerRound, "dao creator");
        assertEq(token.balanceOf(canvasCreator.addr), canvasTotalReward1 + canvasRewardPerRound, "canvas creator 1");

        // tally rewards
        protocolTotalReward += protocolRewardPerRound;
        daoTotalReward += daoRewardPerRound;
        canvasTotalReward1 += canvasRewardPerRound;
    }

    function test_case_11_MintAfterSuperLongGap() public {
        test_case_10_MintAfterLongGap();

        drb.changeRound(10_000);

        string memory tokenUri = "token uri 5";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        uint256 price = protocol.getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(10_001);

        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        assertEq(
            token.balanceOf(protocolFeePool.addr), protocolTotalReward + protocolRewardPerRound, "protocol fee pool"
        );
        assertEq(token.balanceOf(daoCreator.addr), daoTotalReward + daoRewardPerRound, "dao creator");
        assertEq(token.balanceOf(canvasCreator.addr), canvasTotalReward1 + canvasRewardPerRound, "canvas creator 1");
    }

    function test_case_20_MintAfterSuperLongGap() public {
        hoax(daoCreator.addr);
        daoId = _createTrivialDao(startDrb, 3, 0, 0, 750, "test project uri 1");
        assertEq(daoCreator.addr, naiveOwner.ownerOf(daoId));

        drb.changeRound(startDrb);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0));
        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 4", new bytes32[](0));

        (address temp,) = protocol.getProjectTokens(daoId);
        token = IERC20(temp);
        (,,, daoFeePool,,,,) = protocol.getProjectInfo(daoId);
        sigUtils = new MintNftSigUtils(address(protocol));

        // clean up rewards
        protocolTotalReward = 0;
        daoTotalReward = 0;
        canvasTotalReward1 = 0;
        canvasTotalReward2 = 0;

        drb.changeRound(1000);

        string memory tokenUri = "token uri 6";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        uint256 price = protocol.getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1001);

        tokenUri = "token uri 7";
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        price = protocol.getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1002);

        tokenUri = "token uri 8";
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        price = protocol.getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1003);

        tokenUri = "token uri 9";
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        startHoax(nftMinter.addr);
        price = protocol.getCanvasNextPrice(canvasId1);
        vm.expectRevert("rounds end, cannot mint");
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
        vm.stopPrank();

        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        assertEq(token.balanceOf(protocolFeePool.addr), protocolTotalReward + 1e9 * 1e18 * 2 / 100, "protocol fee pool");
        assertEq(token.balanceOf(daoCreator.addr), daoTotalReward + 1e9 * 1e18 * 3 / 100, "dao creator");
        assertApproxEqAbs(
            token.balanceOf(canvasCreator.addr), canvasTotalReward1 + 1e9 * 1e18 * 95 / 100, 100, "canvas creator 1"
        );
        assertApproxEqAbs(token.balanceOf(address(protocol)), 0, 100, "protocol");
        assertEq(token.totalSupply(), 1e9 * 1e18, "total supply");
    }
}
