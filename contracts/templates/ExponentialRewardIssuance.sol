// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as MathLady } from "solady/utils/FixedPointMathLib.sol";
import { FixedPointMathLib as MathMate } from "solmate/utils/FixedPointMathLib.sol";

import { RewardStorage } from "contracts/storages/RewardStorage.sol";
import { BASIS_POINT, RewardTemplateBase } from "./bases/RewardTemplateBase.sol";

contract ExponentialRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay period to be `n`, total reward to be `T`, then
     * `(x / k ^ 0) + (x / k ^ 1) + ... + (x - k ^ (n - 1)) = T`
     * `x = T  * (k ^ n - k ^ (n - 1)) / (k ^ n - 1)`
     */
    function getRoundReward(
        bytes32 daoId,
        uint256 round,
        uint256 lastActiveRound
    )
        public
        view
        virtual
        override
        returns (uint256 rewardAmount)
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        uint256 rewardCheckpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, round);
        RewardStorage.RewardCheckpoint memory rewardCheckpoint = rewardInfo.rewardCheckpoints[rewardCheckpointIndex];
        uint256[] memory activeRoundsOfCheckpoint = getActiveRoundsOfCheckpoint(
            rewardInfo.activeRounds,
            rewardCheckpoint.startRound,
            rewardCheckpointIndex == rewardInfo.rewardCheckpoints.length - 1
                ? round
                : rewardInfo.rewardCheckpoints[rewardCheckpointIndex + 1].startRound - 1
        );
        if (!rewardCheckpoint.isProgressiveJackpot) {
            uint256 totalPeriod = MathLady.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.decayLife);
            // TODO: use basis point or WAD for precision?
            // kn is 18 decimal for now
            uint256 kn =
                MathMate.rpow(rewardCheckpoint.decayFactor * MathMate.WAD / BASIS_POINT, totalPeriod, MathMate.WAD);
            // 18 decimal is eliminated here
            uint256 beginPeriodReward = rewardCheckpoint.totalReward
                * (kn - kn * BASIS_POINT / rewardCheckpoint.decayFactor) / (kn - MathMate.WAD);
            rewardAmount = (
                beginPeriodReward
                    - getRoundIndex(activeRoundsOfCheckpoint, round) / rewardCheckpoint.decayLife
                        * rewardCheckpoint.decayFactor
            ) / rewardCheckpoint.decayLife;
        } else {
            uint256 rewardCheckpointIndexOfLastActiveRound =
                _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, lastActiveRound);
            {
                // calculate first checkpoint's reward amount
                RewardStorage.RewardCheckpoint memory lastActiveRoundRewardCheckpoint =
                    rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound];
                // TODO: precision issue when calculating `beginClaimableReward` first?
                // kn is 18 decimal for now
                uint256 kn = MathMate.rpow(
                    lastActiveRoundRewardCheckpoint.decayFactor * MathMate.WAD / BASIS_POINT,
                    MathLady.divUp(
                        lastActiveRoundRewardCheckpoint.totalRound, lastActiveRoundRewardCheckpoint.decayLife
                    ),
                    MathMate.WAD
                );
                // reward amount of the first period at last active round's checkpoint
                uint256 beginPeriodReward = lastActiveRoundRewardCheckpoint.totalReward
                    * (kn - kn * BASIS_POINT / lastActiveRoundRewardCheckpoint.decayFactor) / (kn - MathMate.WAD);

                // period index of last active round at last active round's checkpoint
                // index start at 0, so `periodIndex` also indicate the number of periods before last active round
                // denote period number to be `n`, begin claimable reward to be `x`, then
                // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
                kn = MathMate.rpow(
                    lastActiveRoundRewardCheckpoint.decayFactor * MathMate.WAD / BASIS_POINT,
                    (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                        / lastActiveRoundRewardCheckpoint.decayLife,
                    MathMate.WAD
                );
                rewardAmount = lastActiveRoundRewardCheckpoint.totalReward
                    - (
                        beginPeriodReward * (kn - MathMate.WAD)
                            / (kn - kn * BASIS_POINT / lastActiveRoundRewardCheckpoint.decayFactor)
                    );
                // trim reward at last active round's period
                rewardAmount -= (
                    (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                        % lastActiveRoundRewardCheckpoint.decayLife
                ) * beginPeriodReward * MathMate.WAD / kn / lastActiveRoundRewardCheckpoint.decayLife;
            }
            // use `rewardCheckpointIndexOfLastActiveRound` to iterate all reward checkpoints but the fist one and the
            // last one
            for (; rewardCheckpointIndexOfLastActiveRound + 1 < rewardCheckpointIndex - 1;) {
                rewardAmount += rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound].totalReward;
                unchecked {
                    ++rewardCheckpointIndexOfLastActiveRound;
                }
            }
            {
                // calculate last checkpoint's reward amount
                // TODO: precision issue when calculating `beginClaimableReward` first?
                // kn is 18 decimal for now
                uint256 kn = MathMate.rpow(
                    rewardCheckpoint.decayFactor * MathMate.WAD / BASIS_POINT,
                    MathLady.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.decayLife),
                    MathMate.WAD
                );
                // 18 decimal is eliminated here
                uint256 beginPeriodReward = rewardCheckpoint.totalReward
                    * (kn - kn * BASIS_POINT / rewardCheckpoint.decayFactor) / (kn - MathMate.WAD);
                // denote period number to be `n`, begin claimable reward to be `x`, then
                // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
                kn = MathMate.rpow(
                    rewardCheckpoint.decayFactor * MathMate.WAD / BASIS_POINT,
                    (round - rewardCheckpoint.startRound) / rewardCheckpoint.decayLife,
                    MathMate.WAD
                );
                rewardAmount +=
                    (beginPeriodReward * (kn - MathMate.WAD) / (kn - kn * BASIS_POINT / rewardCheckpoint.decayFactor));
                // add reward at current round's period
                rewardAmount += ((round - rewardCheckpoint.startRound) % rewardCheckpoint.decayLife) * beginPeriodReward
                    * MathMate.WAD / kn / rewardCheckpoint.decayLife;
            }
        }
        // uint256 totalPeriod = MathLady.divUp(param.totalRound, param.decayLife);
        // // TODO: use basis point or WAD for precision?
        // uint256 kn = MathMate.rpow(param.decayFactor * MathMate.WAD / BASIS_POINT, totalPeriod, MathMate.WAD);
        // uint256 beginPeriodReward =
        //     param.totalReward * (kn - kn * BASIS_POINT / param.decayFactor) / (kn - MathMate.WAD);

        // if (param.isProgressiveJackpot) {
        //     uint256 periodOfLastActiveRound = (param.lastActiveRound - param.startRound) / param.decayLife;
        //     uint256 periodOfRound = (param.round - param.startRound) / param.decayLife;
        //     uint256 claimablePeriod = periodOfRound - periodOfLastActiveRound + 1;
        //     // TODO: precision issue when calculating `beginClaimableReward` first?
        //     uint256 beginClaimableReward = beginPeriodReward * MathMate.WAD
        //         / MathMate.rpow(param.decayFactor * MathMate.WAD / BASIS_POINT, periodOfLastActiveRound,
        // MathMate.WAD);
        //     // denote claimable period to be `n`, begin claimable reward to be `x`, then
        //     // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
        //     kn = MathMate.rpow(param.decayFactor * MathMate.WAD / BASIS_POINT, claimablePeriod, MathMate.WAD);
        //     rewardAmount = beginClaimableReward * (kn - MathMate.WAD) / (kn - kn * BASIS_POINT / param.decayFactor);
        //     // trim reward at last active round's period and current round's period
        //     rewardAmount -=
        //         ((param.lastActiveRound - param.startRound) % param.decayLife) * beginClaimableReward /
        // param.decayLife;
        //     rewardAmount -= (param.decayLife - 1 - ((param.round - param.startRound) % param.decayLife))
        //         * (
        //             beginPeriodReward
        //                 / MathMate.rpow(param.decayFactor * MathMate.WAD / BASIS_POINT, periodOfRound, MathMate.WAD)
        //         ) / param.decayLife;
        // } else {
        //     rewardAmount =
        //         (beginPeriodReward - param.activeRoundsLength / param.decayLife * param.decayFactor) /
        // param.decayLife;
        // }
    }
}
