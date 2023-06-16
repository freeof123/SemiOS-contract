// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library RewardStorage {
    struct RewardInfo {
        uint256 totalReward;
        uint256 totalWeight;
        mapping(address account => uint256 weight) weights;
        uint256 canvasCreatorERC20RatioInBps;
        uint256 nftMinterERC20RatioInBps;
    }

    struct Layout {
        mapping(bytes32 daoId => RewardInfo rewardInfo) rewardInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.RewardStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
