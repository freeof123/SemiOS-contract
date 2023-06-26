// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as MathLady } from "solady/utils/FixedPointMathLib.sol";
import { FixedPointMathLib as MathMate } from "solmate/utils/FixedPointMathLib.sol";

import { GetRoundRewardParam } from "contracts/interface/D4AStructs.sol";
import { BASIS_POINT, RewardTemplateBase } from "./bases/RewardTemplateBase.sol";

contract ExponentialRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay period to be `n`, total reward to be `T`, then
     * `(x / k ^ 0) + (x / k ^ 1) + ... + (x - k ^ (n - 1)) = T`
     * `x = T  * (k ^ n - k ^ (n - 1)) / (k ^ n - 1)`
     */
    function getRoundReward(GetRoundRewardParam memory param)
        public
        pure
        virtual
        override
        returns (uint256 rewardAmount)
    {
        uint256 decayPeriod = MathLady.divUp(param.totalRound, param.decayLife);
        // TODO: use basis point or WAD for precision?
        uint256 kn = MathMate.rpow(param.decayFactor * MathMate.WAD / BASIS_POINT, decayPeriod, MathMate.WAD);
        uint256 beginPeriodReward =
            param.totalReward * (kn - kn * BASIS_POINT / param.decayFactor) / (kn - MathMate.WAD);

        uint256 length = param.activeRounds.length;
        uint256 lastActiveRound = length == 0 ? param.startRound : param.activeRounds[length - 1];
        if (param.isProgressiveJackpot) {
            uint256 periodOfLastActiveRound = (lastActiveRound - param.startRound) / param.decayLife;
            uint256 periodOfRound = (param.round - param.startRound) / param.decayLife;
            uint256 claimablePeriod = periodOfRound - periodOfLastActiveRound + 1;
            // TODO: precision issue when calculating `beginClaimableReward` first?
            uint256 beginClaimableReward = beginPeriodReward * MathMate.WAD
                / MathMate.rpow(param.decayFactor * MathMate.WAD / BASIS_POINT, periodOfLastActiveRound, MathMate.WAD);
            // denote claimable period to be `n`, begin claimable reward to be `x`, then
            // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
            kn = MathMate.rpow(param.decayFactor * MathMate.WAD / BASIS_POINT, claimablePeriod, MathMate.WAD);
            rewardAmount = beginClaimableReward * (kn - MathMate.WAD) / (kn - kn * BASIS_POINT / param.decayFactor);
            // trim reward at last active round's period and current round's period
            rewardAmount -=
                ((lastActiveRound - param.startRound) % param.decayLife) * beginClaimableReward / param.decayLife;
            rewardAmount -= (param.decayLife - 1 - ((param.round - param.startRound) % param.decayLife))
                * (
                    beginPeriodReward
                        / MathMate.rpow(param.decayFactor * MathMate.WAD / BASIS_POINT, periodOfRound, MathMate.WAD)
                ) / param.decayLife;
        } else {
            rewardAmount = (beginPeriodReward - length / param.decayLife * param.decayFactor) / param.decayLife;
        }
    }
}
