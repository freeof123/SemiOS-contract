// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { FixedPointMathLib as Math } from "solmate/utils/FixedPointMathLib.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";

contract GetRoundRewardTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_getRoundReward_Exponential_reward_issuance_2x_decayFactor_notProgressiveJackpot_30_mintableRounds()
        public
    {
        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 30,
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
                daoCreatorERC20Ratio: 300,
                canvasCreatorERC20Ratio: 9500,
                nftMinterERC20Ratio: 3000,
                daoFeePoolETHRatio: 3000,
                daoFeePoolETHRatioFlatPrice: 3500
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 20_000,
                isProgressiveJackpot: false
            }),
            0
        );
        drb.changeRound(1);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        for (uint256 i = 1; i < 11; i++) {
            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                500_000_000_465_661_287_741_420_127,
                1,
                string.concat("round ", vm.toString(i))
            );
        }

        // mint for 30 rounds
        for (uint256 j = 2; j < 32; j++) {
            drb.changeRound(j);

            string memory tokenUri = string.concat("test token uri", vm.toString(j));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();

            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                500_000_000_465_661_287_741_420_127 / 2 ** (j - 2),
                1,
                string.concat("round ", vm.toString(j))
            );

            drb.changeRound(j + 1);

            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                500_000_000_465_661_287_741_420_127 / 2 ** (j - 2),
                1,
                string.concat("round ", vm.toString(j))
            );
            for (uint256 i = j + 1; i < j + 11; i++) {
                assertApproxEqAbs(
                    ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                    500_000_000_465_661_287_741_420_127 / 2 ** (j - 1),
                    1,
                    string.concat("round ", vm.toString(i))
                );
            }
        }

        drb.changeRound(33);
        protocol.claimProjectERC20Reward(daoId);
        assertApproxEqAbs(
            D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
            ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
            100,
            "total supply"
        );
    }

    function test_getRoundReward_Exponential_reward_issuance_2x_decayFactor_notProgressiveJackpot_max_mintableRounds()
        public
    {
        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 366,
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
                daoCreatorERC20Ratio: 300,
                canvasCreatorERC20Ratio: 9500,
                nftMinterERC20Ratio: 3000,
                daoFeePoolETHRatio: 3000,
                daoFeePoolETHRatioFlatPrice: 3500
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 20_000,
                isProgressiveJackpot: false
            }),
            0
        );
        drb.changeRound(1);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        for (uint256 i = 1; i < 11; i++) {
            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                5e26,
                1,
                string.concat("round ", vm.toString(i))
            );
        }

        // mint for 30 rounds
        for (uint256 j = 2; j < 368; j++) {
            drb.changeRound(j);

            string memory tokenUri = string.concat("test token uri", vm.toString(j));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();

            uint256 temp = 5e26;
            for (uint256 k; k < j - 2; k++) {
                temp /= 2;
            }
            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                temp,
                1,
                string.concat("round ", vm.toString(j))
            );

            drb.changeRound(j + 1);

            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                temp,
                1,
                string.concat("round ", vm.toString(j))
            );
            for (uint256 i = j + 1; i < j + 11; i++) {
                assertApproxEqAbs(
                    ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                    temp / 2,
                    1,
                    string.concat("round ", vm.toString(i))
                );
            }
        }

        drb.changeRound(371);
        protocol.claimProjectERC20Reward(daoId);
        assertApproxEqAbs(
            D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
            ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
            100,
            "total supply"
        );
    }

    function test_getRoundReward_Exponential_reward_issuance_3x_decayFactor_notProgressiveJackpot_max_mintableRounds()
        public
    {
        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 366,
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
                daoCreatorERC20Ratio: 300,
                canvasCreatorERC20Ratio: 9500,
                nftMinterERC20Ratio: 3000,
                daoFeePoolETHRatio: 3000,
                daoFeePoolETHRatioFlatPrice: 3500
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 30_000,
                isProgressiveJackpot: false
            }),
            0
        );
        drb.changeRound(1);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        for (uint256 i = 1; i < 11; i++) {
            assertEq(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                666_666_666_666_666_666_666_666_667,
                string.concat("round ", vm.toString(i))
            );
        }

        // mint for 30 rounds
        for (uint256 j = 2; j < 368; j++) {
            drb.changeRound(j);

            string memory tokenUri = string.concat("test token uri", vm.toString(j));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();

            uint256 temp = 666_666_666_666_666_666_666_666_667;
            // for (uint256 k; k < j - 2; k++) {
            //     temp /= 3;
            // }
            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                temp * Math.rpow(uint256(1e27) / 3, j - 2, 1e27) / 1e27,
                1,
                string.concat("round ", vm.toString(j))
            );

            drb.changeRound(j + 1);

            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                temp * Math.rpow(uint256(1e27) / 3, j - 2, 1e27) / 1e27,
                1,
                string.concat("round ", vm.toString(j))
            );
            for (uint256 i = j + 1; i < j + 11; i++) {
                assertApproxEqAbs(
                    ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                    temp * Math.rpow(uint256(1e27) / 3, j - 2, 1e27) / 1e27 / 3,
                    1,
                    string.concat("round ", vm.toString(i))
                );
            }
        }

        drb.changeRound(371);
        protocol.claimProjectERC20Reward(daoId);
        assertApproxEqAbs(
            D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
            ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
            100,
            "total supply"
        );
    }

    function test_getRoundReward_Exponential_reward_issuance_1dot5x_decayFactor_notProgressiveJackpot_max_mintableRounds(
    )
        public
    {
        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 366,
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
                daoCreatorERC20Ratio: 300,
                canvasCreatorERC20Ratio: 9500,
                nftMinterERC20Ratio: 3000,
                daoFeePoolETHRatio: 3000,
                daoFeePoolETHRatioFlatPrice: 3500
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 15_000,
                isProgressiveJackpot: false
            }),
            0
        );
        drb.changeRound(1);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        for (uint256 i = 1; i < 11; i++) {
            assertEq(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                333_333_333_333_333_333_333_333_334,
                string.concat("round ", vm.toString(i))
            );
        }

        // mint for 30 rounds
        for (uint256 j = 2; j < 368; j++) {
            drb.changeRound(j);

            string memory tokenUri = string.concat("test token uri", vm.toString(j));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();

            uint256 temp = 333_333_333_333_333_333_333_333_334;
            // for (uint256 k; k < j - 2; k++) {
            //     temp /= 3;
            // }
            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27,
                1,
                string.concat("round ", vm.toString(j))
            );

            drb.changeRound(j + 1);

            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27,
                1,
                string.concat("round ", vm.toString(j))
            );
            for (uint256 i = j + 1; i < j + 11; i++) {
                assertApproxEqAbs(
                    ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                    temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27 * 10_000 / 15_000,
                    1,
                    string.concat("round ", vm.toString(i))
                );
            }
        }

        drb.changeRound(371);
        protocol.claimProjectERC20Reward(daoId);
        assertApproxEqAbs(
            D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
            ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
            100,
            "total supply"
        );
    }

    function test_getRoundReward_Exponential_reward_issuance_1dot5x_decayFactor_notProgressiveJackpot_30_mintableRounds(
    )
        public
    {
        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 30,
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
                daoCreatorERC20Ratio: 300,
                canvasCreatorERC20Ratio: 9500,
                nftMinterERC20Ratio: 3000,
                daoFeePoolETHRatio: 3000,
                daoFeePoolETHRatioFlatPrice: 3500
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 15_000,
                isProgressiveJackpot: false
            }),
            0
        );
        drb.changeRound(1);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        for (uint256 i = 1; i < 11; i++) {
            assertEq(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                333_335_071_707_416_068_263_145_206,
                string.concat("round ", vm.toString(i))
            );
        }

        // mint for 30 rounds
        for (uint256 j = 2; j < 32; j++) {
            drb.changeRound(j);

            string memory tokenUri = string.concat("test token uri", vm.toString(j));
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            startHoax(nftMinter.addr);
            protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            vm.stopPrank();

            uint256 temp = 333_335_071_707_416_068_263_145_206;
            // for (uint256 k; k < j - 2; k++) {
            //     temp /= 3;
            // }
            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27,
                1,
                string.concat("round ", vm.toString(j))
            );

            drb.changeRound(j + 1);

            assertApproxEqAbs(
                ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
                temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27,
                1,
                string.concat("round ", vm.toString(j))
            );
            for (uint256 i = j + 1; i < j + 11; i++) {
                assertApproxEqAbs(
                    ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
                    temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27 * 10_000 / 15_000,
                    1,
                    string.concat("round ", vm.toString(i))
                );
            }
        }

        drb.changeRound(42);
        protocol.claimProjectERC20Reward(daoId);
        assertApproxEqAbs(
            D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
            ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
            100,
            "total supply"
        );
    }
}
