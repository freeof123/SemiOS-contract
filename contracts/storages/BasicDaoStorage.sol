// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library BasicDaoStorage {
    struct BasicDaoInfo {
        bool unlocked;
        bytes32 canvasIdOfSpecialNft;
        uint256 tokenId;
        uint256 roundMintCap;
        uint256 reserveNftNumber;
        bool unifiedPriceModeOff;
        uint256 unifiedPrice;
        //---------1.3 add
        bool exist;
        address daoAssetPool;
        bool isThirdPartyToken;
        bool topUpMode;
        bool needMintableWork;
        uint8 version;
        //---------1.4 add
        bool infiniteMode;
        bool outputPaymentMode;
        //---------1.6 add
        uint256 topUpInputToRedeemPoolRatio;
        uint256 topUpOutputToTreasuryRatio;
        address grantAssetPoolNft;
    }

    struct Layout {
        mapping(bytes32 daoId => BasicDaoInfo basicDaoInfo) basicDaoInfos;
        string specialTokenUriPrefix;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.BasicDaoStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
