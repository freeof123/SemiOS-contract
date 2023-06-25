// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as Math } from "solady/utils/FixedPointMathLib.sol";

import { BASIS_POINT, RewardTemplateBase } from "./bases/RewardTemplateBase.sol";

contract LinearRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay period to be `n`, total reward to be `T`, then
     * `(x - 0 * k) + (x - 1 * k) + ... + (x - (n - 1) * k) = T`
     * `x = T / n + (n - 1) * k / 2`
     */
    function getRoundReward(
        uint256 totalReward,
        uint256 startRound,
        uint256 round,
        uint256[] memory activeRounds,
        uint256 totalRound,
        uint256 decayFactor,
        uint256 decayLife,
        bool isProgressiveJackpot
    )
        public
        pure
        virtual
        override
        returns (uint256 rewardAmount)
    {
        uint256 decayPeriod = Math.divUp(totalRound, decayLife);
        uint256 beginPeriodReward = totalReward / decayPeriod + (decayPeriod - 1) * decayFactor / 2;

        uint256 length = activeRounds.length;
        uint256 lastActiveRound = length == 0 ? startRound : activeRounds[length - 1];
        if (isProgressiveJackpot) {
            uint256 periodOfLastActiveRound = (lastActiveRound - startRound) / decayLife;
            uint256 periodOfRound = (round - startRound) / decayLife;
            uint256 claimablePeriod = periodOfRound - periodOfLastActiveRound + 1;
            uint256 beginClaimableReward = beginPeriodReward - periodOfLastActiveRound * decayFactor;
            rewardAmount =
                claimablePeriod * beginClaimableReward - claimablePeriod * (claimablePeriod - 1) * decayFactor / 2;
            // trim reward at last active round's period and current round's period
            rewardAmount -= ((lastActiveRound - startRound) % decayLife) * beginClaimableReward / decayLife;
            rewardAmount -= (decayLife - 1 - ((round - startRound) % decayLife))
                * (beginPeriodReward - periodOfRound * decayFactor) / decayLife;
        } else {
            rewardAmount = (beginPeriodReward - length / decayLife * decayFactor) / decayLife;
        }
    }
}
