// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";
import { UpdateRewardParam } from "contracts/interface/D4AStructs.sol";
import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { ExceedMaxMintableRound } from "contracts/interface/D4AErrors.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { RewardStorage } from "contracts/storages/RewardStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";

abstract contract RewardTemplateBase is IRewardTemplate {
    function updateReward(UpdateRewardParam memory param) public payable {
        // deal with daoFeeAmount being 0
        if (param.daoFeeAmount == 0) param.daoFeeAmount = 1 ether;

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[param.daoId];

        // update initial mint pending round
        uint256 pendingRound = rewardInfo.rewardPendingRound;
        if (rewardInfo.rewardPendingRound == type(uint256).max) rewardInfo.rewardPendingRound = param.currentRound;
        if (param.currentRound > pendingRound) {
            rewardInfo.activeRounds.push(pendingRound);
            rewardInfo.rewardPendingRound = param.currentRound;
            _issueLastRoundReward(rewardInfo, param.daoId, param.token, pendingRound);
        }

        uint256 length = rewardInfo.activeRounds.length;
        if (rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].isProgressiveJackpot) {
            if (length != 0 && rewardInfo.activeRounds[length - 1] - param.startRound > param.totalRound) {
                revert ExceedMaxMintableRound();
            }
        } else {
            if (length != 0 && rewardInfo.activeRounds[length - 1] != param.currentRound) {
                if (length >= param.totalRound) revert ExceedMaxMintableRound();
            }
        }

        rewardInfo.totalWeights[param.currentRound] += param.daoFeeAmount;
        rewardInfo.protocolWeights[param.currentRound] +=
            param.daoFeeAmount * param.protocolERC20RatioInBps / BASIS_POINT;
        rewardInfo.daoCreatorWeights[param.currentRound] +=
            param.daoFeeAmount * param.daoCreatorERC20RatioInBps / BASIS_POINT;

        uint256 tokenRebateAmount =
            param.daoFeeAmount * param.nftMinterERC20RatioInBps * param.canvasRebateRatioInBps / BASIS_POINT ** 2;
        rewardInfo.canvasCreatorWeights[param.currentRound][param.canvasId] +=
            param.daoFeeAmount * param.canvasCreatorERC20RatioInBps / BASIS_POINT + tokenRebateAmount;
        rewardInfo.nftMinterWeights[param.currentRound][msg.sender] +=
            param.daoFeeAmount * param.nftMinterERC20RatioInBps / BASIS_POINT - tokenRebateAmount;
    }

    function claimDaoCreatorReward(
        bytes32 daoId,
        address protocolFeePool,
        address daoCreator,
        uint256 currentRound,
        address token
    )
        public
        returns (uint256 protocolClaimableReward, uint256 daoCreatorClaimableReward)
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        _updateRewardRoundAndIssue(rewardInfo, daoId, token, currentRound);

        uint256 length = rewardInfo.activeRounds.length;
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        // enumerate all active rounds, not including current round
        uint256 i = rewardInfo.daoCreatorClaimableRoundIndex;
        for (; i < length;) {
            // given a past active round, get round reward
            uint256 checkpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, currentRound);
            RewardStorage.RewardCheckpoint memory checkpoint = rewardInfo.rewardCheckpoints[checkpointIndex];
            uint256 roundReward =
                getRoundReward(daoId, activeRounds[i], i == 0 ? checkpoint.startRound : activeRounds[i - 1]);
            // update protocol's claimable reward
            protocolClaimableReward +=
                roundReward * rewardInfo.protocolWeights[activeRounds[i]] / rewardInfo.totalWeights[activeRounds[i]];
            // update dao creator's claimable reward
            daoCreatorClaimableReward +=
                roundReward * rewardInfo.daoCreatorWeights[activeRounds[i]] / rewardInfo.totalWeights[activeRounds[i]];
            unchecked {
                ++i;
            }
        }
        rewardInfo.daoCreatorClaimableRoundIndex = i;

        if (protocolClaimableReward > 0) D4AERC20(token).transfer(protocolFeePool, protocolClaimableReward);
        if (daoCreatorClaimableReward > 0) D4AERC20(token).transfer(daoCreator, daoCreatorClaimableReward);
    }

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 currentRound,
        address token
    )
        public
        returns (uint256 claimableReward)
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        _updateRewardRoundAndIssue(rewardInfo, daoId, token, currentRound);

        uint256 length = rewardInfo.activeRounds.length;
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        // enumerate all active rounds, not including current round
        uint256 i = rewardInfo.canvasCreatorClaimableRoundIndexes[canvasId];
        for (; i < length;) {
            // given a past active round, get round reward
            uint256 checkpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, currentRound);
            RewardStorage.RewardCheckpoint memory checkpoint = rewardInfo.rewardCheckpoints[checkpointIndex];
            uint256 roundReward =
                getRoundReward(daoId, activeRounds[i], i == 0 ? checkpoint.startRound : activeRounds[i - 1]);
            // update dao creator's claimable reward
            claimableReward += roundReward * rewardInfo.canvasCreatorWeights[activeRounds[i]][canvasId]
                / rewardInfo.totalWeights[activeRounds[i]];
            unchecked {
                ++i;
            }
        }
        rewardInfo.canvasCreatorClaimableRoundIndexes[canvasId] = i;

        if (claimableReward > 0) D4AERC20(token).transfer(canvasCreator, claimableReward);
    }

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 currentRound,
        address token
    )
        public
        returns (uint256 claimableReward)
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        _updateRewardRoundAndIssue(rewardInfo, daoId, token, currentRound);

        uint256 length = rewardInfo.activeRounds.length;
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        // enumerate all active rounds, not including current round
        uint256 i = rewardInfo.nftMinterClaimableRoundIndexes[nftMinter];
        for (; i < length;) {
            // given a past active round, get round reward
            uint256 checkpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, currentRound);
            RewardStorage.RewardCheckpoint memory checkpoint = rewardInfo.rewardCheckpoints[checkpointIndex];
            uint256 roundReward =
                getRoundReward(daoId, activeRounds[i], i == 0 ? checkpoint.startRound : activeRounds[i - 1]);
            // update dao creator's claimable reward
            claimableReward += roundReward * rewardInfo.nftMinterWeights[activeRounds[i]][nftMinter]
                / rewardInfo.totalWeights[activeRounds[i]];
            unchecked {
                ++i;
            }
        }
        rewardInfo.nftMinterClaimableRoundIndexes[nftMinter] = i;

        if (claimableReward > 0) D4AERC20(token).transfer(nftMinter, claimableReward);
    }

    function setRewardCheckpoint(
        bytes32 daoId,
        uint256 rewardDecayFactor,
        uint256 rewardDecayLife,
        bool isProgressiveJackpot
    )
        public
        payable
    {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

        if (rewardInfo.rewardCheckpoints.length == 0) {
            rewardInfo.rewardCheckpoints.push(
                RewardStorage.RewardCheckpoint({
                    startRound: daoInfo.startRound,
                    totalRound: daoInfo.mintableRound,
                    totalReward: daoInfo.tokenMaxSupply,
                    decayFactor: rewardDecayFactor,
                    decayLife: rewardDecayLife,
                    isProgressiveJackpot: isProgressiveJackpot
                })
            );
        } else {
            uint256 startRound = settingsStorage.drb.currentRound();
            RewardStorage.RewardCheckpoint storage rewardCheckpoint =
                rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1];
            uint256 totalRound = rewardCheckpoint.totalRound - (startRound - rewardCheckpoint.startRound);
            uint256 totalReward = daoInfo.tokenMaxSupply - D4AERC20(daoInfo.token).totalSupply();
            rewardInfo.rewardCheckpoints.push(
                RewardStorage.RewardCheckpoint({
                    startRound: startRound,
                    totalRound: totalRound,
                    totalReward: totalReward,
                    decayFactor: rewardDecayFactor,
                    decayLife: rewardDecayLife,
                    isProgressiveJackpot: isProgressiveJackpot
                })
            );
        }
    }

    /**
     * @dev calculate a sub-array of active rounds given start round and end round of a checkpoint
     * @dev doesn't include sanity check, active rounds length equal to 0, startRound less than endRound
     * @param activeRounds all active rounds of a DAO
     * @param startRound start round of a checkpoint
     * @param endRound end round of a checkpoint, either start round of the next checkpoint - 1, or current round
     * @return activeRoundsOfCheckpoint active rounds of a specific checkpoint, greater than or equal to start round,
     * less than or equal to end
     * round
     */
    function getActiveRoundsOfCheckpoint(
        uint256[] memory activeRounds,
        uint256 startRound,
        uint256 endRound
    )
        public
        pure
        returns (uint256[] memory activeRoundsOfCheckpoint)
    {
        if (activeRounds.length == 0) return activeRounds;

        uint256 l;
        uint256 r = activeRounds.length - 1;
        uint256 mid;
        while (l < r) {
            mid = l + r >> 1;
            if (activeRounds[mid] < startRound) l = mid + 1;
            else r = mid;
        }
        uint256 startIndex = l;

        l = 0;
        r = activeRounds.length - 1;
        while (l < r) {
            mid = l + r + 1 >> 1;
            if (activeRounds[mid] > endRound) r = mid - 1;
            else l = mid;
        }
        uint256 endIndex = l;

        /// @solidity memory-safe-assembly
        assembly {
            let offset := add(activeRounds, mul(startIndex, 0x20))
            let length := sub(add(endIndex, 1), startIndex)
            mstore(offset, length)
            activeRoundsOfCheckpoint := offset // assign return value to remove unreachable code warning
                // return(offset, mul(add(length, 1), 0x20))
        }
    }

    /**
     * @dev given an array of active rounds and a round, find the index of the round in the array
     */
    function getRoundIndex(uint256[] memory activeRounds, uint256 round) public pure returns (uint256 index) {
        if (activeRounds.length == 0) return 0;

        uint256 l;
        uint256 r = activeRounds.length - 1;
        uint256 mid;
        while (l < r) {
            mid = l + r >> 1;
            if (activeRounds[mid] < round) l = mid + 1;
            else r = mid;
        }
        return l;
    }

    /**
     * @dev given a DAO's reward info, a given round and the corresponding last active round relative to the round,
     * calculate reward of the round
     * @param daoId DAO id
     * @param round a specific round
     * @param lastActiveRound last active round relative to the specific round
     * @return rewardAmount reward amount of the round
     */
    function getRoundReward(
        bytes32 daoId,
        uint256 round,
        uint256 lastActiveRound
    )
        public
        view
        virtual
        returns (uint256 rewardAmount);

    function _updateRewardRoundAndIssue(
        RewardStorage.RewardInfo storage rewardInfo,
        bytes32 daoId,
        address token,
        uint256 currentRound
    )
        internal
    {
        uint256 pendingRound = rewardInfo.rewardPendingRound;
        if (currentRound > pendingRound) {
            rewardInfo.activeRounds.push(pendingRound);
            rewardInfo.rewardPendingRound = type(uint256).max;
            _issueLastRoundReward(rewardInfo, daoId, token, pendingRound);
        }
    }

    /**
     * @dev given a round, get the index of the corresponding reward checkpoint
     * @param rewardCheckpoints reward checkpoints of a DAO
     * @param round a specific round
     * @return index index of the corresponding reward checkpoint
     */
    function _getRewardCheckpointIndexByRound(
        RewardStorage.RewardCheckpoint[] storage rewardCheckpoints,
        uint256 round
    )
        internal
        view
        returns (uint256 index)
    {
        uint256 length = rewardCheckpoints.length;
        for (uint256 i; i < length - 1;) {
            if (rewardCheckpoints[i + 1].startRound > round) return i;
            unchecked {
                ++i;
            }
        }
        return length - 1;
    }

    /**
     * @dev Since this method is called when `_updateRewardRoundAndIssue` is called, which is called everytime when
     * `mint` or `claim reward`, we can assure that only one pending round reward is issued at a time
     * @param rewardInfo reward info of a DAO
     * @param pendingRound pending round of a DAO
     */
    function _issueLastRoundReward(
        RewardStorage.RewardInfo storage rewardInfo,
        bytes32 daoId,
        address token,
        uint256 pendingRound
    )
        internal
    {
        uint256 activeRoundLength = rewardInfo.activeRounds.length;
        // get reward of the pending round
        uint256 roundReward = getRoundReward(
            daoId,
            pendingRound,
            activeRoundLength == 0
                // if no active round, use the start round of the first checkpoint
                ? rewardInfo.rewardCheckpoints[0].startRound
                // otherwise, use the last active round
                : rewardInfo.activeRounds[activeRoundLength - 1]
        );
        D4AERC20(token).mint(address(this), roundReward);
    }
}
