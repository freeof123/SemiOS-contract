// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { FixedPointMathLib as Math } from "solmate/utils/FixedPointMathLib.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";

contract GetRoundRewardTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;
    bytes32 public canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
    uint256 maxDelta = 1;
    uint256 mintFeeRatioToAssetPoolNoFiatPrice = 2000;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function _createDaoAndCanvasAndOneNFT(
        uint256 mintableRound,
        RewardTemplateType rewardTemplateType,
        uint256 priceFactor,
        bool isProgressiveJackpot,
        bool uniPriceModeOff,
        uint256 flatPrice
    )
        internal
        returns (bytes32 daoId)
    {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = mintableRound;
        createDaoParam.rewardTemplateType = rewardTemplateType;
        createDaoParam.priceFactor = priceFactor;
        createDaoParam.isProgressiveJackpot = isProgressiveJackpot;
        createDaoParam.noPermission = true;
        createDaoParam.isBasicDao = true;
        createDaoParam.selfRewardRatioERC20 = 10_000;
        createDaoParam.selfRewardRatioETH = 10_000;
        createDaoParam.uniPriceModeOff = uniPriceModeOff;
        daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);
        vm.roll(1);
        super._createCanvasAndMintNft(
            daoId,
            canvasId,
            "test token uri 1",
            "test canvas uri 1",
            flatPrice,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );
    }

    function _calculateETHRoundReward(
        uint256 mintNumberForSingleRound,
        uint256 priceFactor,
        uint256 mintFeeRatioToAssetPool,
        uint256 currentRound,
        uint256 remainingRound,
        uint256 previousRoundStartCanvasPrice,
        uint256 previousoundStartDaoAssetPoolBalance
    )
        internal
        returns (uint256 rewardCalculate)
    {
        uint256 sumMintFee = 0;
        for (uint256 i = 0; i < mintNumberForSingleRound; i++) {
            previousRoundStartCanvasPrice =
                i == 0 ? previousRoundStartCanvasPrice : previousRoundStartCanvasPrice * priceFactor / 1e4;
            sumMintFee += previousRoundStartCanvasPrice;
        }
        if (currentRound == 2) {
            rewardCalculate = 0.01 ether * mintFeeRatioToAssetPoolNoFiatPrice / 10_000;
        } else {
            rewardCalculate = previousoundStartDaoAssetPoolBalance * remainingRound / (remainingRound + 1)
                + sumMintFee * mintFeeRatioToAssetPool / 1e4;
        }
        rewardCalculate /= (remainingRound);
    }

    function test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_noCanvasPriceChange(
    )
        public
    {
        uint256 mintableRound = 366;
        uint256 flatPrice = 0.01 ether;
        uint256 mintNumberForSingleRound = 6;
        bytes32 daoId = _createDaoAndCanvasAndOneNFT(
            mintableRound, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 20_000, false, false, flatPrice
        );

        for (uint256 i = 1; i < 11; i++) {
            assertApproxEqAbs(
                IPDProtocolReadable(address(protocol)).getRoundETHReward(daoId, i),
                0,
                1,
                string.concat("round ", vm.toString(i))
            );
        }

        // uint256 lastRoundETHBalance = 0;
        for (uint256 j = 2; j < mintableRound + 1; j++) {
            vm.roll(j);
            uint256 remaingRound = protocol.getDaoRemainingRound(daoId);
            uint256 distirbuteDaoAssetETHBalance = protocol.getDaoAssetPool(daoId).balance;
            uint256 reward = distirbuteDaoAssetETHBalance / remaingRound;
            // uint256 reward = protocol.getDaoRoundDistributeAmount(daoId, address(0), j, remaingRound);
            // assertEq(reward, protocol.getDaoRoundDistributeAmount(daoId, address(0), j, remaingRound));

            for (uint256 i = 0; i < mintNumberForSingleRound; i++) {
                super._mintNft(
                    daoId,
                    canvasId,
                    string.concat("test token uri", vm.toString(j), vm.toString(i)),
                    flatPrice,
                    canvasCreator.key,
                    nftMinter.addr
                );
            }

            assertApproxEqAbs(
                IPDProtocolReadable(address(protocol)).getRoundETHReward(daoId, j),
                reward,
                maxDelta,
                string.concat("round ", vm.toString(j))
            );

            for (uint256 i = j + 1; i < j + 11; i++) {
                assertApproxEqAbs(
                    IPDProtocolReadable(address(protocol)).getRoundETHReward(daoId, i),
                    0,
                    1,
                    string.concat("Extra round check reward", vm.toString(i))
                );
            }
        }

        vm.roll(mintableRound + 5);
        protocol.claimDaoCreatorReward(daoId);
        assertApproxEqAbs(
            D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
            ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
            100,
            "total supply"
        );
    }

    //two test
    //1. price change, reward = daoAssetPoolBalance / remaingRound still work
    //2. canvasPrice should change as expected
    function test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_2xDecay(
    )
        public
    {
        uint256 mintableRound = 20;
        uint256 mintNumberForSingleRound = 3;
        uint256 flatPrice = 0 ether;
        uint256 reward;
        uint256 rewardCalculate;
        uint256 nextCanvasPrice = 0.01 ether;
        uint256 decayFactor = 20_000;

        bytes32 daoId = _createDaoAndCanvasAndOneNFT(
            mintableRound, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, decayFactor, false, true, flatPrice
        );

        uint256 previousRoundDaoAssetPoolBalance;
        uint256 previousNextCanvasPrice = 0.01 ether;

        for (uint256 j = 2; j < mintableRound + 1; j++) {
            vm.roll(j);
            bool newRound = true;
            uint256 remaingRound = protocol.getDaoRemainingRound(daoId);
            reward = protocol.getDaoAssetPool(daoId).balance / remaingRound;
            rewardCalculate = _calculateETHRoundReward(
                mintNumberForSingleRound,
                decayFactor,
                mintFeeRatioToAssetPoolNoFiatPrice,
                j,
                remaingRound,
                previousNextCanvasPrice,
                previousRoundDaoAssetPoolBalance
            );
            previousRoundDaoAssetPoolBalance = protocol.getDaoAssetPool(daoId).balance;
            previousNextCanvasPrice = protocol.getCanvasNextPrice(daoId, canvasId);

            for (uint256 i = 0; i < mintNumberForSingleRound; i++) {
                nextCanvasPrice = newRound == true ? nextCanvasPrice : nextCanvasPrice * decayFactor / 1e4;
                newRound = false;
                assertApproxEqAbs(
                    protocol.getCanvasNextPrice(daoId, canvasId),
                    nextCanvasPrice,
                    maxDelta,
                    string.concat(
                        "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_2xDecay_NextCanvasPrice_ERROR_",
                        vm.toString(j),
                        vm.toString(i)
                    )
                );
                super._mintNft(
                    daoId,
                    canvasId,
                    string.concat("test token uri_", vm.toString(uint256(j)), vm.toString(uint256(i))),
                    flatPrice,
                    canvasCreator.key,
                    nftMinter.addr
                );
            }

            assertApproxEqAbs(
                IPDProtocolReadable(address(protocol)).getRoundETHReward(daoId, j),
                reward,
                maxDelta,
                string.concat(
                    "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_2xDecay_ETHReward_ERROR_",
                    vm.toString(j)
                )
            );
            assertApproxEqAbs(
                rewardCalculate,
                reward,
                maxDelta,
                string.concat(
                    "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_2xDecay_ETHReward_ERROR_RewardCal",
                    vm.toString(j)
                )
            );
        }
    }

    function test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_3xDecay(
    )
        public
    {
        uint256 mintableRound = 10;
        uint256 mintNumberForSingleRound = 3;
        uint256 flatPrice = 0 ether;
        uint256 reward;
        uint256 rewardCalculate;
        uint256 nextCanvasPrice = 0.01 ether;
        uint256 decayFactor = 30_000;

        bytes32 daoId = _createDaoAndCanvasAndOneNFT(
            mintableRound, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, decayFactor, false, true, flatPrice
        );

        uint256 previousRoundDaoAssetPoolBalance;
        uint256 previousNextCanvasPrice = 0.01 ether;

        for (uint256 j = 2; j < mintableRound + 1; j++) {
            vm.roll(j);
            bool newRound = true;
            uint256 remaingRound = protocol.getDaoRemainingRound(daoId);
            reward = protocol.getDaoAssetPool(daoId).balance / remaingRound;
            rewardCalculate = _calculateETHRoundReward(
                mintNumberForSingleRound,
                decayFactor,
                mintFeeRatioToAssetPoolNoFiatPrice,
                j,
                remaingRound,
                previousNextCanvasPrice,
                previousRoundDaoAssetPoolBalance
            );
            previousRoundDaoAssetPoolBalance = protocol.getDaoAssetPool(daoId).balance;
            previousNextCanvasPrice = protocol.getCanvasNextPrice(daoId, canvasId);

            for (uint256 i = 0; i < mintNumberForSingleRound; i++) {
                nextCanvasPrice = newRound == true ? nextCanvasPrice : nextCanvasPrice * decayFactor / 1e4;
                newRound = false;
                assertApproxEqAbs(
                    protocol.getCanvasNextPrice(daoId, canvasId),
                    nextCanvasPrice,
                    maxDelta,
                    string.concat(
                        "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_3xDecay_NextCanvasPrice_ERROR_",
                        vm.toString(j),
                        vm.toString(i)
                    )
                );
                super._mintNft(
                    daoId,
                    canvasId,
                    string.concat("test token uri_", vm.toString(uint256(j)), vm.toString(uint256(i))),
                    flatPrice,
                    canvasCreator.key,
                    nftMinter.addr
                );
            }

            assertApproxEqAbs(
                IPDProtocolReadable(address(protocol)).getRoundETHReward(daoId, j),
                reward,
                maxDelta,
                string.concat(
                    "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_3xDecay_ETHReward_ERROR_",
                    vm.toString(j)
                )
            );
            assertApproxEqAbs(
                rewardCalculate,
                reward,
                maxDelta,
                string.concat(
                    "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_3xDecay_ETHReward_ERROR_RewardCal",
                    vm.toString(j)
                )
            );
        }
    }

    function test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_1dot5Decay(
    )
        public
    {
        uint256 mintableRound = 10;
        uint256 mintNumberForSingleRound = 3;
        uint256 flatPrice = 0 ether;
        uint256 reward;
        uint256 rewardCalculate;
        uint256 nextCanvasPrice = 0.01 ether;
        uint256 decayFactor = 15_000;

        bytes32 daoId = _createDaoAndCanvasAndOneNFT(
            mintableRound, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, decayFactor, false, true, flatPrice
        );

        uint256 previousRoundDaoAssetPoolBalance;
        uint256 previousNextCanvasPrice = 0.01 ether;

        for (uint256 j = 2; j < mintableRound + 1; j++) {
            vm.roll(j);
            bool newRound = true;
            uint256 remaingRound = protocol.getDaoRemainingRound(daoId);
            reward = protocol.getDaoAssetPool(daoId).balance / remaingRound;
            rewardCalculate = _calculateETHRoundReward(
                mintNumberForSingleRound,
                decayFactor,
                mintFeeRatioToAssetPoolNoFiatPrice,
                j,
                remaingRound,
                previousNextCanvasPrice,
                previousRoundDaoAssetPoolBalance
            );
            previousRoundDaoAssetPoolBalance = protocol.getDaoAssetPool(daoId).balance;
            previousNextCanvasPrice = protocol.getCanvasNextPrice(daoId, canvasId);

            for (uint256 i = 0; i < mintNumberForSingleRound; i++) {
                nextCanvasPrice = newRound == true ? nextCanvasPrice : nextCanvasPrice * decayFactor / 1e4;
                newRound = false;
                assertApproxEqAbs(
                    protocol.getCanvasNextPrice(daoId, canvasId),
                    nextCanvasPrice,
                    maxDelta,
                    string.concat(
                        "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_1dot5xDecay_NextCanvasPrice_ERROR_",
                        vm.toString(j),
                        vm.toString(i)
                    )
                );
                super._mintNft(
                    daoId,
                    canvasId,
                    string.concat("test token uri_", vm.toString(uint256(j)), vm.toString(uint256(i))),
                    flatPrice,
                    canvasCreator.key,
                    nftMinter.addr
                );
            }

            assertApproxEqAbs(
                IPDProtocolReadable(address(protocol)).getRoundETHReward(daoId, j),
                reward,
                maxDelta,
                string.concat(
                    "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_1dot5xDecay_ETHReward_ERROR_",
                    vm.toString(j)
                )
            );
            assertApproxEqAbs(
                rewardCalculate,
                reward,
                maxDelta,
                string.concat(
                    "test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_1dot5xDecay_ETHReward_ERROR_RewardCal",
                    vm.toString(j)
                )
            );
        }
    }

    // function test_getRoundReward_Exponential_reward_issuance_2x_decayFactor_ProgressiveJackpot_30_mintableRounds()
    //     public
    // {
    //     _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 20_000, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 500_000_000_465_661_287_741_420_127);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 750_000_000_698_491_931_612_130_190);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 875_000_000_814_907_253_547_485_222);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_996_186_234_053_397_769_158_144);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_999_999_999_999_999);
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    // }

    // function test_getRoundReward_Exponential_reward_issuance_2x_decayFactor_ProgressiveJackpot_max_mintableRounds()
    //     public
    // {
    //     _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 20_000, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1), 5e26);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2), 75e25);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3), 875e24);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_996_185_302_734_375_000_000_000);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_068_677_425_384_521_484);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100), 1e27);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 200), 1e27);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 300), 1e27);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 366), 1e27);
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 367);
    // }

    // function
    // test_getRoundReward_Exponential_reward_issuance_2dot65x_decayFactor_ProgressiveJackpot_30_mintableRounds()
    //     public
    // {
    //     _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 26_500, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 622_641_509_434_087_250_289_909_344);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 857_600_569_597_893_759_833_271_359);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 946_264_365_886_122_631_359_068_346);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_999_975_924_758_731_203_841_883);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_999_999_999_999_999);
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    // }

    // function
    // test_getRoundReward_Exponential_reward_issuance_2dot65x_decayFactor_ProgressiveJackpot_max_mintableRounds()
    //     public
    // {
    //     _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 26_500, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 622_641_509_433_962_264_150_943_397);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 857_600_569_597_721_609_113_563_546);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 946_264_365_885_932_682_684_363_602);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_999_975_924_557_995_894_577_851);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_799_264_685_903_216);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100), 1e27);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 200), 1e27);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 300), 1e27);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 366), 1e27);
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 367);
    // }

    // function
    // test_getRoundReward_Exponential_reward_issuance_1dot5x_decayFactor_ProgressiveJackpot_30_mintableRounds()
    //     public
    // {
    //     _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 15_000, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 333_335_071_707_416_068_263_145_206);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 555_558_452_845_693_447_105_242_009);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 703_707_373_604_545_032_999_973_211);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_328_572_108_891_710_282_000_512);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_999_999_999_999_998);
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    // }

    // function
    // test_getRoundReward_Exponential_reward_issuance_1dot5x_decayFactor_ProgressiveJackpot_max_mintableRounds()
    //     public
    // {
    //     _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 15_000, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 333_333_333_333_333_333_333_333_334);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 555_555_555_555_555_555_555_555_556);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 703_703_703_703_703_703_703_703_704);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_323_360_515_401_135_637_924_405);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_994_784_904_949_153_436_736_982);
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100), 999_999_999_999_999_997_540_345_573
    //     );
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 200), 1e27);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 300), 1e27);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 366), 1e27);
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 367);
    // }

    // function test_getRoundReward_Linear_reward_issuance_ProgressiveJackpot_30_mintableRounds() public {
    //     _createDaoAndCanvas(30, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 33_333_333_333_333_333_333_333_333);
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2), 33_333_333_333_333_333_333_333_333 * 2
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3), 33_333_333_333_333_333_333_333_333 * 3
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18), 33_333_333_333_333_333_333_333_333 *
    // 18
    //     );
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_999_999_999_999_990);
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    // }

    // function test_getRoundReward_Linear_reward_issuance_ProgressiveJackpot_max_mintableRounds() public {
    //     _createDaoAndCanvas(366, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 2_732_240_437_158_469_945_355_191);
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2), 2_732_240_437_158_469_945_355_191 * 2
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3), 2_732_240_437_158_469_945_355_191 * 3
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18), 2_732_240_437_158_469_945_355_191 * 18
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30), 2_732_240_437_158_469_945_355_191 * 30
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100), 273_224_043_715_846_994_535_519_100
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 200), 273_224_043_715_846_994_535_519_100 *
    // 2
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 300), 273_224_043_715_846_994_535_519_100 *
    // 3
    //     );
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 366), 999_999_999_999_999_999_999_999_906
    //     );
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 367);
    // }

    // function test_getRoundReward_Linear_reward_issuance_notProgressiveJackpot_30_mintableRounds() public {
    //     vm.skip(true);
    //     _createDaoAndCanvas(30, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, false);

    //     for (uint256 i = 1; i < 11; i++) {
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //             33_333_333_333_333_333_333_333_333,
    //             string.concat("round ", vm.toString(i))
    //         );
    //     }

    //     // mint for 30 rounds
    //     for (uint256 j = 2; j < 32; j++) {
    //         vm.roll(j);

    //         string memory tokenUri = string.concat("test token uri", vm.toString(j));
    //         uint256 flatPrice = 0;
    //         bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         startHoax(nftMinter.addr);
    //         protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //             daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //         );
    //         vm.stopPrank();

    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //             33_333_333_333_333_333_333_333_333,
    //             string.concat("round ", vm.toString(j))
    //         );

    //         vm.roll(j + 1);

    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //             33_333_333_333_333_333_333_333_333,
    //             string.concat("round ", vm.toString(j))
    //         );
    //         for (uint256 i = j + 1; i < j + 11 && i < 31; i++) {
    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 33_333_333_333_333_333_333_333_333,
    //                 string.concat("round ", vm.toString(j))
    //             );
    //         }
    //     }

    //     vm.roll(42);
    //     // claim问题
    //     protocol.claimProjectERC20Reward(daoId);
    //     assertEq(
    //         D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
    //         999_999_999_999_999_999_999_999_990,
    //         "total supply"
    //     );
    // }

    // function test_getRoundReward_Linear_reward_issuance_notProgressiveJackpot_max_mintableRounds() public {
    //     vm.skip(true);
    //     _createDaoAndCanvas(366, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, false);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 2_732_240_437_158_469_945_355_191);
    //     for (uint256 i = 1; i < 11; i++) {
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //             2_732_240_437_158_469_945_355_191,
    //             string.concat("round ", vm.toString(i))
    //         );
    //     }

    //     // mint for 366 rounds
    //     for (uint256 j = 2; j < 368; j++) {
    //         vm.roll(j);

    //         string memory tokenUri = string.concat("test token uri", vm.toString(j));
    //         uint256 flatPrice = 0;
    //         bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         startHoax(nftMinter.addr);
    //         protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //             daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //         );
    //         vm.stopPrank();

    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //             2_732_240_437_158_469_945_355_191,
    //             string.concat("round ", vm.toString(j))
    //         );

    //         vm.roll(j + 1);

    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //             2_732_240_437_158_469_945_355_191,
    //             string.concat("round ", vm.toString(j))
    //         );
    //         for (uint256 i = j + 1; i < j + 11 && i < 367; i++) {
    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 2_732_240_437_158_469_945_355_191,
    //                 string.concat("round ", vm.toString(j))
    //             );
    //         }
    //     }

    //     vm.roll(420);
    //     // claim问题
    //     protocol.claimProjectERC20Reward(daoId);
    //     assertEq(
    //         D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
    //         999_999_999_999_999_999_999_999_906,
    //         "total supply"
    //     );
    // }

    // function
    // test_getRoundReward_Exponential_reward_issuance_1dot26x_decayFactor_ProgressiveJackpot_30_mintableRounds()
    //     public
    // {
    //     _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 12_600, true);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 206_550_537_035_966_409_568_996_316);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 370_479_534_683_558_798_115_818_789);

    //     {
    //         vm.roll(2);
    //         string memory tokenUri = "test token uri 1";
    //         uint256 flatPrice = 0;
    //         bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         startHoax(nftMinter.addr);
    //         protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //             daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //         );
    //         vm.stopPrank();
    //     }

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 130_102_379_085_390_784_560_970_216);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 23),
    // 625_576_871_083_750_305_360_515_774);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 629_520_465_316_441_201_884_181_206);
    //     vm.expectRevert(ExceedMaxMintableRound.selector);
    //     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    // }

    // function test_getRoundReward_on_new_checkpoint() public {
    //     _createDaoAndCanvas(90, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, true);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 11_111_111_111_111_111_111_111_111);
    //     assertEq(
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2), 11_111_111_111_111_111_111_111_111 * 2
    //     );

    //     {
    //         string memory tokenUri = "test token uri 1";
    //         uint256 flatPrice = 0;
    //         bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         startHoax(nftMinter.addr);
    //         protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //             daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //         );
    //         vm.stopPrank();
    //     }

    //     {
    //         vm.roll(2);
    //         string memory tokenUri = "test token uri 2";
    //         uint256 flatPrice = 0;
    //         bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         startHoax(nftMinter.addr);
    //         protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //             daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //         );
    //         vm.stopPrank();
    //     }

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 11_111_111_111_111_111_111_111_111);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 11_111_111_111_111_111_111_111_111);

    //     hoax(daoCreator.addr);
    //     D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 120);

    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 11_111_111_111_111_111_111_111_111);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 11_111_111_111_111_111_111_111_111);
    //     assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 8_286_252_354_048_964_218_455_743);
    // }
}
