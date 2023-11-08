// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library BasicDaoStorage {
    struct BasicDaoInfo {
        bool unlocked;
        bytes32 canvasIdOfSpecialNft;
        uint256 tokenId;
        uint256 dailyMintCap;
        uint256 reserveNftNumber;
        bool unifiedPriceModeOff;
        uint256 unifiedPrice;
        //---------1.3 add
        bool exist;
        address daoAssetPool;
        address daoFundingPool;
        bool isThirdPartyToken;
        bool topUpMode;
        uint8 version;
    }

    struct Layout {
        mapping(bytes32 daoId => BasicDaoInfo basicDaoInfo) basicDaoInfos;
        string specialTokenUriPrefix;
        uint256 basicDaoNftFlatPrice;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.BasicDaoStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
