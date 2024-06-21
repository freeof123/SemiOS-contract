// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library TreeStorage {
    struct TreeInfo {
        bytes32[] parents;
        bytes32[] children;
        bytes32[] familyDaos;
        bytes32 ancestor;
        bool isAncestorDao;
        uint256[] childrenDaoOutputRatios;
        uint256[] childrenDaoInputRatios;
        //uint256 redeemPoolOutputRatio;//output token does not go to redeem pool
        uint256 redeemPoolInputRatio;
        uint256 selfRewardOutputRatio;
        uint256 selfRewardInputRatio;
        uint256 treasuryOutputRatio;
        uint256 treasuryInputRatio;
        //mint fee ratio
        uint256 canvasCreatorMintFeeRatio;
        uint256 assetPoolMintFeeRatio;
        uint256 redeemPoolMintFeeRatio;
        uint256 treasuryMintFeeRatio;
        // also have l.protocolMintFeeRatioInBps
        uint256 canvasCreatorMintFeeRatioFiatPrice;
        uint256 assetPoolMintFeeRatioFiatPrice;
        uint256 redeemPoolMintFeeRatioFiatPrice;
        uint256 treasuryMintFeeRatioFiatPrice;
        // also have l.protocolMintFeeRatioInBps

        //output token reward ratio
        uint256 minterOutputRewardRatio;
        uint256 canvasCreatorOutputRewardRatio;
        uint256 daoCreatorOutputRewardRatio;
        // also have l.protocolOutputRewardRatio,

        //input token reward ratio
        uint256 minterInputRewardRatio;
        uint256 canvasCreatorInputRewardRatio;
        uint256 daoCreatorInputRewardRatio;
    }
    // also have l.protocolInputRewardRatio

    struct Layout {
        mapping(bytes32 daoId => TreeInfo treeInfo) treeInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.TreeStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
