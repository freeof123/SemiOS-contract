// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library RewardStorage {
    // struct RewardCheckpoint {
    //     uint256 startRound;
    //     uint256 totalRound;
    //     uint256 totalReward;
    //     uint256 lastActiveRound; // deprecated
    //     uint256[] activeRounds;
    //     // claimable round index
    //     uint256 daoCreatorClaimableRoundIndex;
    //     mapping(bytes32 canvasId => uint256 claimableRoundIndex) canvasCreatorClaimableRoundIndexes;
    //     mapping(address nftMinter => uint256 claimableRoundIndex) nftMinterClaimableRoundIndexes;
    // }

    struct RewardInfo {
        //RewardCheckpoint[] rewardCheckpoints;
        uint256 rewardIssuePendingRound;
        uint256 rewardDecayFactor;
        bool isProgressiveJackpot;
        // weights for erc20
        mapping(uint256 round => uint256 totalWeight) totalWeights; // also total ETH in DAO fee pool at given round
        mapping(uint256 round => uint256 weight) protocolWeights;
        mapping(uint256 round => uint256 weight) daoCreatorWeights;
        mapping(uint256 round => mapping(bytes32 canvasId => uint256 weight)) canvasCreatorWeights;
        mapping(uint256 round => mapping(address nftMinter => uint256 weight)) nftMinterWeights;
        uint256 daoCreatorERC20RatioInBps;
        uint256 canvasCreatorERC20RatioInBps;
        //1.3add ------------------------------------
        uint256[] activeRounds;
        mapping(uint256 ronud => uint256 amount) selfRoundERC20Reward;
        mapping(uint256 ronud => uint256 amount) selfRoundETHReward;
        // weights for eth
        mapping(uint256 round => uint256 weight) protocolWeightsETH;
        mapping(uint256 round => uint256 weight) daoCreatorWeightsETH;
        mapping(uint256 round => mapping(bytes32 canvasId => uint256 weight)) canvasCreatorWeightsETH;
        mapping(uint256 round => mapping(address nftMinter => uint256 weight)) nftMinterWeightsETH;
        uint256 daoCreatorClaimableRoundIndex;
        mapping(bytes32 canvasId => uint256 claimableRoundIndex) canvasCreatorClaimableRoundIndexes;
        mapping(address nftMinter => uint256 claimableRoundIndex) nftMinterClaimableRoundIndexes;
        mapping(uint256 round => mapping(address investor => uint256 amount)) topUpInvestorPendingETH;
        //1.5add -------------------------------------
        mapping(uint256 round => mapping(bytes32 nftHash => uint256 weight)) nftTopUpInvestorWeights;
        mapping(uint256 round => mapping(bytes32 nftHash => uint256 amount)) nftTopUpInvestorPendingETH;
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
