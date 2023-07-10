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

import "forge-std/Test.sol";

abstract contract RewardTemplateBase is IRewardTemplate {
    function updateReward(UpdateRewardParam memory param) public payable {
        // deal with daoFeeAmount being 0
        if (param.daoFeeAmount == 0) param.daoFeeAmount = 1 ether;

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[param.daoId];

        // update initial mint pending round
        uint256[] storage activeRounds =
            rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].activeRounds;
        // new checkpoint
        if (activeRounds.length == 0) {
            // has at least one old checkpoint
            if (rewardInfo.rewardCheckpoints.length > 1) {
                // last checkpoint's active rounds
                uint256[] storage activeRoundsOfLastCheckpoint =
                    rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 2].activeRounds;
                if (activeRoundsOfLastCheckpoint[activeRoundsOfLastCheckpoint.length - 1] != param.currentRound) {
                    _issueLastRoundReward(
                        param.daoId, param.token, activeRoundsOfLastCheckpoint[activeRoundsOfLastCheckpoint.length - 1]
                    );
                    activeRounds.push(param.currentRound);
                }
            }
            // no old checkpoint
            else {
                activeRounds.push(param.currentRound);
            }
        }
        // not new checkpoint
        else {
            if (activeRounds[activeRounds.length - 1] != param.currentRound) {
                rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].lastActiveRound =
                    activeRounds[activeRounds.length - 1];
                _issueLastRoundReward(
                    param.daoId,
                    param.token,
                    rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].lastActiveRound
                );
                activeRounds.push(param.currentRound);
            }
        }

        uint256 length = activeRounds.length;
        if (rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].isProgressiveJackpot) {
            if (length != 0 && activeRounds[length - 1] - param.startRound > param.totalRound) {
                revert ExceedMaxMintableRound();
            }
        } else {
            if (length != 0 && activeRounds[length - 1] != param.currentRound) {
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

        RewardStorage.RewardCheckpoint[] storage rewardCheckpoints = rewardInfo.rewardCheckpoints;
        for (uint256 i; i < rewardCheckpoints.length; i++) {
            uint256 length = rewardCheckpoints[i].activeRounds.length;
            uint256[] memory activeRounds = rewardCheckpoints[i].activeRounds;

            // enumerate all active rounds, not including current round
            uint256 j = rewardCheckpoints[i].daoCreatorClaimableRoundIndex;
            for (; j < length;) {
                // given a past active round, get round reward
                uint256 roundReward = getRoundReward(daoId, activeRounds[j]);
                // update protocol's claimable reward
                protocolClaimableReward +=
                    roundReward * rewardInfo.protocolWeights[activeRounds[j]] / rewardInfo.totalWeights[activeRounds[j]];
                // update dao creator's claimable reward
                daoCreatorClaimableReward += roundReward * rewardInfo.daoCreatorWeights[activeRounds[j]]
                    / rewardInfo.totalWeights[activeRounds[j]];
                unchecked {
                    ++j;
                }
            }
            rewardCheckpoints[i].daoCreatorClaimableRoundIndex = j;
        }

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

        RewardStorage.RewardCheckpoint[] storage rewardCheckpoints = rewardInfo.rewardCheckpoints;
        for (uint256 i; i < rewardCheckpoints.length; i++) {
            uint256 length = rewardCheckpoints[i].activeRounds.length;
            uint256[] memory activeRounds = rewardCheckpoints[i].activeRounds;

            // enumerate all active rounds, not including current round
            uint256 j = rewardCheckpoints[i].canvasCreatorClaimableRoundIndexes[canvasId];
            for (; j < length;) {
                // given a past active round, get round reward
                uint256 roundReward = getRoundReward(daoId, activeRounds[j]);
                // update dao creator's claimable reward
                claimableReward += roundReward * rewardInfo.canvasCreatorWeights[activeRounds[j]][canvasId]
                    / rewardInfo.totalWeights[activeRounds[j]];
                unchecked {
                    ++j;
                }
            }
            rewardCheckpoints[i].canvasCreatorClaimableRoundIndexes[canvasId] = j;
        }

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

        RewardStorage.RewardCheckpoint[] storage rewardCheckpoints = rewardInfo.rewardCheckpoints;
        for (uint256 i; i < rewardCheckpoints.length; i++) {
            uint256 length = rewardCheckpoints[i].activeRounds.length;
            uint256[] memory activeRounds = rewardCheckpoints[i].activeRounds;

            // enumerate all active rounds, not including current round
            uint256 j = rewardCheckpoints[i].nftMinterClaimableRoundIndexes[nftMinter];
            for (; j < length;) {
                // given a past active round, get round reward
                uint256 roundReward = getRoundReward(daoId, activeRounds[j]);
                // update dao creator's claimable reward
                claimableReward += roundReward * rewardInfo.nftMinterWeights[activeRounds[j]][nftMinter]
                    / rewardInfo.totalWeights[activeRounds[j]];
                unchecked {
                    ++j;
                }
            }
            rewardCheckpoints[i].nftMinterClaimableRoundIndexes[nftMinter] = j;
        }

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
            rewardInfo.rewardCheckpoints.push();
            rewardInfo.rewardCheckpoints[0].startRound = daoInfo.startRound;
            rewardInfo.rewardCheckpoints[0].totalRound = daoInfo.mintableRound;
            rewardInfo.rewardCheckpoints[0].totalReward = daoInfo.tokenMaxSupply;
            rewardInfo.rewardCheckpoints[0].rewardDecayFactor = rewardDecayFactor;
            rewardInfo.rewardCheckpoints[0].rewardDecayLife = rewardDecayLife;
            rewardInfo.rewardCheckpoints[0].isProgressiveJackpot = isProgressiveJackpot;
        } else if (rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].activeRounds.length == 0) {
            rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].startRound = daoInfo.startRound;
            rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].totalRound = daoInfo.mintableRound;
            rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].totalReward = daoInfo.tokenMaxSupply;
            rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].rewardDecayFactor = rewardDecayFactor;
            rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].rewardDecayLife = rewardDecayLife;
            rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].isProgressiveJackpot =
                isProgressiveJackpot;
        } else {
            uint256 startRound = settingsStorage.drb.currentRound();
            RewardStorage.RewardCheckpoint storage rewardCheckpoint =
                rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1];
            uint256 totalRound = rewardCheckpoint.totalRound - (startRound - rewardCheckpoint.startRound);
            uint256 totalReward = daoInfo.tokenMaxSupply - D4AERC20(daoInfo.token).totalSupply();
            rewardInfo.rewardCheckpoints.push();
            uint256 length = rewardInfo.rewardCheckpoints.length;
            rewardInfo.rewardCheckpoints[length - 1].startRound = startRound;
            rewardInfo.rewardCheckpoints[length - 1].totalRound = totalRound;
            rewardInfo.rewardCheckpoints[length - 1].totalReward = totalReward;
            rewardInfo.rewardCheckpoints[length - 1].rewardDecayFactor = rewardDecayFactor;
            rewardInfo.rewardCheckpoints[length - 1].rewardDecayLife = rewardDecayLife;
            rewardInfo.rewardCheckpoints[length - 1].isProgressiveJackpot = isProgressiveJackpot;
        }
    }

    /**
     * @dev given an array of active rounds and a round, return the number of rounds below the round
     */
    function _getBelowRoundCount(uint256[] memory activeRounds, uint256 round) public pure returns (uint256 index) {
        if (activeRounds.length == 0) return 0;

        uint256 l;
        uint256 r = activeRounds.length - 1;
        uint256 mid;
        while (l < r) {
            mid = l + r >> 1;
            if (activeRounds[mid] < round) l = mid + 1;
            else r = mid;
        }
        return activeRounds[l] == round ? l : l + 1;
    }

    /**
     * @dev given a DAO's reward info, a given round and the corresponding last active round relative to the round,
     * calculate reward of the round
     * @param daoId DAO id
     * @param round a specific round
     * @return rewardAmount reward amount of the round
     */
    function getRoundReward(bytes32 daoId, uint256 round) public view virtual returns (uint256 rewardAmount);

    function _updateRewardRoundAndIssue(
        RewardStorage.RewardInfo storage rewardInfo,
        bytes32 daoId,
        address token,
        uint256 currentRound
    )
        internal
    {
        uint256[] storage activeRounds =
            rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].activeRounds;
        // new checkpoint
        if (activeRounds.length == 0) {
            // has at least one old checkpoint
            if (rewardInfo.rewardCheckpoints.length > 1) {
                // last checkpoint's active rounds
                uint256[] storage activeRoundsOfLastCheckpoint =
                    rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 2].activeRounds;
                if (activeRoundsOfLastCheckpoint[activeRoundsOfLastCheckpoint.length - 1] != currentRound) {
                    _issueLastRoundReward(
                        daoId, token, activeRoundsOfLastCheckpoint[activeRoundsOfLastCheckpoint.length - 1]
                    );
                }
            }
        }
        // not new checkpoint
        else {
            if (activeRounds[activeRounds.length - 1] != currentRound) {
                rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].lastActiveRound =
                    activeRounds[activeRounds.length - 1];
                _issueLastRoundReward(
                    daoId, token, rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].lastActiveRound
                );
            }
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

    function _getLastActiveRound(
        RewardStorage.RewardInfo storage rewardInfo,
        uint256 round
    )
        internal
        view
        returns (uint256)
    {
        console2.log("length: %s", rewardInfo.rewardCheckpoints.length);
        for (uint256 i = rewardInfo.rewardCheckpoints.length - 1; ~i != 0;) {
            if (
                rewardInfo.rewardCheckpoints[i].lastActiveRound < round
                    && rewardInfo.rewardCheckpoints[i].lastActiveRound != 0
            ) {
                return rewardInfo.rewardCheckpoints[i].lastActiveRound;
            }
            unchecked {
                --i;
            }
        }
        return rewardInfo.rewardCheckpoints[0].startRound - 1;
    }

    /**
     * @dev Since this method is called when `_updateRewardRoundAndIssue` is called, which is called everytime when
     * `mint` or `claim reward`, we can assure that only one pending round reward is issued at a time
     */
    function _issueLastRoundReward(bytes32 daoId, address token, uint256 pendingRound) internal {
        // get reward of the pending round
        uint256 roundReward = getRoundReward(daoId, pendingRound);
        D4AERC20(token).mint(address(this), roundReward);
    }
}
