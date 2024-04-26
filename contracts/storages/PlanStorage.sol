// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { PlanTemplateType } from "contracts/interface/D4AEnums.sol";

library PlanStorage {
    struct PlanInfo {
        bytes32 daoId;
        uint256 startBlock;
        uint256 duration;
        uint256 totalRounds;
        uint256 totalReward;
        address rewardToken;
        bool io; //false for incentivizing input token, true for output token
        bool planExist;
        PlanTemplateType planTemplateType;
        address owner;
        uint256 cumulatedReward;
        uint256 lastUpdateRound;
        uint256 cumulatedRewardPerToken;
        mapping(uint256 => uint256) roundRewardPerToken;
        //account info
        mapping(bytes32 => uint256) accountLastUpdateRound;
        mapping(bytes32 => uint256) accountCumulatedRewardPerToken;
        mapping(bytes32 => uint256) accountCumulatedReward;
        mapping(bytes32 => uint256) accountClaimedReward;
    }

    struct Layout {
        mapping(bytes32 PlanId => PlanInfo) planInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("SemiOS.contracts.storage.PlanStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
