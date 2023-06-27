// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as Math } from "solady/utils/FixedPointMathLib.sol";

import { GetRoundRewardParam } from "contracts/interface/D4AStructs.sol";
import { BASIS_POINT, RewardTemplateBase } from "./bases/RewardTemplateBase.sol";

contract LinearRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay period to be `n`, total reward to be `T`, then
     * `(x - 0 * k) + (x - 1 * k) + ... + (x - (n - 1) * k) = T`
     * `x = T / n + (n - 1) * k / 2`
     */
    function getRoundReward(GetRoundRewardParam memory param)
        public
        pure
        virtual
        override
        returns (uint256 rewardAmount)
    {
        uint256 decayPeriod = Math.divUp(param.totalRound, param.decayLife);
        uint256 beginPeriodReward = param.totalReward / decayPeriod + (decayPeriod - 1) * param.decayFactor / 2;

        uint256 length = param.activeRounds.length;
        uint256 lastActiveRound = length == 0 ? param.startRound : param.activeRounds[length - 1];
        if (param.isProgressiveJackpot) {
            uint256 periodOfLastActiveRound = (lastActiveRound - param.startRound) / param.decayLife;
            uint256 periodOfRound = (param.round - param.startRound) / param.decayLife;
            uint256 claimablePeriod = periodOfRound - periodOfLastActiveRound + 1;
            uint256 beginClaimableReward = beginPeriodReward - periodOfLastActiveRound * param.decayFactor;
            rewardAmount =
                claimablePeriod * beginClaimableReward - claimablePeriod * (claimablePeriod - 1) * param.decayFactor / 2;
            // trim reward at last active round's period and current round's period
            rewardAmount -=
                ((lastActiveRound - param.startRound) % param.decayLife) * beginClaimableReward / param.decayLife;
            rewardAmount -= (param.decayLife - 1 - ((param.round - param.startRound) % param.decayLife))
                * (beginPeriodReward - periodOfRound * param.decayFactor) / param.decayLife;
        } else {
            rewardAmount = (beginPeriodReward - length / param.decayLife * param.decayFactor) / param.decayLife;
        }
    }
}
