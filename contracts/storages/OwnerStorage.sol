// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";

library OwnerStorage {
    struct Layout {
        mapping(bytes32 => NftIdentifier) ownerControlForDaoEditInformation;
        mapping(bytes32 => NftIdentifier) ownerControlForDaoEditParameter;
        mapping(bytes32 => NftIdentifier) ownerControlForDaoEditStrategy;
        mapping(bytes32 => NftIdentifier) ownerControlForDaoReward;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("SemiosV1.contracts.storage.OwnerStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
