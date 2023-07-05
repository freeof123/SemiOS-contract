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
            uint256 totalPeriod = Math.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.decayLife);
            uint256 beginPeriodReward =
                rewardCheckpoint.totalReward / totalPeriod + (totalPeriod - 1) * rewardCheckpoint.decayFactor / 2;
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
                // period index of last active round at last active round's checkpoint
                // index start at 0, so `periodIndex` also indicate the number of periods before last active round
                uint256 periodIndex = (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                    / lastActiveRoundRewardCheckpoint.decayLife;
                // total period number of last active rounds at last active round's checkpoint
                uint256 totalPeriod =
                    Math.divUp(lastActiveRoundRewardCheckpoint.totalRound, lastActiveRoundRewardCheckpoint.decayLife);
                // reward amount of the first period at last active round's checkpoint
                uint256 beginPeriodReward = lastActiveRoundRewardCheckpoint.totalReward / totalPeriod
                    + (totalPeriod - 1) * lastActiveRoundRewardCheckpoint.decayFactor / 2;
                // reward amount start with total reward of last active round's checkpoint
                rewardAmount = lastActiveRoundRewardCheckpoint.totalReward;
                // minus reward amount before the period index of last active round at last active round's checkpoint
                if (periodIndex > 0) {
                    // prevent underflow
                    rewardAmount -= (
                        periodIndex * beginPeriodReward
                            - periodIndex * (periodIndex - 1) * lastActiveRoundRewardCheckpoint.decayFactor / 2
                    );
                }
                // trim reward at last active round's period
                rewardAmount -= (
                    (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                        % lastActiveRoundRewardCheckpoint.decayLife
                ) * (beginPeriodReward - periodIndex * rewardCheckpoint.decayFactor)
                    / lastActiveRoundRewardCheckpoint.decayLife;
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
                uint256 periodIndex = (round - rewardCheckpoint.startRound) / rewardCheckpoint.decayLife;
                uint256 totalPeriod = Math.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.decayLife);
                uint256 beginPeriodReward =
                    rewardCheckpoint.totalReward / totalPeriod + (totalPeriod - 1) * rewardCheckpoint.decayFactor / 2;
                rewardAmount += (
                    periodIndex * beginPeriodReward - periodIndex * (periodIndex - 1) * rewardCheckpoint.decayFactor / 2
                );
                // add reward at current round's period
                rewardAmount += ((round - rewardCheckpoint.startRound) % rewardCheckpoint.decayLife)
                    * (beginPeriodReward - periodIndex * rewardCheckpoint.decayFactor) / rewardCheckpoint.decayLife;
            }
        }
        // uint256 totalPeriod = Math.divUp(totalRound, decayLife);
        // uint256 beginPeriodReward = totalReward / totalPeriod + (totalPeriod - 1) * decayFactor / 2;

        // if (isProgressiveJackpot) {
        //     uint256 periodOfLastActiveRound = (lastActiveRound - startRound) / decayLife;
        //     uint256 periodIndex = (round - startRound) / decayLife;
        //     uint256 claimablePeriod = periodIndex - periodOfLastActiveRound + 1;
        //     uint256 beginClaimableReward = beginPeriodReward - periodOfLastActiveRound * decayFactor;
        //     rewardAmount =
        //         claimablePeriod * beginClaimableReward - claimablePeriod * (claimablePeriod - 1) * decayFactor / 2;
        //     // trim reward at last active round's period and current round's period
        //     rewardAmount -= ((lastActiveRound - startRound) % decayLife) * beginClaimableReward / decayLife;
        //     rewardAmount -= (decayLife - 1 - ((round - startRound) % decayLife))
        //         * (beginPeriodReward - periodIndex * decayFactor) / decayLife;
        // } else {
        //     rewardAmount = (beginPeriodReward - activeRoundsLength / decayLife * decayFactor) / decayLife;
        // }
    }
}
