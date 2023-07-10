// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as Math } from "solady/utils/FixedPointMathLib.sol";

import { BASIS_POINT, RewardTemplateBase } from "./bases/RewardTemplateBase.sol";

import { RewardStorage } from "contracts/storages/RewardStorage.sol";

contract LinearRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay period to be `n`, total reward to be `T`, then
     * `(x - 0 * k) + (x - 1 * k) + ... + (x - (n - 1) * k) = T`
     * `x = T / n + (n - 1) * k / 2`
     */
    function getRoundReward(bytes32 daoId, uint256 round) public view virtual override returns (uint256 rewardAmount) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        uint256 rewardCheckpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, round);
        RewardStorage.RewardCheckpoint storage rewardCheckpoint = rewardInfo.rewardCheckpoints[rewardCheckpointIndex];
        if (!rewardCheckpoint.isProgressiveJackpot) {
            uint256 totalPeriod = Math.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.rewardDecayLife);
            uint256 beginPeriodReward =
                rewardCheckpoint.totalReward / totalPeriod + (totalPeriod - 1) * rewardCheckpoint.rewardDecayFactor / 2;
            rewardAmount = (
                beginPeriodReward
                    - _getBelowRoundCount(rewardCheckpoint.activeRounds, round) / rewardCheckpoint.rewardDecayLife
                        * rewardCheckpoint.rewardDecayFactor
            ) / rewardCheckpoint.rewardDecayLife;
        } else {
            uint256 lastActiveRound = _getLastActiveRound(rewardInfo, round);

            uint256 rewardCheckpointIndexOfLastActiveRound =
                _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, lastActiveRound);
            {
                // calculate first checkpoint's reward amount
                RewardStorage.RewardCheckpoint storage lastActiveRoundRewardCheckpoint =
                    rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound];
                // period index of last active round at last active round's checkpoint
                // index start at 0, so `periodIndex` also indicate the number of periods before last active round
                uint256 periodIndex = (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                    / lastActiveRoundRewardCheckpoint.rewardDecayLife;
                // total period number of last active rounds at last active round's checkpoint
                uint256 totalPeriod = Math.divUp(
                    lastActiveRoundRewardCheckpoint.totalRound, lastActiveRoundRewardCheckpoint.rewardDecayLife
                );
                // reward amount of the first period at last active round's checkpoint
                uint256 beginPeriodReward = lastActiveRoundRewardCheckpoint.totalReward / totalPeriod
                    + (totalPeriod - 1) * lastActiveRoundRewardCheckpoint.rewardDecayFactor / 2;
                // reward amount start with total reward of last active round's checkpoint
                rewardAmount = lastActiveRoundRewardCheckpoint.totalReward;
                // minus reward amount before the period index of last active round at last active round's checkpoint
                if (periodIndex > 0) {
                    // prevent underflow
                    rewardAmount -= (
                        periodIndex * beginPeriodReward
                            - periodIndex * (periodIndex - 1) * lastActiveRoundRewardCheckpoint.rewardDecayFactor / 2
                    );
                }
                // trim reward at last active round's period
                rewardAmount -= (
                    (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                        % lastActiveRoundRewardCheckpoint.rewardDecayLife
                ) * (beginPeriodReward - periodIndex * rewardCheckpoint.rewardDecayFactor)
                    / lastActiveRoundRewardCheckpoint.rewardDecayLife;
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
                uint256 periodIndex = (round - rewardCheckpoint.startRound) / rewardCheckpoint.rewardDecayLife;
                uint256 totalPeriod = Math.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.rewardDecayLife);
                uint256 beginPeriodReward = rewardCheckpoint.totalReward / totalPeriod
                    + (totalPeriod - 1) * rewardCheckpoint.rewardDecayFactor / 2;
                rewardAmount += (
                    periodIndex * beginPeriodReward
                        - periodIndex * (periodIndex - 1) * rewardCheckpoint.rewardDecayFactor / 2
                );
                // add reward at current round's period
                rewardAmount += ((round - rewardCheckpoint.startRound) % rewardCheckpoint.rewardDecayLife)
                    * (beginPeriodReward - periodIndex * rewardCheckpoint.rewardDecayFactor)
                    / rewardCheckpoint.rewardDecayLife;
            }
        }
        // uint256 totalPeriod = Math.divUp(totalRound, rewardDecayLife);
        // uint256 beginPeriodReward = totalReward / totalPeriod + (totalPeriod - 1) * rewardDecayFactor / 2;

        // if (isProgressiveJackpot) {
        //     uint256 periodOfLastActiveRound = (lastActiveRound - startRound) / rewardDecayLife;
        //     uint256 periodIndex = (round - startRound) / rewardDecayLife;
        //     uint256 claimablePeriod = periodIndex - periodOfLastActiveRound + 1;
        //     uint256 beginClaimableReward = beginPeriodReward - periodOfLastActiveRound * rewardDecayFactor;
        //     rewardAmount =
        //         claimablePeriod * beginClaimableReward - claimablePeriod * (claimablePeriod - 1) * rewardDecayFactor
        // / 2;
        //     // trim reward at last active round's period and current round's period
        //     rewardAmount -= ((lastActiveRound - startRound) % rewardDecayLife) * beginClaimableReward /
        // rewardDecayLife;
        //     rewardAmount -= (rewardDecayLife - 1 - ((round - startRound) % rewardDecayLife))
        //         * (beginPeriodReward - periodIndex * rewardDecayFactor) / rewardDecayLife;
        // } else {
        //     rewardAmount = (beginPeriodReward - activeRoundsLength / rewardDecayLife * rewardDecayFactor) /
        // rewardDecayLife;
        // }
    }
}
