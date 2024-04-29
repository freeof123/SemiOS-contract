// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/interface/D4AErrors.sol";

import { PlanStorage } from "contracts/storages/PlanStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IPlanTemplate } from "contracts/interface/IPlanTemplate.sol";
import { IRewardTemplate } from "./interface/IRewardTemplate.sol";
import { IPDRound } from "contracts/interface/IPDRound.sol";

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";

//import "forge-std/Test.sol";

abstract contract PlanUpdater {
    event TopUpAccountUpdated(bytes32 daoId, NftIdentifier nft);

    function _updatePlanReward(bytes32 planId, bytes32 nftHash, bytes memory data) internal {
        PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
        (bool succ,) = SettingsStorage.layout().planTemplates[uint8(planInfo.planTemplateType)].delegatecall(
            abi.encodeCall(IPlanTemplate.updateReward, (planId, nftHash, data))
        );
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _updateAllPlans(bytes32 daoId, bytes32 nftHash, bytes memory data) internal {
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        bytes32[] storage allPlans = poolInfo.allPlans;
        for (uint256 i = 0; i < allPlans.length;) {
            _updatePlanReward(allPlans[i], nftHash, data);
            unchecked {
                ++i;
            }
        }
    }

    function _afterUpdate(bytes32 planId, bytes32 nftHash, bytes memory data) internal {
        PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
        (bool succ,) = SettingsStorage.layout().planTemplates[uint8(planInfo.planTemplateType)].delegatecall(
            abi.encodeCall(IPlanTemplate.afterUpdate, (planId, nftHash, data))
        );

        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _afterUpdateAll(bytes32 daoId, bytes32 nftHash, bytes memory data) internal {
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        bytes32[] storage allPlans = poolInfo.allPlans;
        for (uint256 i = 0; i < allPlans.length;) {
            _afterUpdate(allPlans[i], nftHash, data);
            unchecked {
                ++i;
            }
        }
    }

    function _updateTopUpAccount(bytes32 daoId, NftIdentifier memory nft) internal returns (uint256, uint256) {
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];

        bytes32[] memory investedTopUpDaos = poolInfo.nftInvestedTopUpDaos[_nftHash(nft)];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        for (uint256 i; i < investedTopUpDaos.length;) {
            (bool succ,) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
                abi.encodeCall(
                    IRewardTemplate.claimNftTopUpBalance,
                    (
                        investedTopUpDaos[i],
                        _nftHash(nft),
                        IPDRound(address(this)).getDaoCurrentRound(investedTopUpDaos[i])
                    )
                )
            );
            require(succ, "delegate call failed");

            unchecked {
                ++i;
            }
        }
        emit TopUpAccountUpdated(daoId, nft);
        return (poolInfo.topUpNftErc20[_nftHash(nft)], poolInfo.topUpNftEth[_nftHash(nft)]);
    }

    function _nftHash(NftIdentifier memory nft) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nft.erc721Address, nft.tokenId));
    }
}
