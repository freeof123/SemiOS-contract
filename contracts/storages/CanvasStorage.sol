// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import { PriceTemplateType, RewardTemplateType } from "../interface/D4AEnums.sol";
import { DaoMintInfo } from "contracts/interface/D4AStructs.sol";

library CanvasStorage {
    struct CanvasInfo {
        bytes32 daoId;
        uint256[] tokenIds;
        uint256 index;
        string canvasUri;
        bool canvasExist;
        uint256 canvasRebateRatioInBps;
    }

    struct Layout {
        mapping(bytes32 canvasId => CanvasInfo) canvasInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.CanvasStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
