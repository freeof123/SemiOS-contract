// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SafeCastLib } from "solady/utils/SafeCastLib.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";

import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";
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

contract UniformDistributionRewardIssuance is IRewardTemplate {
    function updateReward(UpdateRewardParam memory param) public payable {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[param.daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        uint256[] storage activeRounds = rewardInfo.activeRounds;

        if (activeRounds.length == 0 || activeRounds[activeRounds.length - 1] != param.currentRound) {
            uint256 remainingRound = IPDProtocolReadable(address(this)).getDaoRemainingRound(param.daoId);
            if (remainingRound == 0) revert ExceedMaxMintableRound();
            uint256 erc20DistributeAmount =
                getDaoRoundDistributeAmount(param.daoId, param.token, param.currentRound, remainingRound);
            _distributeRoundReward(param.daoId, erc20DistributeAmount, param.token, param.currentRound);
            uint256 ethDistributeAmount;
            if (!param.topUpMode) {
                ethDistributeAmount =
                    getDaoRoundDistributeAmount(param.daoId, address(0), param.currentRound, remainingRound);
                _distributeRoundReward(param.daoId, ethDistributeAmount, address(0), param.currentRound);
            }
            activeRounds.push(param.currentRound);
            emit DaoBlockRewardTotal(
                param.daoId, param.token, erc20DistributeAmount, ethDistributeAmount, param.currentRound
            );
        }

        rewardInfo.totalWeights[param.currentRound] += param.daoFeeAmount;
        if (!param.topUpMode) {
            rewardInfo.protocolWeights[param.currentRound] +=
                param.daoFeeAmount * settingsStorage.protocolERC20RatioInBps / BASIS_POINT;

            rewardInfo.daoCreatorWeights[param.currentRound] += param.daoFeeAmount
                * IPDProtocolReadable(address(this)).getDaoCreatorERC20RewardRatio(param.daoId) / BASIS_POINT;

            rewardInfo.canvasCreatorWeights[param.currentRound][param.canvasId] += param.daoFeeAmount
                * IPDProtocolReadable(address(this)).getCanvasCreatorERC20RewardRatio(param.daoId) / BASIS_POINT;

            rewardInfo.nftMinterWeights[param.currentRound][msg.sender] += param.daoFeeAmount
                * IPDProtocolReadable(address(this)).getMinterERC20RewardRatio(param.daoId) / BASIS_POINT;

            rewardInfo.protocolWeightsETH[param.currentRound] +=
                param.daoFeeAmount * settingsStorage.protocolETHRewardRatio / BASIS_POINT;

            rewardInfo.daoCreatorWeightsETH[param.currentRound] += param.daoFeeAmount
                * IPDProtocolReadable(address(this)).getDaoCreatorETHRewardRatio(param.daoId) / BASIS_POINT;

            rewardInfo.canvasCreatorWeightsETH[param.currentRound][param.canvasId] += param.daoFeeAmount
                * IPDProtocolReadable(address(this)).getCanvasCreatorETHRewardRatio(param.daoId) / BASIS_POINT;

            rewardInfo.nftMinterWeightsETH[param.currentRound][msg.sender] += param.daoFeeAmount
                * IPDProtocolReadable(address(this)).getMinterETHRewardRatio(param.daoId) / BASIS_POINT;
        } else {
            rewardInfo.nftMinterWeights[param.currentRound][msg.sender] += param.daoFeeAmount;
        }
    }

    function getDaoRoundDistributeAmount(
        bytes32 daoId,
        address token,
        uint256 currentRound,
        uint256 remainingRound
    )
        public
        view
        returns (uint256 distributeAmount)
    {
        address daoAssetPool = IPDProtocolReadable(address(this)).getDaoAssetPool(daoId);
        distributeAmount = token == address(0) ? daoAssetPool.balance : IERC20(token).balanceOf(daoAssetPool);
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].infiniteMode) {
            return distributeAmount;
        }
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        if (remainingRound == 0) return 0;

        if (rewardInfo.isProgressiveJackpot) {
            uint256 lastActiveRound = _getLastActiveRound(rewardInfo, currentRound); //not include current round
            uint256 progressiveJackpotRound = currentRound - lastActiveRound; // include current round
            if (BasicDaoStorage.layout().basicDaoInfos[daoId].version < 14 && lastActiveRound == 0) {
                progressiveJackpotRound = currentRound - DaoStorage.layout().daoInfos[daoId].startBlock + 1;
            }
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
        return token == address(0) ? rewardInfo.selfRoundETHReward[round] : rewardInfo.selfRoundERC20Reward[round];
    }

    function claimDaoCreatorReward(
        bytes32 daoId,
        address protocolFeePool,
        address daoCreator,
        uint256 currentRound,
        address token
    )
        public
        returns (
            uint256 protocolClaimableERC20Reward,
            uint256 daoCreatorClaimableERC20Reward,
            uint256 protocolClaimableETHReward,
            uint256 daoCreatorClaimableETHReward
        )
    {
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode) return (0, 0, 0, 0);

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        //_updateRewardRoundAndIssue(rewardInfo, daoId, token, currentRound);

        uint256[] memory activeRounds = rewardInfo.activeRounds;

        // enumerate all active rounds, not including current round
        uint256 j = rewardInfo.daoCreatorClaimableRoundIndex;
        for (; j < activeRounds.length && activeRounds[j] < currentRound;) {
            // rewardInfo.totalWeights = 0 is IMPOSSIBLE since weight is either non-zero price or 1 ether for 0 price,
            // except that the active round is pushed for dao restarting
            // todo: change active round push for dao restart in next version
            if (rewardInfo.totalWeights[activeRounds[j]] == 0) {
                unchecked {
                    ++j;
                }
                continue;
            }
            // given a past active round, get round reward
            uint256 roundReward = getRoundReward(daoId, activeRounds[j], token);
            // update protocol's and creator's claimable reward, use weights caculated by ratios w.r.t. 4 roles
            protocolClaimableERC20Reward +=
                roundReward * rewardInfo.protocolWeights[activeRounds[j]] / rewardInfo.totalWeights[activeRounds[j]];
            daoCreatorClaimableERC20Reward +=
                roundReward * rewardInfo.daoCreatorWeights[activeRounds[j]] / rewardInfo.totalWeights[activeRounds[j]];

            roundReward = getRoundReward(daoId, activeRounds[j], address(0));
            protocolClaimableETHReward +=
                roundReward * rewardInfo.protocolWeightsETH[activeRounds[j]] / rewardInfo.totalWeights[activeRounds[j]];
            daoCreatorClaimableETHReward += roundReward * rewardInfo.daoCreatorWeightsETH[activeRounds[j]]
                / rewardInfo.totalWeights[activeRounds[j]];
            unchecked {
                ++j;
            }
        }
        rewardInfo.daoCreatorClaimableRoundIndex = j;

        if (protocolClaimableERC20Reward > 0) D4AERC20(token).transfer(protocolFeePool, protocolClaimableERC20Reward);
        if (daoCreatorClaimableERC20Reward > 0) D4AERC20(token).transfer(daoCreator, daoCreatorClaimableERC20Reward);
        if (protocolClaimableETHReward > 0) {
            (bool succ,) = protocolFeePool.call{ value: protocolClaimableETHReward }("");
            require(succ, "transfer eth failed");
        }
        if (daoCreatorClaimableETHReward > 0) {
            (bool succ,) = daoCreator.call{ value: daoCreatorClaimableETHReward }("");
            require(succ, "transfer eth failed");
        }
        // (protocolClaimableERC20Reward, daoCreatorClaimableERC20Reward) =
        //     _claimDaoCreatorReward(daoId, protocolFeePool, daoCreator, currentRound, token);
        // (protocolClaimableETHReward, daoCreatorClaimableETHReward) =
        //     _claimDaoCreatorReward(daoId, protocolFeePool, daoCreator, currentRound, address(0));
    }

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 currentRound,
        address token
    )
        public
        returns (uint256 claimableERC20Reward, uint256 claimableETHReward)
    {
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode) return (0, 0);

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        //_updateRewardRoundAndIssue(rewardInfo, daoId, token, currentRound);

        uint256[] memory activeRounds = rewardInfo.activeRounds;

        // enumerate all active rounds, not including current round
        uint256 j = rewardInfo.canvasCreatorClaimableRoundIndexes[canvasId];
        for (; j < activeRounds.length && activeRounds[j] < currentRound;) {
            if (rewardInfo.totalWeights[activeRounds[j]] == 0) {
                unchecked {
                    ++j;
                }
                continue;
            }
            // given a past active round, get round reward
            uint256 roundReward = getRoundReward(daoId, activeRounds[j], token);
            // update dao creator's claimable reward
            claimableERC20Reward += roundReward * rewardInfo.canvasCreatorWeights[activeRounds[j]][canvasId]
                / rewardInfo.totalWeights[activeRounds[j]];

            roundReward = getRoundReward(daoId, activeRounds[j], address(0));

            claimableETHReward += roundReward * rewardInfo.canvasCreatorWeightsETH[activeRounds[j]][canvasId]
                / rewardInfo.totalWeights[activeRounds[j]];
            unchecked {
                ++j;
            }
        }
        rewardInfo.canvasCreatorClaimableRoundIndexes[canvasId] = j;

        if (claimableERC20Reward > 0) D4AERC20(token).transfer(canvasCreator, claimableERC20Reward);
        if (claimableETHReward > 0) {
            (bool succ,) = canvasCreator.call{ value: claimableETHReward }("");
            require(succ, "transfer eth failed");
        }

        // claimableERC20Reward = _claimCanvasCreatorReward(daoId, canvasId, canvasCreator, currentRound, token);
        // claimableETHReward = _claimCanvasCreatorReward(daoId, canvasId, canvasCreator, currentRound, address(0));
    }

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 currentRound,
        address token
    )
        public
        payable
        returns (uint256 claimableERC20Reward, uint256 claimableETHReward)
    {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        //_updateRewardRoundAndIssue(rewardInfo, daoId, token, currentRound);

        uint256[] memory activeRounds = rewardInfo.activeRounds;
        bool topUpMode = BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode;
        // enumerate all active rounds, not including current round
        uint256 j = rewardInfo.nftMinterClaimableRoundIndexes[nftMinter];
        for (; j < activeRounds.length && activeRounds[j] < currentRound;) {
            if (rewardInfo.totalWeights[activeRounds[j]] == 0) {
                unchecked {
                    ++j;
                }
                continue;
            }
            uint256 roundReward = getRoundReward(daoId, activeRounds[j], token);
            claimableERC20Reward += roundReward * rewardInfo.nftMinterWeights[activeRounds[j]][nftMinter]
                / rewardInfo.totalWeights[activeRounds[j]];

            if (!topUpMode) {
                roundReward = getRoundReward(daoId, activeRounds[j], address(0));
                claimableETHReward += roundReward * rewardInfo.nftMinterWeightsETH[activeRounds[j]][nftMinter]
                    / rewardInfo.totalWeights[activeRounds[j]];
            } else {
                //handle topup eth
                claimableETHReward += rewardInfo.topUpInvestorPendingETH[activeRounds[j]][nftMinter];
            }
            unchecked {
                ++j;
            }
        }
        rewardInfo.nftMinterClaimableRoundIndexes[nftMinter] = j;
        if (!topUpMode) {
            if (claimableERC20Reward > 0) D4AERC20(token).transfer(nftMinter, claimableERC20Reward);
            if (claimableETHReward > 0) {
                (bool succ,) = nftMinter.call{ value: claimableETHReward }("");
                require(succ, "transfer eth failed");
            }
        } else {
            //同一family享用同一个redeem池子
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].topUpInvestorETHQuota[nftMinter]
            += claimableETHReward;
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].topUpInvestorERC20Quota[nftMinter]
            += claimableERC20Reward;
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

    function _getLastActiveRound(
        RewardStorage.RewardInfo storage rewardInfo,
        uint256 round
    )
        internal
        view
        returns (uint256)
    {
        uint256[] storage activeRounds = rewardInfo.activeRounds;
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

    function _distributeRoundReward(bytes32 daoId, uint256 amount, address token, uint256 round) internal {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        if (!basicDaoInfo.topUpMode) {
            bytes32[] memory children = IPDProtocolReadable(address(this)).getDaoChildren(daoId);
            uint256[] memory childrenDaoRatio = token == address(0)
                ? IPDProtocolReadable(address(this)).getDaoChildrenRatiosETH(daoId)
                : IPDProtocolReadable(address(this)).getDaoChildrenRatiosERC20(daoId);
            //address daoAssetPool = basicDaoInfo.daoAssetPool;
            for (uint256 i = 0; i < children.length;) {
                address desPool = IPDProtocolReadable(address(this)).getDaoAssetPool(children[i]);
                uint256 distrbuteAmount = amount * childrenDaoRatio[i] / BASIS_POINT;
                if (childrenDaoRatio[i] > 0) {
                    D4AFeePool(payable(basicDaoInfo.daoAssetPool)).transfer(token, payable(desPool), distrbuteAmount);
                    emit DaoBlockRewardDistributedToChildrenDao(daoId, children[i], token, distrbuteAmount, round);
                }
                unchecked {
                    ++i;
                }
            }

            if (token == address(0)) {
                uint256 redeemPoolRatio = IPDProtocolReadable(address(this)).getDaoRedeemPoolRatioETH(daoId);
                if (redeemPoolRatio > 0) {
                    uint256 distributeAmount = amount * redeemPoolRatio / BASIS_POINT;
                    D4AFeePool(payable(basicDaoInfo.daoAssetPool)).transfer(
                        token, payable(daoInfo.daoFeePool), distributeAmount
                    );
                    emit DaoBlockRewardDistributedToRedeemPool(
                        daoId, daoInfo.daoFeePool, token, distributeAmount, round
                    );
                }
            }
            uint256 selfRewardRatio = token == address(0)
                ? IPDProtocolReadable(address(this)).getDaoSelfRewardRatioETH(daoId)
                : IPDProtocolReadable(address(this)).getDaoSelfRewardRatioERC20(daoId);
            if (selfRewardRatio > 0) {
                uint256 selfRewardAmount = amount * selfRewardRatio / BASIS_POINT;
                D4AFeePool(payable(basicDaoInfo.daoAssetPool)).transfer(token, payable(address(this)), selfRewardAmount);
                emit DaoBlockRewardForSelf(daoId, token, selfRewardAmount, round);
                if (token != address(0)) {
                    rewardInfo.selfRoundERC20Reward[round] = selfRewardAmount;
                    PoolStorage.layout().poolInfos[daoInfo.daoFeePool].circulateERC20Amount += selfRewardAmount;
                } else {
                    rewardInfo.selfRoundETHReward[round] = selfRewardAmount;
                }
            }
        } else {
            rewardInfo.selfRoundERC20Reward[round] = amount;
            PoolStorage.layout().poolInfos[daoInfo.daoFeePool].circulateERC20Amount += amount;
            D4AFeePool(payable(basicDaoInfo.daoAssetPool)).transfer(token, payable(address(this)), amount);
            emit DaoBlockRewardForSelf(daoId, token, amount, round);
            if (basicDaoInfo.daoAssetPool.balance > 0) {
                D4AFeePool(payable(basicDaoInfo.daoAssetPool)).transfer(
                    address(0), payable(daoInfo.daoFeePool), basicDaoInfo.daoAssetPool.balance
                );
            }
        }
    }
}
