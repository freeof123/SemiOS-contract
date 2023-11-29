// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ID4ASettingsReadable, DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AConstants.sol";
import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";

contract D4ARewardTest is DeployHelper {
    bytes32 daoId;
    bytes32 canvasId1;
    bytes32 canvasId2;
    IERC20 token;
    address daoFeePool;

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

        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = mintableRound;
        daoId = _createDao(createDaoParam);
        assertEq(daoCreator.addr, naiveOwner.ownerOf(daoId));

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0), 0);
        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId);
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_case_00_NoMintAndTryClaimReward() public {
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.balanceOf(protocolFeePool.addr), 0);
        assertEq(token.balanceOf(daoCreator.addr), 0);
        protocol.claimCanvasReward(canvasId1);
        assertEq(token.balanceOf(canvasCreator.addr), 0);
    }

    function test_case_01_OneMintAndClaimRewardInTheSameDrbShouldGetNothing() public {
        test_case_00_NoMintAndTryClaimReward();

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
        vm.skip(true);
        test_case_01_OneMintAndClaimRewardInTheSameDrbShouldGetNothing();

        drb.changeRound(2);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);

        assertEq(token.balanceOf(protocolFeePool.addr), protocolRewardPerRound, "protocol fee pool");
        assertEq(token.balanceOf(daoCreator.addr), daoRewardPerRound, "dao creator");
        assertEq(token.balanceOf(canvasCreator.addr), canvasRewardPerRound, "canvas creator");

        // tally rewards
        protocolTotalReward += protocolRewardPerRound;
        daoTotalReward += daoRewardPerRound;
        canvasTotalReward1 += canvasRewardPerRound;
    }

    function test_case_03_TwoMintsInTwoCanvases_RewardShoulSplit() public {
        vm.skip(true);
        test_case_02_ClaimInNextDrbShouldGetSomething();

        string memory tokenUri = "token uri 2";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        uint256 price1 = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price1 }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        tokenUri = "token uri 3";
        digest = sigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator2.key, digest);

        hoax(nftMinter.addr);
        uint256 price2 = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2);
        protocol.mintNFT{ value: price2 }(
            daoId, canvasId2, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(3);
        // claim问题
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
        vm.skip(true);
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
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1001);

        // claim问题
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
        vm.skip(true);
        test_case_10_MintAfterLongGap();

        drb.changeRound(10_000);

        string memory tokenUri = "token uri 5";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(10_001);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        assertEq(
            token.balanceOf(protocolFeePool.addr), protocolTotalReward + protocolRewardPerRound, "protocol fee pool"
        );
        assertEq(token.balanceOf(daoCreator.addr), daoTotalReward + daoRewardPerRound, "dao creator");
        assertEq(token.balanceOf(canvasCreator.addr), canvasTotalReward1 + canvasRewardPerRound, "canvas creator 1");
    }

    function test_case_20_MintAfterSuperLongGap() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 3;
        createDaoParam.daoUri = "test dao uri 1";
        daoId = _createDao(createDaoParam);
        assertEq(daoCreator.addr, naiveOwner.ownerOf(daoId));

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 0);
        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 4", new bytes32[](0), 0);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId);
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
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1001);

        tokenUri = "token uri 7";
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1002);

        tokenUri = "token uri 8";
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1003);

        tokenUri = "token uri 9";
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        startHoax(nftMinter.addr);
        price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
        vm.expectRevert(ExceedMaxMintableRound.selector);
        protocol.mintNFT{ value: price }(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
        vm.stopPrank();

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);

        assertApproxEqAbs(
            token.balanceOf(protocolFeePool.addr), protocolTotalReward + 1e9 * 1e18 * 2 / 100, 10, "protocol fee pool"
        );
        assertApproxEqAbs(token.balanceOf(daoCreator.addr), daoTotalReward + 1e9 * 1e18 * 3 / 100, 10, "dao creator");
        assertApproxEqAbs(
            token.balanceOf(canvasCreator.addr), canvasTotalReward1 + 1e9 * 1e18 * 95 / 100, 10, "canvas creator 1"
        );
        assertApproxEqAbs(token.balanceOf(address(protocol)), 0, 10, "protocol");
        assertApproxEqAbs(token.totalSupply(), 1e9 * 1e18, 10, "total supply");
    }

    function test_Reward_amount() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.daoUri = "test dao uri 1";
        createDaoParam.daoCreatorERC20RatioInBps = 1900;
        createDaoParam.canvasCreatorERC20RatioInBps = 4000;
        createDaoParam.nftMinterERC20RatioInBps = 3900;
        createDaoParam.actionType = 16;
        daoId = _createDao(createDaoParam);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 1000);

        {
            drb.changeRound(2);
            string memory tokenUri = "test token uri 1";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1) }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();
        }

        {
            drb.changeRound(23);
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1) }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();
        }

        drb.changeRound(24);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);

        uint256 totalReward = ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 23);
        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        assertApproxEqAbs(
            token.balanceOf(protocolFeePool.addr), totalReward * 200 / BASIS_POINT, 1, "protocol fee pool"
        );
        assertEq(token.balanceOf(daoCreator.addr), totalReward * 1900 / BASIS_POINT, "dao creator");
        assertApproxEqAbs(token.balanceOf(canvasCreator.addr), totalReward * 4390 / BASIS_POINT, 1, "canvas creator");
        assertApproxEqAbs(token.balanceOf(nftMinter.addr), totalReward * 3510 / BASIS_POINT, 1, "nft minter");
    }

    function test_claim_partial_reward_when_current_round_have_mint() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.daoUri = "test dao uri 1";
        createDaoParam.daoCreatorERC20RatioInBps = 1900;
        createDaoParam.canvasCreatorERC20RatioInBps = 4000;
        createDaoParam.nftMinterERC20RatioInBps = 3900;
        createDaoParam.daoFeePoolETHRatioInBps = 3000;
        createDaoParam.daoFeePoolETHRatioInBpsFlatPrice = 3500;
        createDaoParam.actionType = 16;
        daoId = _createDao(createDaoParam);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 1000);

        {
            drb.changeRound(2);
            string memory tokenUri = "test token uri 1";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1) }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();
        }

        {
            drb.changeRound(23);
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1) }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();
        }

        // drb.changeRound(24);
        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        uint256 totalReward = ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 2);
        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        assertEq(token.balanceOf(protocolFeePool.addr), totalReward * 200 / BASIS_POINT, "protocol fee pool");
        assertEq(token.balanceOf(daoCreator.addr), totalReward * 1900 / BASIS_POINT, "dao creator");
        assertEq(token.balanceOf(canvasCreator.addr), totalReward * 4390 / BASIS_POINT, "canvas creator");
        assertEq(token.balanceOf(nftMinter.addr), totalReward * 3510 / BASIS_POINT, "nft minter");
    }

    function test_claimRewardWhenDaoFloorPriceIsZeroAndUseBatchMint() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.daoUri = "test dao uri 1";
        createDaoParam.floorPriceRank = 9999;
        createDaoParam.daoCreatorERC20RatioInBps = 300;
        createDaoParam.canvasCreatorERC20RatioInBps = 5000;
        createDaoParam.nftMinterERC20RatioInBps = 4500;
        createDaoParam.actionType = 16;
        daoId = _createDao(createDaoParam);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 0);

        string[] memory tokenUris = new string[](3);
        tokenUris[0] = "test token uri 1";
        tokenUris[1] = "test token uri 2";
        tokenUris[2] = "test token uri 3";
        uint256[] memory flatPrices = new uint256[](3);
        // batchMint问题
        _batchMint(daoId, canvasId1, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);

        tokenUris = new string[](2);
        tokenUris[0] = "test token uri 4";
        tokenUris[1] = "test token uri 5";
        flatPrices = new uint256[](2);
        // batchMint问题
        _batchMint(daoId, canvasId1, tokenUris, flatPrices, canvasCreator.key, nftMinter2.addr);

        drb.changeRound(2);
        // claim问题
        assertEq(protocol.claimProjectERC20Reward(daoId), 999_999_999_999_999_999_999_999);
        assertEq(protocol.claimCanvasReward(canvasId1), 16_666_666_666_666_666_666_666_666);
        assertEq(protocol.claimNftMinterReward(daoId, nftMinter.addr), 8_999_999_999_999_999_999_999_999);
        assertEq(protocol.claimNftMinterReward(daoId, nftMinter2.addr), 5_999_999_999_999_999_999_999_999);
    }

    function test_LinearRewardIssuacneAndProgressiveJackpot() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory param;
        param.daoUri = "test dao uri 1";
        param.startDrb = 2;
        param.mintableRound = 90;
        param.daoCreatorERC20RatioInBps = 800;
        param.canvasCreatorERC20RatioInBps = 8000;
        param.nftMinterERC20RatioInBps = 1000;
        param.daoFeePoolETHRatioInBps = 250;
        param.daoFeePoolETHRatioInBpsFlatPrice = 750;
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 10 ether;
        param.isProgressiveJackpot = true;
        param.actionType = 16;
        daoId = _createDao(param);

        drb.changeRound(2);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 0);

        _mintNft(daoId, canvasId1, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 10.01 ether);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 120);

        drb.changeRound(3);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(token.totalSupply(), 11_111_111_111_111_111_111_111_111);
        assertEq(token.balanceOf(daoCreator.addr), 888_888_888_888_888_888_888_888);
        assertEq(token.balanceOf(canvasCreator.addr), 8_888_888_888_888_888_888_888_888);
        assertEq(token.balanceOf(nftMinter.addr), 1_111_111_111_111_111_111_111_111);

        hoax(canvasCreator.addr);
        protocol.setCanvasRebateRatioInBps(canvasId1, 2000);

        _mintNft(daoId, canvasId1, "test token uri 2", 0.0109 ether, canvasCreator.key, nftMinter.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 180);

        drb.changeRound(4);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(token.totalSupply(), 19_421_101_774_042_950_513_538_748);
        assertEq(token.balanceOf(daoCreator.addr), 1_553_688_141_923_436_041_083_098);
        assertEq(token.balanceOf(canvasCreator.addr), 15_703_081_232_492_997_198_879_550);
        assertEq(token.balanceOf(nftMinter.addr), 1_775_910_364_145_658_263_305_321);

        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 4", new bytes32[](0), 10_000);

        _mintNft(daoId, canvasId1, "test token uri 3", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 4", 0.0123 ether, canvasCreator2.key, nftMinter2.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);

        drb.changeRound(5);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 24_929_971_988_795_518_207_282_912);
        assertEq(token.balanceOf(daoCreator.addr), 1_994_397_759_103_641_456_582_631);
        assertEq(token.balanceOf(canvasCreator.addr), 16_242_135_358_518_904_777_503_680);
        assertEq(token.balanceOf(canvasCreator2.addr), 4_366_338_420_809_851_386_855_457);
        assertEq(token.balanceOf(nftMinter.addr), 1_828_501_010_587_210_222_195_480);
        assertEq(token.balanceOf(nftMinter2.addr), 0);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);

        drb.changeRound(6);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.totalSupply(), 24_929_971_988_795_518_207_282_912);

        hoax(canvasCreator2.addr);
        protocol.setCanvasRebateRatioInBps(canvasId2, 4070);

        _mintNft(daoId, canvasId2, "test token uri 5", 0, canvasCreator2.key, nftMinter2.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);

        drb.changeRound(7);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 35_947_712_418_300_653_594_771_240);
        assertEq(token.balanceOf(daoCreator.addr), 2_875_816_993_464_052_287_581_697);
        assertEq(token.balanceOf(canvasCreator.addr), 16_242_135_358_518_904_777_503_680);
        assertEq(token.balanceOf(canvasCreator2.addr), 13_628_952_799_894_818_707_116_894);
        assertEq(token.balanceOf(nftMinter.addr), 1_828_501_010_587_210_222_195_480);
        assertEq(token.balanceOf(nftMinter2.addr), 653_352_007_469_654_528_478_057);

        drb.changeRound(181);

        _mintNft(daoId, canvasId1, "test token uri 6", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(182);

        {
            string memory tokenUri = "test token uri 7";
            uint256 flatPrice = 0;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            vm.expectRevert(ExceedMaxMintableRound.selector);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        //   claim问题
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.totalSupply(), 999_999_999_999_999_999_999_999_998);
    }

    function test_LinearRewardIssuacneAndNotProgressiveJackpot() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory param;
        param.daoUri = "test dao uri 1";
        param.startDrb = 2;
        param.mintableRound = 90;
        param.daoCreatorERC20RatioInBps = 800;
        param.canvasCreatorERC20RatioInBps = 8000;
        param.nftMinterERC20RatioInBps = 1000;
        param.daoFeePoolETHRatioInBps = 250;
        param.daoFeePoolETHRatioInBpsFlatPrice = 750;
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 10 ether;
        param.actionType = 16;
        daoId = _createDao(param);

        drb.changeRound(2);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 0);

        _mintNft(daoId, canvasId1, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 10.01 ether);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 120);

        drb.changeRound(3);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(token.totalSupply(), 11_111_111_111_111_111_111_111_111);
        assertEq(token.balanceOf(daoCreator.addr), 888_888_888_888_888_888_888_888);
        assertEq(token.balanceOf(canvasCreator.addr), 8_888_888_888_888_888_888_888_888);
        assertEq(token.balanceOf(nftMinter.addr), 1_111_111_111_111_111_111_111_111);

        hoax(canvasCreator.addr);
        protocol.setCanvasRebateRatioInBps(canvasId1, 2000);

        _mintNft(daoId, canvasId1, "test token uri 2", 0.0109 ether, canvasCreator.key, nftMinter.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 180);

        drb.changeRound(4);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        assertEq(token.totalSupply(), 19_421_101_774_042_950_513_538_748);
        assertEq(token.balanceOf(daoCreator.addr), 1_553_688_141_923_436_041_083_098);
        assertEq(token.balanceOf(canvasCreator.addr), 15_703_081_232_492_997_198_879_550);
        assertEq(token.balanceOf(nftMinter.addr), 1_775_910_364_145_658_263_305_321);

        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 4", new bytes32[](0), 10_000);

        _mintNft(daoId, canvasId1, "test token uri 3", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 4", 0.0123 ether, canvasCreator2.key, nftMinter2.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);

        drb.changeRound(5);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 24_929_971_988_795_518_207_282_912);
        assertEq(token.balanceOf(daoCreator.addr), 1_994_397_759_103_641_456_582_631);
        assertEq(token.balanceOf(canvasCreator.addr), 16_242_135_358_518_904_777_503_680);
        assertEq(token.balanceOf(canvasCreator2.addr), 4_366_338_420_809_851_386_855_457);
        assertEq(token.balanceOf(nftMinter.addr), 1_828_501_010_587_210_222_195_480);
        assertEq(token.balanceOf(nftMinter2.addr), 0);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);

        for (uint256 i; i < 177; ++i) {
            drb.changeRound(i + 5);
            _mintNft(
                daoId,
                canvasId1,
                string.concat("test token uri ", vm.toString(i + 5)),
                0,
                canvasCreator.key,
                nftMinter.addr
            );
        }

        drb.changeRound(200);

        {
            string memory tokenUri = "test token uri 200";
            uint256 flatPrice = 0;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            vm.expectRevert(ExceedMaxMintableRound.selector);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.totalSupply(), 999_999_999_999_999_999_999_999_940);
    }

    function test_ExponentialRewardIssuacneAndProgressiveJackpot() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory param;
        param.daoUri = "test dao uri 1";
        param.mintableRound = 360;
        param.daoCreatorERC20RatioInBps = 800;
        param.canvasCreatorERC20RatioInBps = 8000;
        param.nftMinterERC20RatioInBps = 1000;
        param.daoFeePoolETHRatioInBps = 250;
        param.daoFeePoolETHRatioInBpsFlatPrice = 750;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.priceFactor = 35_000;
        param.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        param.rewardDecayFactor = 10_195;
        param.isProgressiveJackpot = true;
        param.actionType = 16;
        daoId = _createDao(param);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 1500);
        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 4", new bytes32[](0), 1800);

        drb.changeRound(2);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        assertEq(token.totalSupply(), 0);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.005 ether);

        _mintNft(daoId, canvasId1, "test token uri 1", 0.0319 ether, canvasCreator.key, nftMinter.addr);

        drb.changeRound(3);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 37_924_470_512_192_503_534_213_692);
        assertEq(token.balanceOf(daoCreator.addr), 3_033_957_640_975_400_282_737_095);
        assertEq(token.balanceOf(canvasCreator.addr), 30_908_443_467_436_890_380_384_158);
        assertEq(token.balanceOf(canvasCreator2.addr), 0);
        assertEq(token.balanceOf(nftMinter.addr), 3_223_579_993_536_362_800_408_163);
        assertEq(token.balanceOf(nftMinter2.addr), 0);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 270);

        drb.changeRound(4);

        _mintNft(daoId, canvasId1, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 3", 0.0123 ether, canvasCreator2.key, nftMinter2.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);

        drb.changeRound(5);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 74_498_353_887_096_351_093_157_026);
        assertEq(token.balanceOf(daoCreator.addr), 5_959_868_310_967_708_087_452_561);
        assertEq(token.balanceOf(canvasCreator.addr), 34_465_450_024_781_357_654_911_463);
        assertEq(token.balanceOf(canvasCreator2.addr), 26_347_336_767_655_673_400_683_947);
        assertEq(token.balanceOf(nftMinter.addr), 3_594_556_137_553_883_927_199_354);
        assertEq(token.balanceOf(nftMinter2.addr), 2_641_175_568_395_801_001_046_557);

        drb.changeRound(11);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.005 ether);
        _mintNft(daoId, canvasId2, "test token uri 4", 0, canvasCreator2.key, nftMinter2.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);

        drb.changeRound(12);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 192_216_596_167_066_759_069_283_899);
        assertEq(token.balanceOf(daoCreator.addr), 15_377_327_693_365_340_725_542_710);
        assertEq(token.balanceOf(canvasCreator.addr), 34_465_450_024_781_357_654_911_463);
        assertEq(token.balanceOf(canvasCreator2.addr), 122_640_858_952_671_467_125_155_729);
        assertEq(token.balanceOf(nftMinter.addr), 3_594_556_137_553_883_927_199_354);
        assertEq(token.balanceOf(nftMinter2.addr), 12_294_071_435_353_374_455_088_960);

        drb.changeRound(270);

        _mintNft(daoId, canvasId1, "test token uri 5", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(271);

        {
            string memory tokenUri = "test token uri 6";
            uint256 flatPrice = 0;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            vm.expectRevert(ExceedMaxMintableRound.selector);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.totalSupply(), 999_999_999_999_999_999_999_999_942);
    }

    function test_ExponentialRewardIssuacneAndNotProgressiveJackpot() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory param;
        param.daoUri = "test dao uri 1";
        param.mintableRound = 360;
        param.daoCreatorERC20RatioInBps = 800;
        param.canvasCreatorERC20RatioInBps = 8000;
        param.nftMinterERC20RatioInBps = 1000;
        param.daoFeePoolETHRatioInBps = 250;
        param.daoFeePoolETHRatioInBpsFlatPrice = 750;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.priceFactor = 35_000;
        param.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        param.rewardDecayFactor = 10_195;
        param.actionType = 16;
        daoId = _createDao(param);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 1500);
        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 4", new bytes32[](0), 1800);

        drb.changeRound(2);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        assertEq(token.totalSupply(), 0);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.005 ether);

        _mintNft(daoId, canvasId1, "test token uri 1", 0.0319 ether, canvasCreator.key, nftMinter.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.005 ether);

        drb.changeRound(3);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 19_145_331_857_974_873_658_396_068);
        assertEq(token.balanceOf(daoCreator.addr), 1_531_626_548_637_989_892_671_685);
        assertEq(token.balanceOf(canvasCreator.addr), 15_603_445_464_249_522_031_592_795);
        assertEq(token.balanceOf(canvasCreator2.addr), 0);
        assertEq(token.balanceOf(nftMinter.addr), 1_627_353_207_927_864_260_963_665);
        assertEq(token.balanceOf(nftMinter2.addr), 0);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 180);

        drb.changeRound(4);

        _mintNft(daoId, canvasId1, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 3", 0.0123 ether, canvasCreator2.key, nftMinter2.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);
        assertEq(token.totalSupply(), 19_145_331_857_974_873_658_396_068);

        drb.changeRound(5);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 38_516_893_372_315_331_601_968_308);
        assertEq(token.balanceOf(daoCreator.addr), 3_081_351_469_785_226_528_157_464);
        assertEq(token.balanceOf(canvasCreator.addr), 17_487_433_845_417_478_263_575_059);
        assertEq(token.balanceOf(canvasCreator2.addr), 13_955_014_011_006_091_901_202_224);
        assertEq(token.balanceOf(nftMinter.addr), 1_823_842_793_693_847_426_262_428);
        assertEq(token.balanceOf(nftMinter2.addr), 1_398_913_384_966_380_850_731_763);

        drb.changeRound(11);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.005 ether);
        _mintNft(daoId, canvasId2, "test token uri 4", 0, canvasCreator2.key, nftMinter2.addr);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);

        drb.changeRound(12);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 57_517_934_583_046_531_154_270_652);
        assertEq(token.balanceOf(daoCreator.addr), 4_601_434_766_643_722_492_341_651);
        assertEq(token.balanceOf(canvasCreator.addr), 17_487_433_845_417_478_263_575_059);
        assertEq(token.balanceOf(canvasCreator2.addr), 29_497_865_721_384_213_134_985_541);
        assertEq(token.balanceOf(nftMinter.addr), 1_823_842_793_693_847_426_262_428);
        assertEq(token.balanceOf(nftMinter2.addr), 2_956_998_764_246_339_214_020_555);

        for (uint256 i; i < 177; ++i) {
            drb.changeRound(i + 13);

            _mintNft(
                daoId,
                canvasId1,
                string.concat("test token uri ", vm.toString(i + 5)),
                0,
                canvasCreator.key,
                nftMinter.addr
            );
        }

        drb.changeRound(200);
        {
            string memory tokenUri = "test token uri 200";
            uint256 flatPrice = 0;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            vm.expectRevert(ExceedMaxMintableRound.selector);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.totalSupply(), 999_999_999_999_999_999_999_999_884);
    }

    function test_LinearRewardIssuanceAndNotProgressiveJackpotAndSetMintableRoundMultipleTimes() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory param;
        param.daoUri = "test dao uri 1";
        param.mintableRound = 90;
        param.daoCreatorERC20RatioInBps = 800;
        param.canvasCreatorERC20RatioInBps = 8000;
        param.nftMinterERC20RatioInBps = 1000;
        param.daoFeePoolETHRatioInBps = 250;
        param.daoFeePoolETHRatioInBpsFlatPrice = 750;
        param.actionType = 16;
        daoId = _createDao(param);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 0);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        _mintNft(daoId, canvasId1, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        //  claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 11_111_111_111_111_111_111_111_111);
        assertEq(token.balanceOf(daoCreator.addr), 888_888_888_888_888_888_888_888);
        assertEq(token.balanceOf(canvasCreator.addr), 8_888_888_888_888_888_888_888_888);
        assertEq(token.balanceOf(nftMinter.addr), 1_111_111_111_111_111_111_111_111);

        drb.changeRound(10);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 120);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether);
        _mintNft(daoId, canvasId1, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(11);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 22_222_222_222_222_222_222_222_222);
        assertEq(token.balanceOf(daoCreator.addr), 1_777_777_777_777_777_777_777_776);
        assertEq(token.balanceOf(canvasCreator.addr), 17_777_777_777_777_777_777_777_776);
        assertEq(token.balanceOf(nftMinter.addr), 2_222_222_222_222_222_222_222_222);

        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        _mintNft(daoId, canvasId1, "test token uri 3", 0, canvasCreator.key, nftMinter.addr);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 60);

        drb.changeRound(12);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 30_508_474_576_271_186_440_677_965);
        assertEq(token.balanceOf(daoCreator.addr), 2_440_677_966_101_694_915_254_235);
        assertEq(token.balanceOf(canvasCreator.addr), 24_406_779_661_016_949_152_542_370);
        assertEq(token.balanceOf(nftMinter.addr), 3_050_847_457_627_118_644_067_796);

        drb.changeRound(15);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 180);

        drb.changeRound(18);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 270);

        _mintNft(daoId, canvasId1, "test token uri 4", 0.03 ether, canvasCreator.key, nftMinter.addr);

        drb.changeRound(19);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 34_139_528_978_607_249_412_810_257);
        assertEq(protocol.getRoundReward(daoId, 18), 3_631_054_402_336_062_972_132_292);
        assertEq(token.balanceOf(daoCreator.addr), 2_731_162_318_288_579_953_024_818);
        assertEq(token.balanceOf(canvasCreator.addr), 27_311_623_182_885_799_530_248_203);
        assertEq(token.balanceOf(nftMinter.addr), 3_413_952_897_860_724_941_281_025);

        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 30);
        hoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, 60);

        _mintNft(daoId, canvasId1, "test token uri 5", 0.5 ether, canvasCreator.key, nftMinter.addr);

        drb.changeRound(20);

        console2.log(protocol.getDaoRewardTotalRound(daoId, 0));
        console2.log(protocol.getDaoRewardTotalRound(daoId, 1));
        console2.log(protocol.getDaoRewardTotalRound(daoId, 2));
        console2.log(protocol.getDaoRewardTotalRound(daoId, 3));
        console2.log(protocol.getDaoTotalReward(daoId, 0));
        console2.log(protocol.getDaoTotalReward(daoId, 1));
        console2.log(protocol.getDaoTotalReward(daoId, 2));
        console2.log(protocol.getDaoTotalReward(daoId, 3));
        console2.log(protocol.getDaoRewardActiveRounds(daoId, 0).length);
        console2.log(protocol.getDaoRewardActiveRounds(daoId, 1).length);
        console2.log(protocol.getDaoRewardActiveRounds(daoId, 2).length);
        console2.log(protocol.getDaoRewardActiveRounds(daoId, 3).length);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 37_770_583_380_943_312_384_942_549);
        assertEq(protocol.getRoundReward(daoId, 19), 3_631_054_402_336_062_972_132_292);
        assertEq(token.balanceOf(daoCreator.addr), 3_021_646_670_475_464_990_795_401);
        assertEq(token.balanceOf(canvasCreator.addr), 30_216_466_704_754_649_907_954_036);
        assertEq(token.balanceOf(nftMinter.addr), 3_777_058_338_094_331_238_494_254);

        _mintNft(daoId, canvasId1, "test token uri 6", 0.7 ether, canvasCreator.key, nftMinter.addr);

        drb.changeRound(21);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 55_265_663_683_107_979_432_489_048);
        assertEq(protocol.getRoundReward(daoId, 20), 17_495_080_302_164_667_047_546_499);
        assertEq(token.balanceOf(daoCreator.addr), 4_421_253_094_648_638_354_599_120);
        assertEq(token.balanceOf(canvasCreator.addr), 44_212_530_946_486_383_545_991_235);
        assertEq(token.balanceOf(nftMinter.addr), 5_526_566_368_310_797_943_248_903);

        for (uint256 i; i < 54; ++i) {
            drb.changeRound(i + 22);
            _mintNft(
                daoId,
                canvasId1,
                string.concat("test token uri ", vm.toString(i + 7)),
                0.7 ether,
                canvasCreator.key,
                nftMinter.addr
            );
        }

        drb.changeRound(200);
        {
            string memory tokenUri = "test token uri 200";
            uint256 flatPrice = 0;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            vm.expectRevert(ExceedMaxMintableRound.selector);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        assertEq(token.totalSupply(), 999_999_999_999_999_999_999_999_994);
    }

    function test_ZeroDfp() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory param;
        param.daoUri = "test dao uri 1";
        param.mintableRound = 90;
        param.floorPriceRank = 9999;
        param.daoCreatorERC20RatioInBps = 800;
        param.canvasCreatorERC20RatioInBps = 8000;
        param.nftMinterERC20RatioInBps = 1000;
        param.daoFeePoolETHRatioInBps = 250;
        param.daoFeePoolETHRatioInBpsFlatPrice = 750;
        param.actionType = 16;
        daoId = _createDao(param);

        hoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 4", new bytes32[](0), 0);

        _mintNft(daoId, canvasId1, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId1, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 3", 0, canvasCreator2.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 4", 0, canvasCreator2.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 5", 0, canvasCreator2.key, nftMinter.addr);

        drb.changeRound(2);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 11_111_111_111_111_111_111_111_111);
        assertEq(token.balanceOf(daoCreator.addr), 888_888_888_888_888_888_888_888);
        assertEq(token.balanceOf(canvasCreator.addr), 3_555_555_555_555_555_555_555_555);
        assertEq(token.balanceOf(canvasCreator2.addr), 5_333_333_333_333_333_333_333_333);
        assertEq(token.balanceOf(nftMinter.addr), 1_111_111_111_111_111_111_111_111);

        string[] memory tokenUris = new string[](2);
        tokenUris[0] = "test token uri 6";
        tokenUris[1] = "test token uri 7";
        uint256[] memory flatPrices = new uint256[](2);
        // batchMint问题
        _batchMint(daoId, canvasId1, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);
        tokenUris = new string[](3);
        tokenUris[0] = "test token uri 8";
        tokenUris[1] = "test token uri 9";
        tokenUris[2] = "test token uri 10";
        flatPrices = new uint256[](3);
        // batchMint问题
        _batchMint(daoId, canvasId2, tokenUris, flatPrices, canvasCreator2.key, nftMinter.addr);

        drb.changeRound(3);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 22_222_222_222_222_222_222_222_222);
        assertEq(token.balanceOf(daoCreator.addr), 1_777_777_777_777_777_777_777_776);
        assertEq(token.balanceOf(canvasCreator.addr), 7_111_111_111_111_111_111_111_110);
        assertEq(token.balanceOf(canvasCreator2.addr), 10_666_666_666_666_666_666_666_666);
        assertEq(token.balanceOf(nftMinter.addr), 2_222_222_222_222_222_222_222_222);

        tokenUris = new string[](2);
        tokenUris[0] = "test token uri 11";
        tokenUris[1] = "test token uri 12";
        flatPrices = new uint256[](2);
        // batchMint问题
        _batchMint(daoId, canvasId1, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);
        tokenUris = new string[](3);
        tokenUris[0] = "test token uri 13";
        tokenUris[1] = "test token uri 14";
        tokenUris[2] = "test token uri 15";
        flatPrices = new uint256[](3);
        // batchMint问题
        _batchMint(daoId, canvasId2, tokenUris, flatPrices, canvasCreator2.key, nftMinter2.addr);

        drb.changeRound(4);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 33_333_333_333_333_333_333_333_333);
        assertEq(token.balanceOf(daoCreator.addr), 2_666_666_666_666_666_666_666_664);
        assertEq(token.balanceOf(canvasCreator.addr), 10_666_666_666_666_666_666_666_665);
        assertEq(token.balanceOf(canvasCreator2.addr), 15_999_999_999_999_999_999_999_999);
        assertEq(token.balanceOf(nftMinter.addr), 2_666_666_666_666_666_666_666_666);
        assertEq(token.balanceOf(nftMinter2.addr), 666_666_666_666_666_666_666_666);

        _mintNft(daoId, canvasId1, "test token uri 16", 0, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 17", 0, canvasCreator2.key, nftMinter.addr);
        tokenUris = new string[](2);
        tokenUris[0] = "test token uri 18";
        tokenUris[1] = "test token uri 19";
        flatPrices = new uint256[](2);
        // batchMint问题
        _batchMint(daoId, canvasId1, tokenUris, flatPrices, canvasCreator.key, nftMinter2.addr);
        tokenUris = new string[](2);
        tokenUris[0] = "test token uri 20";
        tokenUris[1] = "test token uri 21";
        flatPrices = new uint256[](2);
        // batchMint问题
        _batchMint(daoId, canvasId2, tokenUris, flatPrices, canvasCreator2.key, nftMinter2.addr);

        drb.changeRound(5);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        assertEq(token.totalSupply(), 44_444_444_444_444_444_444_444_444);
        assertEq(token.balanceOf(daoCreator.addr), 3_555_555_555_555_555_555_555_552);
        assertEq(token.balanceOf(canvasCreator.addr), 15_111_111_111_111_111_111_111_109);
        assertEq(token.balanceOf(canvasCreator2.addr), 20_444_444_444_444_444_444_444_443);
        assertEq(token.balanceOf(nftMinter.addr), 3_037_037_037_037_037_037_037_036);
        assertEq(token.balanceOf(nftMinter2.addr), 1_407_407_407_407_407_407_407_406);
    }
}