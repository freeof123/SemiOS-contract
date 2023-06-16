// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library CanvasStorage {
    struct CanvasInfo {
        address owner;
        bytes32 daoId;
        string canvasUri;
        uint256 nftCount;
    }

    struct Layout {
        mapping(bytes32 canvasId => CanvasInfo canvasInfo) canvasInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.CanvasStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
