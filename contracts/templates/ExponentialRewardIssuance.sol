// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as MathLady } from "solady/utils/FixedPointMathLib.sol";
import { FixedPointMathLib as MathMate } from "solmate/utils/FixedPointMathLib.sol";

import { BASIS_POINT, RewardTemplateBase } from "./bases/RewardTemplateBase.sol";

contract ExponentialRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay period to be `n`, total reward to be `T`, then
     * `(x / k ^ 0) + (x / k ^ 1) + ... + (x - k ^ (n - 1)) = T`
     * `x = T  * (k ^ n - k ^ (n - 1)) / (k ^ n - 1)`
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
        uint256 decayPeriod = MathLady.divUp(totalRound, decayLife);
        // TODO: use basis point or WAD for precision?
        uint256 kn = MathMate.rpow(decayFactor * MathMate.WAD / BASIS_POINT, decayPeriod, MathMate.WAD);
        uint256 beginPeriodReward = totalReward * (kn - kn * BASIS_POINT / decayFactor) / (kn - MathMate.WAD);

        uint256 length = activeRounds.length;
        uint256 lastActiveRound = length == 0 ? startRound : activeRounds[length - 1];
        if (isProgressiveJackpot) {
            uint256 periodOfLastActiveRound = (lastActiveRound - startRound) / decayLife;
            uint256 periodOfRound = (round - startRound) / decayLife;
            uint256 claimablePeriod = periodOfRound - periodOfLastActiveRound + 1;
            // TODO: precision issue when calculating `beginClaimableReward` first?
            uint256 beginClaimableReward = beginPeriodReward * MathMate.WAD
                / MathMate.rpow(decayFactor * MathMate.WAD / BASIS_POINT, periodOfLastActiveRound, MathMate.WAD);
            // denote claimable period to be `n`, begin claimable reward to be `x`, then
            // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
            kn = MathMate.rpow(decayFactor * MathMate.WAD / BASIS_POINT, claimablePeriod, MathMate.WAD);
            rewardAmount = beginClaimableReward * (kn - MathMate.WAD) / (kn - kn * BASIS_POINT / decayFactor);
            // trim reward at last active round's period and current round's period
            rewardAmount -= ((lastActiveRound - startRound) % decayLife) * beginClaimableReward / decayLife;
            rewardAmount -= (decayLife - 1 - ((round - startRound) % decayLife))
                * (beginPeriodReward / MathMate.rpow(decayFactor * MathMate.WAD / BASIS_POINT, periodOfRound, MathMate.WAD))
                / decayLife;
        } else {
            rewardAmount = (beginPeriodReward - length / decayLife * decayFactor) / decayLife;
        }
    }
}
