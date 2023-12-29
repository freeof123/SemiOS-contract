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

    function _calculateETHRoundRewardNoProgressiveJackpot(
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

    function _random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp)));
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
            rewardCalculate = _calculateETHRoundRewardNoProgressiveJackpot(
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
            rewardCalculate = _calculateETHRoundRewardNoProgressiveJackpot(
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

    function test_getRoundReward_for_multiRounds_and_multiMintNFT_notProgressiveJackpot_max_mintableRounds_canvasPrice_1dot5xDecay(
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
            rewardCalculate = _calculateETHRoundRewardNoProgressiveJackpot(
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

    //start this progressiveJackpot test
    function test_getRoundReward_for_multiRounds_and_multiMintNFT_ProgressiveJackpot_max_mintableRounds_noCanvasPriceChange(
    )
        public
    {
        uint256 mintableRound = 366;
        uint256 mintNumberForSingleRound = 3;
        uint256 flatPrice = 0.01 ether;
        uint256 reward;
        uint256 rewardCalculate;
        uint256 nextCanvasPrice = 0.01 ether;
        uint256 decayFactor = 0;

        bytes32 daoId = _createDaoAndCanvasAndOneNFT(
            mintableRound, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, decayFactor, true, false, flatPrice
        );

        uint256 previousActiveRound;
        for (uint256 j = 2; j < mintableRound + 1; j++) {
            vm.roll(j);
            bool newRound = true;
            uint256 remaingRound = protocol.getDaoRemainingRound(daoId);
            previousActiveRound = protocol.getDaoLastActiveRound(daoId);
            reward = protocol.getDaoAssetPool(daoId).balance * (j - previousActiveRound)
                / (remaingRound + j - previousActiveRound - 1);
            for (uint256 i = 0; i < mintNumberForSingleRound; i++) {
                if (_random() % 2 == 0) {
                    super._mintNft(
                        daoId,
                        canvasId,
                        string.concat("test token uri_", vm.toString(uint256(j)), vm.toString(uint256(i))),
                        flatPrice,
                        canvasCreator.key,
                        nftMinter.addr
                    );
                }
            }
            //current round is not active round, reward = 0
            if (j != protocol.getDaoLastActiveRound(daoId)) {
                reward = 0;
            }

            assertApproxEqAbs(
                IPDProtocolReadable(address(protocol)).getRoundETHReward(daoId, j),
                reward,
                maxDelta,
                string.concat(
                    "test_getRoundReward_for_multiRounds_and_multiMintNFT_ProgressiveJackpot_max_mintableRounds_noCanvasPriceChange_ETHReward_ERROR_",
                    vm.toString(j)
                )
            );
        }
    }

    function test_getRoundReward_for_multiRounds_and_multiMintNFT_ProgressiveJackpot_max_mintableRounds_canvasPrice_2xDecay(
    )
        public
    {
        uint256 mintableRound = 366;
        uint256 mintNumberForSingleRound = 3;
        uint256 flatPrice = 0.01 ether;
        uint256 reward;
        uint256 rewardCalculate;
        uint256 nextCanvasPrice = 0.01 ether;
        uint256 decayFactor = 0;

        bytes32 daoId = _createDaoAndCanvasAndOneNFT(
            mintableRound, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, decayFactor, true, false, flatPrice
        );

        uint256 previousActiveRound;
        for (uint256 j = 2; j < mintableRound + 1; j++) {
            vm.roll(j);
            bool newRound = true;
            uint256 remaingRound = protocol.getDaoRemainingRound(daoId);
            previousActiveRound = protocol.getDaoLastActiveRound(daoId);
            reward = protocol.getDaoAssetPool(daoId).balance * (j - previousActiveRound)
                / (remaingRound + j - previousActiveRound - 1);
            for (uint256 i = 0; i < mintNumberForSingleRound; i++) {
                if (_random() % 2 == 0) {
                    super._mintNft(
                        daoId,
                        canvasId,
                        string.concat("test token uri_", vm.toString(uint256(j)), vm.toString(uint256(i))),
                        flatPrice,
                        canvasCreator.key,
                        nftMinter.addr
                    );
                }
            }
            //current round is not active round, reward = 0
            if (j != protocol.getDaoLastActiveRound(daoId)) {
                reward = 0;
            }

            assertApproxEqAbs(
                IPDProtocolReadable(address(protocol)).getRoundETHReward(daoId, j),
                reward,
                maxDelta,
                string.concat(
                    "test_getRoundReward_for_multiRounds_and_multiMintNFT_ProgressiveJackpot_max_mintableRounds_noCanvasPriceChange_ETHReward_ERROR_",
                    vm.toString(j)
                )
            );
        }
    }
}

// >>> 35 / 9
// 3.888888888888889
// >>> (35 * 8 / 9 + 35)/7
// 9.444444444444445
// >>> (35 * 8 / 9 + 35)/8
// 8.26388888888889
// >>> (((35 * 8 / 9 + 35) * 7 / 8) + 35)/7
// 13.26388888888889
// >>> 35 / 18
// 1.9444444444444444
// >>> (0.01 * 0.35 * 8 / 9 + 0.01 * 0.35)*2/7
// 0.001888888888888889
// >>> (0.01 * 0.35 * 8 / 9 + 0.01 * 0.35)*2 / 8
// 0.0016527777777777778
// >>> ((0.01 * 0.35 * 8 / 9 + 0.01 * 0.35)*2 * 7/ 8 + 0.01 * 0.35) * 2 / 6
// 0.005023148148148148
// >>> (0.01 * 0.35 * 8 / 9 + 0.01 * 0.35) - (0.01 * 0.35 * 8 / 9 + 0.01 * 0.35)*2 / 8
// 0.004958333333333334
// >>> 0.004958333333333334 * 2 / 6
// 0.001652777777777778
// >>> 0.004958333333333334 + 0.01 * 0.35
// 0.008458333333333333
// >>> 0.008458333333333333 * 2 / 6
// 0.0028194444444444443
