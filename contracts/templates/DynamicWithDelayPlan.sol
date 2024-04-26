// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { IPlanTemplate } from "contracts/interface/IPlanTemplate.sol";
import { UpdateRewardParam, NftIdentifier } from "contracts/interface/D4AStructs.sol";
import { BASIS_POINT, ETHER } from "contracts/interface/D4AConstants.sol";
import { ExceedMaxMintableRound, InvalidRound } from "contracts/interface/D4AErrors.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { PlanStorage } from "contracts/storages/PlanStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";

import { D4AERC20 } from "contracts/D4AERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";

import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";

import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import "forge-std/Test.sol";

contract DynamicWithDelayPlan { //is IPlanTemplate {
// function updateReward(bytes32 planId, bytes32 nftHash, bytes memory data) public {
//     PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
//     uint256 round = _getPlanCurrentRound(planInfo);
//     if (round == 0) {
//         return;
//     }
//     console2.log("here");
//     _updateRewardPerTokenCumulated(planInfo, round);
//     if (nftHash != bytes32(0)) {
//         console2.log("here2");
//         _updateAccountRewardCumulated(planInfo, round, nftHash);
//     }
// }

// function afterUpdate(bytes32 planId, bytes32 nftHash, bytes memory data) public {
//     PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
//     (uint256 ethAmount, uint256 erc20Amount) = abi.decode(data, (uint256, uint256));
//     uint256 amount = !planInfo.io ? ethAmount : erc20Amount;
//     uint256 round = _getPlanCurrentRound(planInfo);
//     if (round <= planInfo.totalRounds) {
//         planInfo.roundEffectiveStake[round] -= amount;
//         planInfo.roundAccountEffectiveStake[round][nftHash] -= amount;
//     }
// }

// function claimReward(
//     bytes32 planId,
//     bytes32 nftHash,
//     address owner,
//     bytes memory data
// )
//     public
//     returns (uint256 reward)
// {
//     PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
//     updateReward(planId, nftHash, hex"");
//     if (planInfo.accountClaimedReward[nftHash] < planInfo.accountCumulatedReward[nftHash]) {
//         reward = planInfo.accountCumulatedReward[nftHash] - planInfo.accountClaimedReward[nftHash];
//         planInfo.accountClaimedReward[nftHash] = planInfo.accountCumulatedReward[nftHash];
//         _transferInputToken(planInfo.rewardToken, owner, reward);
//     }
// }

// function _updateRewardPerTokenCumulated(PlanStorage.PlanInfo storage planInfo, uint256 round) internal {
//     console2.log("updateRewardPerTokenCumulated", round);
//     uint256 totalStake = !planInfo.io
//         ? PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool].totalStakeEth
//         : PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool].totalStakeErc20;
//     if (round > planInfo.lastUpdateRound + 1) {
//         uint256 rewardPerRound =
//             (planInfo.totalReward - planInfo.cumulatedReward) / (planInfo.totalRounds - planInfo.lastUpdateRound);
//         //pending round equals last update reward round + 1;
//         if (planInfo.roundEffectiveStake[planInfo.lastUpdateRound + 1] != 0) {
//             uint256 pendingRoundRewardPerToken =
//                 rewardPerRound * ETHER / planInfo.roundEffectiveStake[planInfo.lastUpdateRound + 1];
//             planInfo.roundRewardPerToken[planInfo.lastUpdateRound + 1] = pendingRoundRewardPerToken;
//             planInfo.cumulatedRewardPerToken += pendingRoundRewardPerToken;
//             planInfo.cumulatedReward += rewardPerRound;
//         }
//         rewardPerRound = (planInfo.totalReward - planInfo.cumulatedReward)
//             / (planInfo.totalRounds - planInfo.lastUpdateRound - 1);
//         if (totalStake != 0) {
//             planInfo.cumulatedRewardPerToken +=
//                 (round - planInfo.lastUpdateRound - 1) * rewardPerRound * ETHER / totalStake;
//             planInfo.cumulatedReward += (round - planInfo.lastUpdateRound - 1) * rewardPerRound;
//         }
//         planInfo.lastUpdateRound = round - 1;
//     }
//     // handle pending, first time enter current round
//     if (round <= planInfo.totalRounds) {
//         if (round > planInfo.globalPendingRound) {
//             planInfo.globalPendingRound = round;
//             planInfo.roundEffectiveStake[round] = totalStake;
//         }
//     }
// }

// function _updateAccountRewardCumulated(
//     PlanStorage.PlanInfo storage planInfo,
//     uint256 round,
//     bytes32 nftHash
// )
//     internal
// {
//     uint256 accountBalance = !planInfo.io
//         ?
// PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool].topUpNftEth[nftHash]
//         :
// PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool].topUpNftErc20[nftHash];
//     if (round > planInfo.accountLastUpdateRound[nftHash] + 1) {
//         //pending round equals last update reward round + 1;
//         planInfo.accountCumulatedReward[nftHash] += planInfo.roundAccountEffectiveStake[planInfo
//             .accountLastUpdateRound[nftHash] + 1][nftHash]
//             * planInfo.roundRewardPerToken[planInfo.accountLastUpdateRound[nftHash] + 1] / ETHER;
//         planInfo.accountCumulatedRewardPerToken[nftHash] +=
//             planInfo.roundRewardPerToken[planInfo.accountLastUpdateRound[nftHash] + 1];
//         planInfo.accountCumulatedReward[nftHash] += accountBalance
//             * (planInfo.cumulatedRewardPerToken - planInfo.accountCumulatedRewardPerToken[nftHash]) / ETHER;
//         planInfo.accountCumulatedRewardPerToken[nftHash] = planInfo.cumulatedRewardPerToken;
//         planInfo.accountLastUpdateRound[nftHash] = round - 1;
//     }
//     if (round <= planInfo.totalRounds) {
//         if (round > planInfo.accountPendingRound[nftHash]) {
//             planInfo.accountPendingRound[nftHash] = round;
//             planInfo.roundAccountEffectiveStake[round][nftHash] = accountBalance;
//         }
//     }
// }

// function _getPlanCurrentRound(PlanStorage.PlanInfo storage planInfo) internal view returns (uint256 round) {
//     if (block.number < planInfo.startBlock) {
//         return 0;
//     }
//     round = (block.number - planInfo.startBlock) / planInfo.duration + 1;
//     if (round > planInfo.totalRounds) {
//         round = planInfo.totalRounds + 1;
//     }
// }

// function _transferInputToken(address token, address to, uint256 amount) internal {
//     if (token == address(0)) {
//         SafeTransferLib.safeTransferETH(to, amount);
//     } else {
//         SafeTransferLib.safeTransfer(token, to, amount);
//     }
// }
}
