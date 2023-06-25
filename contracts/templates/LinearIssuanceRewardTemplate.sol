// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as Math } from "solady/utils/FixedPointMathLib.sol";

import { ExceedMaxMintableRound } from "../interface/D4AErrors.sol";
import { RewardStorage } from "../storages/RewardStorage.sol";

contract LinearIssuanceRewardTemplate {
    function updateReward(
        bytes32 daoId,
        uint256 currentRound,
        address daoCreator,
        address canvasCreator,
        uint256 daoFeeAmount,
        uint256 daoCreatorERC20RatioInBps
    )
        public
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        rewardInfo.totalWeights[currentRound] += daoFeeAmount;
        rewardInfo.daoCreatorWeights[currentRound][daoCreator] += daoFeeAmount * daoCreatorERC20RatioInBps;
        rewardInfo.canvasCreatorWeights[currentRound][canvasCreator] +=
            daoFeeAmount * rewardInfo.canvasCreatorERC20RatioInBps;
        rewardInfo.nftMinterWeights[currentRound][msg.sender] += daoFeeAmount * rewardInfo.nftMinterERC20RatioInBps;

        rewardInfo.lastActiveRound = currentRound;
        uint256 length = rewardInfo.activeRounds.length;
        if (length == 0 || rewardInfo.activeRounds[length - 1] != currentRound) {
            rewardInfo.activeRounds.push(currentRound);
        }
    }

    function claimDaoCreatorReward() public { }

    function claimCanvasCreatorReward() public { }

    function claimNftMinterReward() public { }

    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * total round to be `n`, total reward to be `T`, then
     * `(x - 0 * k) + (x - 1 * k) + ... + (x - (n - 1) * k) = T`
     * `x = T / n + (n - 1) * k / 2`
     */
    function getReward(
        uint256 totalReward,
        uint256 startRound,
        uint256 currentRound,
        uint256 lastActiveRound,
        uint256 totalRound,
        uint256 decayFactor,
        bool isProgressiveJackpot
    )
        public
        pure
        returns (uint256 rewardAmount)
    {
        uint256 currentRoundReward =
            totalReward / totalRound + (totalRound - 1) * decayFactor / 2 - (currentRound - startRound) * decayFactor;
        if (isProgressiveJackpot) {
            uint256 claimableRound = Math.max(currentRound - lastActiveRound, 1);
            rewardAmount = claimableRound * currentRoundReward + claimableRound * (claimableRound - 1) * decayFactor / 2;
        } else {
            rewardAmount = currentRoundReward;
        }
    }
}
