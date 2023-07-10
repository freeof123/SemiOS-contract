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
     * `(x / k ^ 0) + (x / k ^ 1) + ... + (x / k ^ (n - 1)) = T`
     * `x = T  * （1 - 1/k) / (1 - 1/k ^ n)`
     */
    function getRoundReward(bytes32 daoId, uint256 round) public view virtual override returns (uint256 rewardAmount) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        uint256 rewardCheckpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, round);
        RewardStorage.RewardCheckpoint storage rewardCheckpoint = rewardInfo.rewardCheckpoints[rewardCheckpointIndex];
        if (!rewardCheckpoint.isProgressiveJackpot) {
            uint256 totalPeriod = MathLady.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.rewardDecayLife);
            // TODO: use basis point or WAD for precision?
            // kn is 18 decimal for now
            if (rewardCheckpoint.rewardDecayFactor < BASIS_POINT) {
                uint256 kn = MathMate.rpow(rewardCheckpoint.rewardDecayFactor * 1e27 / BASIS_POINT, totalPeriod, 1e27);
                // 18 decimal is eliminated here
                uint256 endPeriodReward = rewardCheckpoint.totalReward
                    * (1e27 - 1e27 * rewardCheckpoint.rewardDecayFactor / BASIS_POINT) / (1e27 - kn);
                uint256 temp = totalPeriod
                    - MathLady.divUp(
                        _getBelowRoundCount(rewardCheckpoint.activeRounds, round), rewardCheckpoint.rewardDecayLife
                    );
                rewardAmount = (
                    endPeriodReward
                        * MathMate.rpow(
                            rewardCheckpoint.rewardDecayFactor * 1e27 / BASIS_POINT, temp == 0 ? 0 : temp - 1, 1e27
                        ) / 1e27
                ) / rewardCheckpoint.rewardDecayLife;
            } else {
                uint256 oneOverKn =
                    MathMate.rpow(1e27 * BASIS_POINT / rewardCheckpoint.rewardDecayFactor, totalPeriod, 1e27);
                // 18 decimal is eliminated here
                uint256 beginPeriodReward = rewardCheckpoint.totalReward
                    * (1e27 - 1e27 * BASIS_POINT / rewardCheckpoint.rewardDecayFactor) / (1e27 - oneOverKn);
                rewardAmount = (
                    beginPeriodReward
                        * MathMate.rpow(
                            1e27 * BASIS_POINT / rewardCheckpoint.rewardDecayFactor,
                            _getBelowRoundCount(rewardCheckpoint.activeRounds, round) / rewardCheckpoint.rewardDecayLife,
                            1e27
                        ) / 1e27
                ) / rewardCheckpoint.rewardDecayLife;
            }
        } else {
            uint256 lastActiveRound = _getLastActiveRound(rewardInfo, round);
            uint256 rewardCheckpointIndexOfLastActiveRound =
                _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, lastActiveRound);
            {
                // calculate first checkpoint's reward amount
                RewardStorage.RewardCheckpoint storage lastActiveRoundRewardCheckpoint =
                    rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound];
                if (lastActiveRound > lastActiveRoundRewardCheckpoint.startRound - 1) {
                    if (lastActiveRoundRewardCheckpoint.rewardDecayFactor < BASIS_POINT) {
                        // TODO: precision issue when calculating `beginClaimableReward` first?
                        // kn is 18 decimal for now
                        uint256 kn = MathMate.rpow(
                            lastActiveRoundRewardCheckpoint.rewardDecayFactor * 1e27 / BASIS_POINT,
                            MathLady.divUp(
                                lastActiveRoundRewardCheckpoint.totalRound,
                                lastActiveRoundRewardCheckpoint.rewardDecayLife
                            ),
                            1e27
                        );
                        // reward amount of the first period at last active round's checkpoint
                        uint256 beginPeriodReward = lastActiveRoundRewardCheckpoint.totalReward
                            * (kn - kn * BASIS_POINT / lastActiveRoundRewardCheckpoint.rewardDecayFactor) / (kn - 1e27);

                        // period index of last active round at last active round's checkpoint
                        // index start at 0, so `periodIndex` also indicate the number of periods before last active
                        // round
                        // denote period number to be `n`, begin claimable reward to be `x`, then
                        // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
                        kn = MathMate.rpow(
                            lastActiveRoundRewardCheckpoint.rewardDecayFactor * 1e27 / BASIS_POINT,
                            (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                                / lastActiveRoundRewardCheckpoint.rewardDecayLife,
                            1e27
                        );
                        rewardAmount = lastActiveRoundRewardCheckpoint.totalReward
                            - (
                                beginPeriodReward * (kn - 1e27)
                                    / (kn - kn * BASIS_POINT / lastActiveRoundRewardCheckpoint.rewardDecayFactor)
                            );
                        // trim reward at last active round's period
                        rewardAmount -= (
                            (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                                % lastActiveRoundRewardCheckpoint.rewardDecayLife
                        ) * beginPeriodReward * 1e27 / kn / lastActiveRoundRewardCheckpoint.rewardDecayLife;
                    } else {
                        // TODO: precision issue when calculating `beginClaimableReward` first?
                        // oneOverKn is 18 decimal for now
                        uint256 oneOverKn = MathMate.rpow(
                            1e27 * BASIS_POINT / lastActiveRoundRewardCheckpoint.rewardDecayFactor,
                            MathLady.divUp(
                                lastActiveRoundRewardCheckpoint.totalRound,
                                lastActiveRoundRewardCheckpoint.rewardDecayLife
                            ),
                            1e27
                        );
                        // reward amount of the first period at last active round's checkpoint
                        uint256 beginPeriodReward = lastActiveRoundRewardCheckpoint.totalReward
                            * (1e27 - 1e27 * BASIS_POINT / lastActiveRoundRewardCheckpoint.rewardDecayFactor)
                            / (1e27 - oneOverKn);
                        // period index of last active round at last active round's checkpoint
                        // index start at 0, so `periodIndex` also indicate the number of periods before last active
                        // round
                        // denote period number to be `n`, begin claimable reward to be `x`, then
                        // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
                        oneOverKn = MathMate.rpow(
                            1e27 * BASIS_POINT / lastActiveRoundRewardCheckpoint.rewardDecayFactor,
                            (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                                / lastActiveRoundRewardCheckpoint.rewardDecayLife,
                            1e27
                        );
                        rewardAmount = lastActiveRoundRewardCheckpoint.totalReward
                            - (
                                beginPeriodReward
                                    * (1e27 - 1e27 * BASIS_POINT / lastActiveRoundRewardCheckpoint.rewardDecayFactor)
                                    / (1e27 - oneOverKn)
                            );
                        // trim reward at last active round's period
                        rewardAmount -= (
                            (lastActiveRound - lastActiveRoundRewardCheckpoint.startRound)
                                % lastActiveRoundRewardCheckpoint.rewardDecayLife
                        ) * beginPeriodReward * oneOverKn / 1e27 / lastActiveRoundRewardCheckpoint.rewardDecayLife;
                    }
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
                    rewardCheckpoint.rewardDecayFactor * 1e27 / BASIS_POINT,
                    MathLady.divUp(rewardCheckpoint.totalRound, rewardCheckpoint.rewardDecayLife),
                    1e27
                );
                // 18 decimal is eliminated here
                uint256 beginPeriodReward = rewardCheckpoint.totalReward
                    * (kn - kn * BASIS_POINT / rewardCheckpoint.rewardDecayFactor) / (kn - 1e27);
                // denote period number to be `n`, begin claimable reward to be `x`, then
                // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
                kn = MathMate.rpow(
                    rewardCheckpoint.rewardDecayFactor * 1e27 / BASIS_POINT,
                    (round - rewardCheckpoint.startRound) / rewardCheckpoint.rewardDecayLife,
                    1e27
                );
                rewardAmount +=
                    (beginPeriodReward * (kn - 1e27) / (kn - kn * BASIS_POINT / rewardCheckpoint.rewardDecayFactor));
                // add reward at current round's period
                rewardAmount += ((round - rewardCheckpoint.startRound + 1) % rewardCheckpoint.rewardDecayLife)
                    * beginPeriodReward * 1e27 / kn / rewardCheckpoint.rewardDecayLife;
            }
        }
        // uint256 totalPeriod = MathLady.divUp(param.totalRound, param.rewardDecayLife);
        // // TODO: use basis point or WAD for precision?
        // uint256 kn = MathMate.rpow(param.rewardDecayFactor * 1e27 / BASIS_POINT, totalPeriod, 1e27);
        // uint256 beginPeriodReward =
        //     param.totalReward * (kn - kn * BASIS_POINT / param.rewardDecayFactor) / (kn - 1e27);

        // if (param.isProgressiveJackpot) {
        //     uint256 periodOfLastActiveRound = (param.lastActiveRound - param.startRound) / param.rewardDecayLife;
        //     uint256 periodOfRound = (param.round - param.startRound) / param.rewardDecayLife;
        //     uint256 claimablePeriod = periodOfRound - periodOfLastActiveRound + 1;
        //     // TODO: precision issue when calculating `beginClaimableReward` first?
        //     uint256 beginClaimableReward = beginPeriodReward * 1e27
        //         / MathMate.rpow(param.rewardDecayFactor * 1e27 / BASIS_POINT, periodOfLastActiveRound,
        // 1e27);
        //     // denote claimable period to be `n`, begin claimable reward to be `x`, then
        //     // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
        //     kn = MathMate.rpow(param.rewardDecayFactor * 1e27 / BASIS_POINT, claimablePeriod, 1e27);
        //     rewardAmount = beginClaimableReward * (kn - 1e27) / (kn - kn * BASIS_POINT /
        // param.rewardDecayFactor);
        //     // trim reward at last active round's period and current round's period
        //     rewardAmount -=
        //         ((param.lastActiveRound - param.startRound) % param.rewardDecayLife) * beginClaimableReward /
        // param.rewardDecayLife;
        //     rewardAmount -= (param.rewardDecayLife - 1 - ((param.round - param.startRound) % param.rewardDecayLife))
        //         * (
        //             beginPeriodReward
        //                 / MathMate.rpow(param.rewardDecayFactor * 1e27 / BASIS_POINT, periodOfRound,
        // 1e27)
        //         ) / param.rewardDecayLife;
        // } else {
        //     rewardAmount =
        //         (beginPeriodReward - param.activeRoundsLength / param.rewardDecayLife * param.rewardDecayFactor) /
        // param.rewardDecayLife;
        // }
    }
}
