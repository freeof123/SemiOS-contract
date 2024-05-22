// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library RewardStorage {
    struct RewardInfo {
        uint256 rewardIssuePendingRound;
        uint256 rewardDecayFactor;
        bool isProgressiveJackpot;
        // weights for output
        mapping(uint256 round => uint256 totalWeight) totalWeights; // also total input in DAO fee pool at given round
        mapping(uint256 round => uint256 weight) protocolOutputWeight;
        mapping(uint256 round => uint256 weight) daoCreatorOutputWeights;
        mapping(uint256 round => mapping(bytes32 canvasId => uint256 weight)) canvasCreatorOutputWeights;
        mapping(uint256 round => mapping(address nftMinter => uint256 weight)) nftMinterOutputWeights;
        //1.3add ------------------------------------
        uint256[] activeRounds;
        mapping(uint256 ronud => uint256 amount) selfRoundOutputReward;
        mapping(uint256 ronud => uint256 amount) selfRoundInputReward;
        // weights for input
        mapping(uint256 round => uint256 weight) protocolInputWeight;
        mapping(uint256 round => uint256 weight) daoCreatorInputWeights;
        mapping(uint256 round => mapping(bytes32 canvasId => uint256 weight)) canvasCreatorInputWeights;
        mapping(uint256 round => mapping(address nftMinter => uint256 weight)) nftMinterInputWeights;
        uint256 daoCreatorClaimableRoundIndex;
        mapping(bytes32 canvasId => uint256 claimableRoundIndex) canvasCreatorClaimableRoundIndexes;
        mapping(address nftMinter => uint256 claimableRoundIndex) nftMinterClaimableRoundIndexes;
        //1.5 add -------------------------------------
        mapping(uint256 round => mapping(bytes32 nftHash => uint256 weight)) nftTopUpInvestorWeights;
        mapping(uint256 round => mapping(bytes32 nftHash => uint256 amount)) nftTopUpInvestorPendingInput;
        mapping(bytes32 nftHash => uint256 amount) nftTopUpClaimableRoundIndexes;
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
