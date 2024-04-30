// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { NftIdentifier, CreatePlanParam } from "contracts/interface/D4AStructs.sol";

import { OPERATION_ROLE } from "contracts/interface/D4AConstants.sol";
import { NotPlanOwner, InvalidRewardTokenForTreasury } from "contracts/interface/D4AErrors.sol";

import { NotOperationRole, StartBlockAlreadyPassed, NotEnoughEther } from "contracts/interface/D4AErrors.sol";
import { IPDPlan } from "contracts/interface/IPDPlan.sol";
import { IPlanTemplate } from "contracts/interface/IPlanTemplate.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { RoundStorage } from "contracts/storages/RoundStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { InheritTreeStorage } from "contracts/storages/InheritTreeStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";
import { PlanStorage } from "contracts/storages/PlanStorage.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";

import { PlanTemplateType } from "contracts/interface/D4AEnums.sol";
import { SetterChecker } from "contracts/SetterChecker.sol";
import { PlanUpdater } from "contracts/PlanUpdater.sol";

contract PDPlan is IPDPlan, SetterChecker, PlanUpdater {
    function createPlan(CreatePlanParam calldata param) external payable returns (bytes32 planId) {
        if (param.useTreasury) {
            _checkTreasuryTransferAssetAbility(param.daoId);
            if (param.rewardToken != DaoStorage.layout().daoInfos[param.daoId].token) {
                revert InvalidRewardTokenForTreasury();
            }
            address treasury =
                PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[param.daoId].daoFeePool].treasury;
            D4AFeePool(payable(treasury)).transfer(
                DaoStorage.layout().daoInfos[param.daoId].token, payable(address(this)), param.totalReward
            );
        } else {
            if (param.rewardToken == address(0)) {
                if (msg.value < param.totalReward) revert NotEnoughEther();
            } else {
                IERC20(param.rewardToken).transferFrom(msg.sender, address(this), param.totalReward);
            }
        }
        {
            PoolStorage.PoolInfo storage poolInfo =
                PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[param.daoId].daoFeePool];
            bytes32[] storage allPlans = poolInfo.allPlans;
            planId = keccak256(
                abi.encodePacked(param.daoId, param.startBlock, param.duration, param.totalRounds, poolInfo.totalPlans)
            );
            allPlans.push(planId);
            poolInfo.totalPlans++;
            if (param.startBlock < block.number) {
                revert StartBlockAlreadyPassed();
            }
            PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
            planInfo.daoId = param.daoId;
            planInfo.startBlock = param.startBlock;
            planInfo.duration = param.duration;
            planInfo.totalRounds = param.totalRounds;
            planInfo.totalReward = param.totalReward;
            planInfo.rewardToken = param.rewardToken;
            planInfo.planTemplateType = param.planTemplateType;
            planInfo.owner = msg.sender;
            planInfo.io = param.io;
            planInfo.planExist = true;
        }
        emit NewSemiOsPlan(
            planId,
            param.daoId,
            param.startBlock,
            param.duration,
            param.totalRounds,
            param.totalReward,
            param.planTemplateType,
            param.io,
            msg.sender,
            param.useTreasury,
            param.uri
        );
    }

    function addPlanTotalReward(bytes32 planId, uint256 amount, bool useTreasury) external payable {
        PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
        require(planInfo.planExist, "plan not exist");
        (bool succ,) = SettingsStorage.layout().planTemplates[uint8(planInfo.planTemplateType)].delegatecall(
            abi.encodeCall(IPlanTemplate.updateReward, (planId, bytes32(0), hex""))
        );

        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        bytes32 daoId = planInfo.daoId;
        if (useTreasury) {
            _checkTreasuryTransferAssetAbility(daoId);
            address treasury = PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].treasury;
            if (planInfo.rewardToken != DaoStorage.layout().daoInfos[daoId].token) {
                revert InvalidRewardTokenForTreasury();
            }
            D4AFeePool(payable(treasury)).transfer(
                DaoStorage.layout().daoInfos[daoId].token, payable(address(this)), amount
            );
        } else {
            if (planInfo.rewardToken == address(0)) {
                if (msg.value < amount) revert NotEnoughEther();
            } else {
                IERC20(planInfo.rewardToken).transferFrom(msg.sender, address(this), amount);
            }
        }
        planInfo.totalReward += amount;
        emit PlanTotalRewardAdded(planId, amount, useTreasury);
    }

    function claimDaoPlanReward(bytes32 daoId, NftIdentifier calldata nft) public returns (uint256 amount) {
        address owner = IERC721(nft.erc721Address).ownerOf(nft.tokenId);
        bytes32 nftHash = _nftHash(nft);
        PlanStorage.PlanInfo storage planInfo;
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        bytes32[] storage allPlans = poolInfo.allPlans;
        for (uint256 i = 0; i < allPlans.length;) {
            _updatePlanReward(allPlans[i], nftHash, hex"");
            planInfo = PlanStorage.layout().planInfos[allPlans[i]];
            (bool succ, bytes memory data) = SettingsStorage.layout().planTemplates[uint8(planInfo.planTemplateType)]
                .delegatecall(abi.encodeCall(IPlanTemplate.claimReward, (allPlans[i], nftHash, owner, hex"")));
            if (!succ) {
                /// @solidity memory-safe-assembly
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
            amount += abi.decode(data, (uint256));

            emit PlanRewardClaimed(allPlans[i], nft, owner, abi.decode(data, (uint256)), planInfo.rewardToken);

            unchecked {
                ++i;
            }
        }
        _updateTopUpAccount(daoId, nft);
    }

    function claimDaoPlanRewardForMultiNft(
        bytes32 daoId,
        NftIdentifier[] calldata nft
    )
        external
        returns (uint256 amount)
    {
        for (uint256 i; i < nft.length;) {
            amount += claimDaoPlanReward(daoId, nft[i]);
            unchecked {
                ++i;
            }
        }
    }
    /// @dev This function does not auto update topup account

    function claimMultiPlanReward(
        bytes32[] calldata planIds,
        NftIdentifier calldata nft
    )
        external
        returns (uint256 amount)
    {
        //不自动挂账
        address owner = IERC721(nft.erc721Address).ownerOf(nft.tokenId);
        bytes32 nftHash = _nftHash(nft);
        PlanStorage.PlanInfo storage planInfo;
        for (uint256 i = 0; i < planIds.length;) {
            planInfo = PlanStorage.layout().planInfos[planIds[i]];
            require(planInfo.planExist, "plan not exist");
            _updatePlanReward(planIds[i], nftHash, hex"");

            (bool succ, bytes memory data) = SettingsStorage.layout().planTemplates[uint8(planInfo.planTemplateType)]
                .delegatecall(abi.encodeCall(IPlanTemplate.claimReward, (planIds[i], nftHash, owner, hex"")));

            if (!succ) {
                /// @solidity memory-safe-assembly
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
            amount += abi.decode(data, (uint256));

            emit PlanRewardClaimed(planIds[i], nft, owner, abi.decode(data, (uint256)), planInfo.rewardToken);
            unchecked {
                ++i;
            }
        }
    }

    function deletePlan(bytes32 planId) external {
        if (!IAccessControl(address(this)).hasRole(OPERATION_ROLE, msg.sender)) revert NotOperationRole();
        PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[planInfo.daoId].daoFeePool];
        bytes32[] storage allPlans = poolInfo.allPlans;

        uint256 length = allPlans.length;
        for (uint256 i; i < length;) {
            if (allPlans[i] == planId) {
                allPlans[i] = allPlans[length - 1];
                allPlans.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
        planInfo.planExist = false;
    }

    function updateTopUpAccount(bytes32 daoId, NftIdentifier memory nft) public returns (uint256, uint256) {
        _updateAllPlans(daoId, _nftHash(nft), hex"");
        return _updateTopUpAccount(daoId, nft);
    }

    function updateMultiTopUpAccount(bytes32 daoId, NftIdentifier[] calldata nfts) external {
        for (uint256 i; i < nfts.length;) {
            _updateAllPlans(daoId, _nftHash(nfts[i]), hex"");
            _updateTopUpAccount(daoId, nfts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getPlanCumulatedReward(bytes32 planId) public returns (uint256) {
        PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
        require(planInfo.planExist, "plan not exist");
        (bool succ,) = SettingsStorage.layout().planTemplates[uint8(planInfo.planTemplateType)].delegatecall(
            abi.encodeCall(IPlanTemplate.updateReward, (planId, bytes32(0), hex""))
        );

        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        return planInfo.cumulatedReward;
    }

    function retriveUnclaimedToken(bytes32 planId) public {
        PlanStorage.PlanInfo storage planInfo = PlanStorage.layout().planInfos[planId];
        require(planInfo.planExist, "plan not exist");
        if (msg.sender != planInfo.owner) revert NotPlanOwner();
        (bool succ,) = SettingsStorage.layout().planTemplates[uint8(planInfo.planTemplateType)].delegatecall(
            abi.encodeCall(IPlanTemplate.updateReward, (planId, bytes32(0), hex""))
        );
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        if (planInfo.lastUpdateRound == planInfo.totalRounds) {
            _transferInputToken(planInfo.rewardToken, msg.sender, planInfo.totalReward - planInfo.cumulatedReward);
        }
    }

    function getTopUpBalance(bytes32 daoId, NftIdentifier memory nft) public view returns (uint256, uint256) {
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        return (poolInfo.topUpNftEth[_nftHash(nft)], poolInfo.topUpNftErc20[_nftHash(nft)]);
    }

    function _transferInputToken(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            SafeTransferLib.safeTransferETH(to, amount);
        } else {
            SafeTransferLib.safeTransfer(token, to, amount);
        }
    }
}
