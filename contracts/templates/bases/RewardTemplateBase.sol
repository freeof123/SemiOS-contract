// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";
import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { ExceedMaxMintableRound } from "contracts/interface/D4AErrors.sol";
import { RewardStorage } from "contracts/storages/RewardStorage.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";

abstract contract RewardTemplateBase is IRewardTemplate {
    function updateReward(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        uint256 daoFeeAmount,
        uint256 daoCreatorERC20RatioInBps
    )
        public
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        uint256 length = rewardInfo.activeRounds.length;
        if (rewardInfo.isProgressiveJackpot) {
            if (length != 0 && rewardInfo.activeRounds[length - 1] - startRound > totalRound) {
                revert ExceedMaxMintableRound();
            }
        } else {
            if (length != 0 && rewardInfo.activeRounds[length - 1] != currentRound) {
                if (length >= totalRound) revert ExceedMaxMintableRound();
            }
        }

        rewardInfo.totalWeights[currentRound] += daoFeeAmount;
        rewardInfo.daoCreatorWeights[currentRound] += daoFeeAmount * daoCreatorERC20RatioInBps / BASIS_POINT;
        rewardInfo.canvasCreatorWeights[currentRound][canvasId] +=
            daoFeeAmount * rewardInfo.canvasCreatorERC20RatioInBps / BASIS_POINT;
        rewardInfo.nftMinterWeights[currentRound][msg.sender] +=
            daoFeeAmount * rewardInfo.nftMinterERC20RatioInBps / BASIS_POINT;

        _updateRewardRound(rewardInfo, currentRound);
    }

    function claimDaoCreatorReward(
        bytes32 daoId,
        address daoCreator,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        public
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        _updateRewardRound(rewardInfo, currentRound);

        uint256 length = rewardInfo.activeRounds.length;
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        uint256 claimableReward;
        // enumerate all active rounds, not including current round
        for (uint256 i; i < length;) {
            // given a past active round, get round reward
            uint256 roundReward = getRoundReward(
                rewardInfo.totalReward,
                startRound,
                activeRounds[i],
                activeRounds,
                totalRound,
                rewardInfo.decayFactor,
                rewardInfo.decayLife,
                rewardInfo.isProgressiveJackpot
            );
            // update dao creator's claimable reward
            claimableReward +=
                roundReward * rewardInfo.daoCreatorWeights[activeRounds[i]] / rewardInfo.totalWeights[activeRounds[i]];
            unchecked {
                ++i;
            }
        }

        if (claimableReward > 0) D4AERC20(token).mint(daoCreator, claimableReward);
    }

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        public
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        _updateRewardRound(rewardInfo, currentRound);

        uint256 length = rewardInfo.activeRounds.length;
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        uint256 claimableReward;
        // enumerate all active rounds, not including current round
        for (uint256 i; i < length;) {
            // given a past active round, get round reward
            uint256 roundReward = getRoundReward(
                rewardInfo.totalReward,
                startRound,
                activeRounds[i],
                activeRounds,
                totalRound,
                rewardInfo.decayFactor,
                rewardInfo.decayLife,
                rewardInfo.isProgressiveJackpot
            );
            // update dao creator's claimable reward
            claimableReward += roundReward * rewardInfo.canvasCreatorWeights[activeRounds[i]][canvasId]
                / rewardInfo.totalWeights[activeRounds[i]];
            unchecked {
                ++i;
            }
        }

        if (claimableReward > 0) D4AERC20(token).mint(canvasCreator, claimableReward);
    }

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        public
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        _updateRewardRound(rewardInfo, currentRound);

        uint256 length = rewardInfo.activeRounds.length;
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        uint256 claimableReward;
        // enumerate all active rounds, not including current round
        for (uint256 i; i < length;) {
            // given a past active round, get round reward
            uint256 roundReward = getRoundReward(
                rewardInfo.totalReward,
                startRound,
                activeRounds[i],
                activeRounds,
                totalRound,
                rewardInfo.decayFactor,
                rewardInfo.decayLife,
                rewardInfo.isProgressiveJackpot
            );
            // update dao creator's claimable reward
            claimableReward += roundReward * rewardInfo.nftMinterWeights[activeRounds[i]][nftMinter]
                / rewardInfo.totalWeights[activeRounds[i]];
            unchecked {
                ++i;
            }
        }

        if (claimableReward > 0) D4AERC20(token).mint(nftMinter, claimableReward);
    }

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
        returns (uint256 rewardAmount);

    function _updateRewardRound(RewardStorage.RewardInfo storage rewardInfo, uint256 currentRound) internal {
        uint256 pendingRound = rewardInfo.rewardPendingRound;
        if (currentRound == pendingRound) return;

        rewardInfo.activeRounds.push(pendingRound);
        rewardInfo.rewardPendingRound = currentRound;
    }
}
