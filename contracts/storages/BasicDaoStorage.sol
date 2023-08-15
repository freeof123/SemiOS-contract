// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library BasicDaoStorage {
    struct Layout {
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
