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
        address daoFundingPool; //deprecated
        bool isThirdPartyToken;
        bool topUpMode;
        bool needMintableWork;
        uint8 version;
        //---------1.4 add
        bool infiniteMode;
        bool erc20PaymentMode;
        //---------1.6 add
        uint256 topUpEthToRedeemPoolRatio;
        uint256 topUpErc20ToTreasuryRatio;
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
