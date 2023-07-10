// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as MathLady } from "solady/utils/FixedPointMathLib.sol";
import { FixedPointMathLib as MathMate } from "solmate/utils/FixedPointMathLib.sol";

import { RewardStorage } from "contracts/storages/RewardStorage.sol";
import { BASIS_POINT, RewardTemplateBase } from "./bases/RewardTemplateBase.sol";

import "forge-std/Test.sol";

contract ExponentialRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay period to be `n`, total reward to be `T`, then
     * `(x / k ^ 0) + (x / k ^ 1) + ... + (x / k ^ (n - 1)) = T`
     * `x = T  * (k ^ n - k ^ (n - 1)) / (k ^ n - 1)`
     */
    function getRoundReward(bytes32 daoId, uint256 round) public view virtual override returns (uint256 rewardAmount) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        uint256 rewardCheckpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, round);
        RewardStorage.RewardCheckpoint storage rewardCheckpoint = rewardInfo.rewardCheckpoints[rewardCheckpointIndex];
        if (!rewardCheckpoint.isProgressiveJackpot) {
            uint256 totalPeriod = MathLady.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.rewardDecayLife);
            // TODO: use basis point or WAD for precision?
            // kn is 18 decimal for now
            console2.log("here");
            uint256 kn = MathMate.rpow(
                rewardCheckpoint.rewardDecayFactor * MathMate.WAD / BASIS_POINT, totalPeriod, MathMate.WAD
            );
            console2.log("kn: %s", kn);
            // 18 decimal is eliminated here
            uint256 beginPeriodReward = rewardCheckpoint.totalReward
                * (kn - kn * BASIS_POINT / rewardCheckpoint.rewardDecayFactor) / (kn - MathMate.WAD);
            console2.log("beginPeriodReward: %s", beginPeriodReward);
            console2.log("round: %s", round);
            console2.log("_getBelowRoundCount: %s", _getBelowRoundCount(rewardCheckpoint.activeRounds, round));
            rewardAmount = (
                beginPeriodReward * MathMate.WAD
                    / MathMate.rpow(
                        rewardCheckpoint.rewardDecayFactor * MathMate.WAD / BASIS_POINT,
                        _getBelowRoundCount(rewardCheckpoint.activeRounds, round) / rewardCheckpoint.rewardDecayLife,
                        MathMate.WAD
                    )
            ) / rewardCheckpoint.rewardDecayLife;
            console2.log("rewardAmount: %s", rewardAmount);
        } else {
            uint256 lastActiveRound = _getLastActiveRound(rewardInfo, round);

            uint256 rewardCheckpointIndexOfLastActiveRound =
                _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, lastActiveRound);
            {
                // calculate first checkpoint's reward amount
                RewardStorage.RewardCheckpoint storage lastActiveRoundRewardCheckpoint =
                    rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound];
                if (lastActiveRound > lastActiveRoundRewardCheckpoint.startRound - 1) {
                    // TODO: precision issue when calculating `beginClaimableReward` first?
                    // kn is 18 decimal for now
                    uint256 kn = MathMate.rpow(
                        lastActiveRoundRewardCheckpoint.rewardDecayFactor * MathMate.WAD / BASIS_POINT,
                        MathLady.divUp(
                            lastActiveRoundRewardCheckpoint.totalRound, lastActiveRoundRewardCheckpoint.rewardDecayLife
                        ),
                        MathMate.WAD
                    );
                    // reward amount of the first period at last active round's checkpoint
                    uint256 beginPeriodReward = lastActiveRoundRewardCheckpoint.totalReward
                        * (kn - kn * BASIS_POINT / lastActiveRoundRewardCheckpoint.rewardDecayFactor) / (kn - MathMate.WAD);

                    // period index of last active round at last active round's checkpoint
                    // index start at 0, so `periodIndex` also indicate the number of periods before last active round
                    // denote period number to be `n`, begin claimable reward to be `x`, then
                    // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
                    kn = MathMate.rpow(
                        lastActiveRoundRewardCheckpoint.rewardDecayFactor * MathMate.WAD / BASIS_POINT,
                        (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                            / lastActiveRoundRewardCheckpoint.rewardDecayLife,
                        MathMate.WAD
                    );
                    rewardAmount = lastActiveRoundRewardCheckpoint.totalReward
                        - (
                            beginPeriodReward * (kn - MathMate.WAD)
                                / (kn - kn * BASIS_POINT / lastActiveRoundRewardCheckpoint.rewardDecayFactor)
                        );
                    // trim reward at last active round's period
                    rewardAmount -= (
                        (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                            % lastActiveRoundRewardCheckpoint.rewardDecayLife
                    ) * beginPeriodReward * MathMate.WAD / kn / lastActiveRoundRewardCheckpoint.rewardDecayLife;
                }
            }
            // use `rewardCheckpointIndexOfLastActiveRound` to iterate all reward checkpoints but the fist one and the
            // last one, here use `rewardCheckpointIndexOfLastActiveRound + 2 < rewardCheckpointIndex` instead of
            // `rewardCheckpointIndexOfLastActiveRound + 1 < rewardCheckpointIndex - 1` to avoid underflow
            for (; rewardCheckpointIndexOfLastActiveRound + 2 < rewardCheckpointIndex;) {
                rewardAmount += rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound + 1].totalReward;
                unchecked {
                    ++rewardCheckpointIndexOfLastActiveRound;
                }
            }
            {
                // calculate last checkpoint's reward amount
                // TODO: precision issue when calculating `beginClaimableReward` first?
                // kn is 18 decimal for now
                uint256 kn = MathMate.rpow(
                    rewardCheckpoint.rewardDecayFactor * MathMate.WAD / BASIS_POINT,
                    MathLady.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.rewardDecayLife),
                    MathMate.WAD
                );
                // 18 decimal is eliminated here
                uint256 beginPeriodReward = rewardCheckpoint.totalReward
                    * (kn - kn * BASIS_POINT / rewardCheckpoint.rewardDecayFactor) / (kn - MathMate.WAD);
                // denote period number to be `n`, begin claimable reward to be `x`, then
                // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
                kn = MathMate.rpow(
                    rewardCheckpoint.rewardDecayFactor * MathMate.WAD / BASIS_POINT,
                    (round - rewardCheckpoint.startRound) / rewardCheckpoint.rewardDecayLife,
                    MathMate.WAD
                );
                rewardAmount += (
                    beginPeriodReward * (kn - MathMate.WAD)
                        / (kn - kn * BASIS_POINT / rewardCheckpoint.rewardDecayFactor)
                );
                // add reward at current round's period
                rewardAmount += ((round - rewardCheckpoint.startRound + 1) % rewardCheckpoint.rewardDecayLife)
                    * beginPeriodReward * MathMate.WAD / kn / rewardCheckpoint.rewardDecayLife;
            }
        }
        // uint256 totalPeriod = MathLady.divUp(param.totalRound, param.rewardDecayLife);
        // // TODO: use basis point or WAD for precision?
        // uint256 kn = MathMate.rpow(param.rewardDecayFactor * MathMate.WAD / BASIS_POINT, totalPeriod, MathMate.WAD);
        // uint256 beginPeriodReward =
        //     param.totalReward * (kn - kn * BASIS_POINT / param.rewardDecayFactor) / (kn - MathMate.WAD);

        // if (param.isProgressiveJackpot) {
        //     uint256 periodOfLastActiveRound = (param.lastActiveRound - param.startRound) / param.rewardDecayLife;
        //     uint256 periodOfRound = (param.round - param.startRound) / param.rewardDecayLife;
        //     uint256 claimablePeriod = periodOfRound - periodOfLastActiveRound + 1;
        //     // TODO: precision issue when calculating `beginClaimableReward` first?
        //     uint256 beginClaimableReward = beginPeriodReward * MathMate.WAD
        //         / MathMate.rpow(param.rewardDecayFactor * MathMate.WAD / BASIS_POINT, periodOfLastActiveRound,
        // MathMate.WAD);
        //     // denote claimable period to be `n`, begin claimable reward to be `x`, then
        //     // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
        //     kn = MathMate.rpow(param.rewardDecayFactor * MathMate.WAD / BASIS_POINT, claimablePeriod, MathMate.WAD);
        //     rewardAmount = beginClaimableReward * (kn - MathMate.WAD) / (kn - kn * BASIS_POINT /
        // param.rewardDecayFactor);
        //     // trim reward at last active round's period and current round's period
        //     rewardAmount -=
        //         ((param.lastActiveRound - param.startRound) % param.rewardDecayLife) * beginClaimableReward /
        // param.rewardDecayLife;
        //     rewardAmount -= (param.rewardDecayLife - 1 - ((param.round - param.startRound) % param.rewardDecayLife))
        //         * (
        //             beginPeriodReward
        //                 / MathMate.rpow(param.rewardDecayFactor * MathMate.WAD / BASIS_POINT, periodOfRound,
        // MathMate.WAD)
        //         ) / param.rewardDecayLife;
        // } else {
        //     rewardAmount =
        //         (beginPeriodReward - param.activeRoundsLength / param.rewardDecayLife * param.rewardDecayFactor) /
        // param.rewardDecayLife;
        // }
    }
}
