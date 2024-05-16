// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { IPlanTemplate } from "contracts/interface/IPlanTemplate.sol";
import { UpdateRewardParam, NftIdentifier } from "contracts/interface/D4AStructs.sol";
import { BASIS_POINT, ETHERSQUARE } from "contracts/interface/D4AConstants.sol";
import { ExceedMaxMintableRound, InvalidRound } from "contracts/interface/D4AErrors.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { PlanStorage } from "contracts/storages/PlanStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";

import { D4AERC20 } from "contracts/D4AERC20.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";

import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";

import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
//import "forge-std/Test.sol";

contract DynamicPlan is IPlanTemplate {
    function updateReward(bytes32 planId, bytes32 nftHash, bytes memory data) public payable {
        PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];

        uint256 round = _getPlanCurrentRound(planInfo);
        if (round == 0) {
            return;
        }
        _updateRewardPerTokenCumulated(planInfo, round);
        if (nftHash != bytes32(0)) {
            _updateAccountRewardCumulated(planInfo, round, nftHash);
        }
    }

    function afterUpdate(bytes32 planId, bytes32 nftHash, bytes memory data) public {
        return;
    }

    function claimReward(
        bytes32 planId,
        bytes32 nftHash,
        address owner,
        bytes memory data
    )
        public
        returns (uint256 reward)
    {
        PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
        updateReward(planId, nftHash, hex"");
        if (planInfo.accountClaimedReward[nftHash] < planInfo.accountCumulatedReward[nftHash]) {
            reward = planInfo.accountCumulatedReward[nftHash] - planInfo.accountClaimedReward[nftHash];
            planInfo.accountClaimedReward[nftHash] = planInfo.accountCumulatedReward[nftHash];
            _transferInputToken(planInfo.rewardToken, owner, reward);
        }
    }

    function _updateRewardPerTokenCumulated(PlanStorage.PlanInfo storage planInfo, uint256 round) internal {
        uint256 totalStake = !planInfo.io
            ? PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool].totalStakeEth
            : PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool].totalStakeErc20;
        if (round > planInfo.lastUpdateRound + 1) {
            uint256 rewardPerRound =
                (planInfo.totalReward - planInfo.cumulatedReward) / (planInfo.totalRounds - planInfo.lastUpdateRound);
            if (totalStake != 0) {
                uint256 incomeReward = (round - planInfo.lastUpdateRound - 1) * rewardPerRound;
                planInfo.cumulatedReward += incomeReward;
                planInfo.cumulatedRewardPerToken += incomeReward * ETHERSQUARE / totalStake;
            }
            planInfo.lastUpdateRound = round - 1;
        }
    }

    function _updateAccountRewardCumulated(
        PlanStorage.PlanInfo storage planInfo,
        uint256 round,
        bytes32 nftHash
    )
        internal
    {
        uint256 accountBalance = !planInfo.io
            ? PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool].topUpNftEth[nftHash]
            : PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool].topUpNftErc20[nftHash];

        if (round > planInfo.accountLastUpdateRound[nftHash] + 1) {
            planInfo.accountCumulatedReward[nftHash] += accountBalance
                * (planInfo.cumulatedRewardPerToken - planInfo.accountCumulatedRewardPerToken[nftHash]) / ETHERSQUARE;
            planInfo.accountCumulatedRewardPerToken[nftHash] = planInfo.cumulatedRewardPerToken;
            planInfo.accountLastUpdateRound[nftHash] = round - 1;
        }
    }

    function _getPlanCurrentRound(PlanStorage.PlanInfo storage planInfo) internal view returns (uint256 round) {
        if (block.number < planInfo.startBlock) {
            return 0;
        }
        round = (block.number - planInfo.startBlock) / planInfo.duration + 1;
        if (round > planInfo.totalRounds) {
            round = planInfo.totalRounds + 1;
        }
    }

    function _transferInputToken(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            SafeTransferLib.safeTransferETH(to, amount);
        } else {
            SafeTransferLib.safeTransfer(token, to, amount);
        }
    }
}
