// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { PlanTemplateType } from "contracts/interface/D4AEnums.sol";
import { NftIdentifier } from "contracts/interface/D4AStructs.sol";

interface IPDPlan {
    event NewSemiOsPlan(
        bytes32 planId,
        bytes32 daoId,
        uint256 startBlock,
        uint256 duration,
        uint256 totalRounds,
        uint256 totalReward,
        PlanTemplateType planTemplateType,
        bool io,
        address owner,
        bool useTreasury
    );
    event PlanTotalRewardAdded(bytes32 planId, uint256 amount, bool useTreasury);
    event PlanRewardClaimed(bytes32 planId, NftIdentifier nft, address owner, uint256 reward, address token);

    function createPlan(
        bytes32 daoId,
        uint256 startBlock,
        uint256 duration,
        uint256 totalRounds,
        uint256 totalReward,
        address rewardToken,
        bool useTreasury,
        bool io,
        PlanTemplateType planTemplateType
    )
        external
        payable
        returns (bytes32 planId);
    function addTotalReward(bytes32 planId, uint256 amount, bool useTreasury) external;
    function claimMultiPlanReward(bytes32[] calldata planIds, NftIdentifier calldata nft) external returns (uint256);
    function claimDaoPlanReward(bytes32 daoId, NftIdentifier calldata nft) external returns (uint256);
    function deletePlan(bytes32 planId) external;

    function updateTopUpAccount(
        bytes32 daoId,
        NftIdentifier memory nft
    )
        external
        returns (uint256 topUPERC20Quota, uint256 topUpETHQuota);

    function updateMultiTopUpAccount(bytes32 daoId, NftIdentifier[] calldata nfts) external;
}
