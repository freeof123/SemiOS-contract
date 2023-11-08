// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SafeCastLib } from "solady/utils/SafeCastLib.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";

import { IRewardTemplateFunding } from "contracts/interface/IRewardTemplateFunding.sol";
import { UpdateRewardParam } from "contracts/interface/D4AStructs.sol";
import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { ExceedMaxMintableRound, InvalidRound } from "contracts/interface/D4AErrors.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";

import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";

import { RewardStorage } from "contracts/storages/RewardStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";

import { PoolStorage } from "contracts/storages/PoolStorage.sol";

import { InheritTreeStorage } from "contracts/storages/InheritTreeStorage.sol";

import { D4AERC20 } from "contracts/D4AERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";

import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";

import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
//import "forge-std/Test.sol";

contract UniformDistribuctionRewardIssuance is IRewardTemplateFunding {
    function updateRewardFunding(UpdateRewardParam memory param) public payable {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[param.daoId];
        uint256 remainingRound = IPDProtocolReadable(address(this)).getDaoRemainingRound(param.daoId);
        if (remainingRound == 0) revert ExceedMaxMintableRound();
        if (!rewardInfo.roundDistributed[param.currentRound]) {
            uint256 distributeAmount = getDaoCurrentRoundDistributeAmount(
                param.daoId, param.token, param.startRound, param.currentRound, remainingRound
            );
            _distributeRoundReward(param.daoId, distributeAmount, param.token);
            rewardInfo.roundDistributed[param.currentRound] = true;
        }
        uint256[] storage activeRounds = rewardInfo.activeRoundsFunding;
    }

    function getDaoCurrentRoundDistributeAmount(
        bytes32 daoId,
        address token,
        uint256 startRound,
        uint256 currentRound,
        uint256 remainingRound
    )
        public
        view
        returns (uint256 distributeAmount)
    {
        //return IPDProtocolReadable(address(this)).getDaoCurrentRoundDistributeAmount(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        address daoAssetPool = IPDProtocolReadable(address(this)).getDaoAssetPool(daoId);
        distributeAmount = token == address(0) ? daoAssetPool.balance : IERC20(token).balanceOf(daoAssetPool);
        //distributeAmount = distributeAmount / remainingRound;
        if (rewardInfo.isProgressiveJackpot) {
            uint256 lastActiveRound = _getLastActiveRound(rewardInfo, currentRound); //not include current round
            uint256 progressiveJackpotRound = currentRound - lastActiveRound == 0 ? startRound - 1 : lastActiveRound;
            distributeAmount =
                distributeAmount * progressiveJackpotRound / (progressiveJackpotRound + remainingRound - 1);
        } else {
            distributeAmount = distributeAmount / remainingRound;
        }
    }

    function getRoundReward(
        bytes32 daoId,
        uint256 round,
        address token
    )
        public
        view
        virtual
        returns (uint256 rewardAmount)
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256 remainingRound = IPDProtocolReadable(address(this)).getDaoRemainingRound(daoId);
        if (remainingRound == 0) revert ExceedMaxMintableRound();
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
            RewardStorage.RewardCheckpoint storage rewardCheckpoint = rewardCheckpoints[i];
            uint256[] memory activeRounds = rewardCheckpoint.activeRounds;

            // enumerate all active rounds, not including current round
            uint256 j = rewardCheckpoint.daoCreatorClaimableRoundIndex;
            for (; j < activeRounds.length && activeRounds[j] < currentRound;) {
                // given a past active round, get round reward
                uint256 roundReward = getRoundReward(daoId, activeRounds[j], token);
                // update protocol's claimable reward
                protocolClaimableReward +=
                    roundReward * rewardInfo.protocolWeights[activeRounds[j]] / rewardInfo.totalWeights[activeRounds[j]];
                // update dao creator's claimable reward, use weights caculated by ratios w.r.t. 4 roles
                daoCreatorClaimableReward += roundReward * rewardInfo.daoCreatorWeights[activeRounds[j]]
                    / rewardInfo.totalWeights[activeRounds[j]];
                unchecked {
                    ++j;
                }
            }
            rewardCheckpoint.daoCreatorClaimableRoundIndex = j;
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
            RewardStorage.RewardCheckpoint storage rewardCheckpoint = rewardCheckpoints[i];
            uint256[] memory activeRounds = rewardCheckpoint.activeRounds;

            // enumerate all active rounds, not including current round
            uint256 j = rewardCheckpoint.canvasCreatorClaimableRoundIndexes[canvasId];
            for (; j < activeRounds.length && activeRounds[j] < currentRound;) {
                // given a past active round, get round reward
                uint256 roundReward = getRoundReward(daoId, activeRounds[j], token);
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
            RewardStorage.RewardCheckpoint storage rewardCheckpoint = rewardCheckpoints[i];
            uint256[] memory activeRounds = rewardCheckpoint.activeRounds;

            // enumerate all active rounds, not including current round
            uint256 j = rewardCheckpoint.nftMinterClaimableRoundIndexes[nftMinter];
            for (; j < activeRounds.length && activeRounds[j] < currentRound;) {
                // given a past active round, get round reward
                uint256 roundReward = getRoundReward(daoId, activeRounds[j], token);
                // update dao creator's claimable reward
                claimableReward += roundReward * rewardInfo.nftMinterWeights[activeRounds[j]][nftMinter]
                    / rewardInfo.totalWeights[activeRounds[j]];
                unchecked {
                    ++j;
                }
            }
            rewardCheckpoint.nftMinterClaimableRoundIndexes[nftMinter] = j;
        }

        if (claimableReward > 0) D4AERC20(token).transfer(nftMinter, claimableReward);
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

    // /**
    //  * @dev given a DAO's reward info, a given round and the corresponding last active round relative to the round,
    //  * calculate reward of the round
    //  * @param daoId DAO id
    //  * @param round a specific round
    //  * @return rewardAmount reward amount of the round
    //  */

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
                    _issueLastRoundReward(daoId, token);
                }
            }
        }
        // not new checkpoint
        else {
            if (activeRounds[activeRounds.length - 1] != currentRound) {
                // rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1].lastActiveRound =
                //     activeRounds[activeRounds.length - 1];
                _issueLastRoundReward(daoId, token);
            }
        }
    }

    function _getLastActiveRound(
        RewardStorage.RewardInfo storage rewardInfo,
        uint256 round
    )
        internal
        view
        returns (uint256)
    {
        uint256[] storage activeRounds = rewardInfo.activeRoundsFunding;
        if (activeRounds.length > 0) {
            for (uint256 j = activeRounds.length - 1; ~j != 0;) {
                if (activeRounds[j] < round) return activeRounds[j];
                unchecked {
                    --j;
                }
            }
        }

        return 0;
    }

    function issueLastRoundReward(bytes32 daoId, address token) public {
        _issueLastRoundReward(daoId, token);
    }

    /**
     * @dev Since this method is called when `_updateRewardRoundAndIssue` is called, which is called everytime when
     * `mint` or `claim reward`, we can assure that only one pending round reward is issued at a time
     */
    function _issueLastRoundReward(bytes32 daoId, address token) internal {
        InheritTreeStorage.InheritTreeInfo memory treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        uint256 currentRound = SettingsStorage.layout().drb.currentRound();

        if (treeInfo.ancestor != bytes32(0)) {
            treeInfo = InheritTreeStorage.layout().inheritTreeInfos[treeInfo.ancestor];
        }
        uint256 length = treeInfo.familyDaos.length;
        if (length != 0) {
            for (uint256 i; i < length;) {
                RewardStorage.RewardInfo storage rewardInfoTemp =
                    RewardStorage.layout().rewardInfos[treeInfo.familyDaos[i]];
                // get reward of the pending round
                if (
                    rewardInfoTemp.rewardIssuePendingRound != 0 && currentRound > rewardInfoTemp.rewardIssuePendingRound
                ) {
                    uint256 roundReward =
                        getRoundReward(treeInfo.familyDaos[i], rewardInfoTemp.rewardIssuePendingRound, token);
                    rewardInfoTemp.rewardIssuePendingRound = 0;
                    D4AERC20(token).mint(address(this), roundReward);
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            RewardStorage.RewardInfo storage rewardInfoTemp = RewardStorage.layout().rewardInfos[daoId];
            // get reward of the pending round
            if (rewardInfoTemp.rewardIssuePendingRound != 0 && currentRound > rewardInfoTemp.rewardIssuePendingRound) {
                uint256 roundReward = getRoundReward(daoId, rewardInfoTemp.rewardIssuePendingRound, token);
                rewardInfoTemp.rewardIssuePendingRound = 0;
                D4AERC20(token).mint(address(this), roundReward);
            }
        }
    }

    function _distributeRoundReward(bytes32 daoId, uint256 amount, address token) internal {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        bytes32[] memory children = IPDProtocolReadable(address(this)).getDaoChildren(daoId);
        uint256[] memory childrenDaoRatio = token == address(0)
            ? IPDProtocolReadable(address(this)).getDaoChildrenRatiosETH(daoId)
            : IPDProtocolReadable(address(this)).getDaoChildrenRatiosERC20(daoId);
        address daoAssetPool = basicDaoInfo.daoAssetPool;
        for (uint256 i = 0; i < children.length;) {
            address desPool = IPDProtocolReadable(address(this)).getDaoAssetPool(children[i]);
            if (childrenDaoRatio[i] > 0) {
                D4AFeePool(payable(daoAssetPool)).transfer(
                    token, payable(desPool), amount * childrenDaoRatio[i] / BASIS_POINT
                );
            }
            unchecked {
                ++i;
            }
        }

        if (token == address(0)) {
            uint256 redeemPoolRatio = IPDProtocolReadable(address(this)).getDaoRedeemPoolRatioETH(daoId);
            if (redeemPoolRatio > 0) {
                D4AFeePool(payable(daoAssetPool)).transfer(
                    token, payable(daoInfo.daoFeePool), amount * redeemPoolRatio / BASIS_POINT
                );
            }
        }
        uint256 selfRewardRatio = token == address(0)
            ? IPDProtocolReadable(address(this)).getDaoSelfRewardRatioETH(daoId)
            : IPDProtocolReadable(address(this)).getDaoSelfRewardRatioERC20(daoId);
        if (selfRewardRatio > 0) {
            uint256 selfRewardAmount = amount * selfRewardRatio / BASIS_POINT;
            D4AFeePool(payable(daoAssetPool)).transfer(token, payable(address(this)), selfRewardAmount);
            rewardInfo.circulateERC20Amount += selfRewardAmount;
        }
    }
}
