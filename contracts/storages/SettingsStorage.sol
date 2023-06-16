// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SettingsStorage {
    struct Layout {
        bool isProtocolPaused;
        uint256 maxDaoMintableRounds;
        uint96 minRoyaltyFeeInBps;
        uint96 maxRoyaltyFeeInBps;
        uint256 createDaoFee;
        address protocolFeePool;
        address royaltyTokenFactory;
        address nftCollectionFactory;
        address daoFeePoolFactory;
        address royaltySplitterFactory;
        address assetAdmin; // TODO: called asset_pool_owner in D4A v1, what is this role? Is is the same as
            // the OPERATION ROLE?
        uint256 maxRoyaltyTokenSupply;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.SettingsStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
