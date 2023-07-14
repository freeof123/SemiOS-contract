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
        canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0), 0);
        hoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId);
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
        assertEq(token.balanceOf(protocolFeePool.addr), protocolRewardPerRound, "protocol fee pool");
        assertEq(token.balanceOf(daoCreator.addr), daoRewardPerRound, "dao creator");
        assertEq(token.balanceOf(canvasCreator.addr), canvasRewardPerRound, "canvas creator");

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
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
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
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
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
        drb.changeRound(1);
        hoax(daoCreator.addr);
        daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: mintableRound,
                floorPriceRank: 0,
                maxNftRank: 0,
                royaltyFee: 750,
                projectUri: "test dao uri",
                projectIndex: 0
            }),
            Whitelist({
                minterMerkleRoot: bytes32(0),
                minterNFTHolderPasses: new address[](0),
                canvasCreatorMerkleRoot: bytes32(0),
                canvasCreatorNFTHolderPasses: new address[](0)
            }),
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            DaoMintCapParam({ daoMintCap: 0, userMintCapParams: new UserMintCapParam[](0) }),
            DaoETHAndERC20SplitRatioParam({
                daoCreatorERC20Ratio: 1900,
                canvasCreatorERC20Ratio: 4000,
                nftMinterERC20Ratio: 3900,
                daoFeePoolETHRatio: 3000,
                daoFeePoolETHRatioFlatPrice: 3500
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 12_600,
                isProgressiveJackpot: true
            }),
            16
        );
        drb.changeRound(1);
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
        drb.changeRound(1);
        hoax(daoCreator.addr);
        daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: mintableRound,
                floorPriceRank: 0,
                maxNftRank: 0,
                royaltyFee: 750,
                projectUri: "test dao uri",
                projectIndex: 0
            }),
            Whitelist({
                minterMerkleRoot: bytes32(0),
                minterNFTHolderPasses: new address[](0),
                canvasCreatorMerkleRoot: bytes32(0),
                canvasCreatorNFTHolderPasses: new address[](0)
            }),
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            DaoMintCapParam({ daoMintCap: 0, userMintCapParams: new UserMintCapParam[](0) }),
            DaoETHAndERC20SplitRatioParam({
                daoCreatorERC20Ratio: 1900,
                canvasCreatorERC20Ratio: 4000,
                nftMinterERC20Ratio: 3900,
                daoFeePoolETHRatio: 3000,
                daoFeePoolETHRatioFlatPrice: 3500
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 12_600,
                isProgressiveJackpot: true
            }),
            16
        );
        drb.changeRound(1);
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
}
