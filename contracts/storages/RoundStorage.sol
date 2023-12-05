// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library RoundStorage {
    struct RoundInfo {
        uint256 roundInLastModify;
        uint256 blockInLastModify;
        uint256 roundDuration;
    }

    struct Layout {
        mapping(bytes32 daoId => RoundInfo) roundInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.RoundStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
