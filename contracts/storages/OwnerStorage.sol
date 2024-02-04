// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";

library OwnerStorage {
    struct DaoOwnerInfo {
        NftIdentifier daoEditInformationOwner;
        NftIdentifier daoEditParameterOwner;
        NftIdentifier daoEditStrategyOwner;
        NftIdentifier daoRewardOwner;
    }

    struct TreasuryOwnerInfo {
        NftIdentifier treasuryEditInformationOwner;
        NftIdentifier treasuryTransferAssetOwner;
        NftIdentifier treasurySetTopUpRatioOwner;
    }

    struct Layout {
        mapping(bytes32 daoId => DaoOwnerInfo ownerInfo) daoOwnerInfos;
        mapping(address pool => TreasuryOwnerInfo ownerInfo) treasuryOwnerInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("SemiosV1.contracts.storage.OwnerStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
