// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library RewardStorage {
    struct RewardInfo {
        uint256 decayFactor;
        uint256 totalReward;
        uint256 lastActiveRound;
        uint256[] activeRounds;
        mapping(uint256 round => uint256 totalWeight) totalWeights;
        mapping(uint256 round => mapping(address daoCreator => uint256 weight)) daoCreatorWeights;
        mapping(uint256 round => mapping(address canvasCreator => uint256 weight)) canvasCreatorWeights;
        mapping(uint256 round => mapping(address nftMinter => uint256 weight)) nftMinterWeights;
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
