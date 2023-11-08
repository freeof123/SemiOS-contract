// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library InheritTreeStorage {
    struct InheritTreeInfo {
        bytes32[] parents;
        bytes32[] children;
        bytes32[] familyDaos;
        bytes32 ancestor;
        bool isAncestorDao;
        uint256[] childrenDaoRatiosERC20;
        uint256[] childrenDaoRatiosETH;
        //uint256 redeemPoolRatioERC20;//dao token 不会去到redeem pool
        uint256 redeemPoolRatioETH;
        uint256 selfRewardRatioERC20;
        uint256 selfRewardRatioETH;
        //mint fee ratio
        uint256 canvasCreatorMintFeeRatio;
        uint256 assetPoolMintFeeRatio;
        uint256 redeemPoolMintFeeRatio;
        // also have l.protocolMintFeeRatioInBps
        uint256 canvasCreatorMintFeeRatioFiatPrice;
        uint256 assetPoolMintFeeRatioFiatPrice;
        uint256 redeemPoolMintFeeRatioFiatPrice;
        // also have l.protocolMintFeeRatioInBps

        //erc20 reward ratio
        uint256 minterERC20RewardRatio;
        uint256 canvasCreatorERC20RewardRatio;
        uint256 daoCreatorERC20RewardRatio;
        // also have l.protocolERC20RatioInBps,

        //eth reward ratio
        uint256 minterETHRewardRatio;
        uint256 canvasCreatorETHRewardRatio;
        uint256 daoCreatorETHRewardRatio;
    }
    // also have l.protocolETHRewardRatio

    struct Layout {
        mapping(bytes32 daoId => InheritTreeInfo inheritTreeInfo) inheritTreeInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.InheritTreeStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
