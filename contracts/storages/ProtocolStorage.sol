// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ProtocolStorage {
    struct Layout {
        mapping(bytes32 => bytes32) nftHashToCanvasId;
        mapping(bytes32 => bool) uriExists;
        uint256 daoIndex;
        uint256 daoIndexBitMap;
        mapping(uint256 daoIndex => bytes32 daoId) daoIndexToId;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.ProtocolStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
