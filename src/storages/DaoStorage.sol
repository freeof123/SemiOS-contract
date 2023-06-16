// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library DaoStorage {
    struct DaoMetadata {
        uint256 startDrb;
        uint256 index;
        string daoUri;
        address daoFeePool;
        address priceTemplate;
        address rewardTemplate;
    }

    struct RoyaltyTokenInfo {
        address token;
        uint256 hardCap;
    }

    struct NftCollectionInfo {
        address token;
        uint256 floorPrice;
        uint256 priceMultiplier;
        uint256 mintCap;
    }

    struct DaoInfo {
        DaoMetadata daoMetadata;
        RoyaltyTokenInfo royaltyTokenInfo;
        NftCollectionInfo nftCollectionInfo;
        bool exist; // TODO: Is this necessary?
        bool isPaused;
        address owner;
        address[] canvases;
        uint256 mintableRounds;
        uint256 daoFeePoolETHRatioInBps;
        uint256 daoFeePoolETHRatioInBpsFlatPrice;
    }

    struct Layout {
        mapping(bytes32 daoId => DaoInfo daoInfo) daoInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.DaoStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
