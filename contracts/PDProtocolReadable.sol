// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ProtocolStorage } from "contracts/storages/ProtocolStorage.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";

contract PDProtocolReadable is IPDProtocolReadable, D4AProtocolReadable {
    // protocol related functions
    function getNFTTokenCanvas(bytes32 daoId, uint256 tokenId) public view returns (bytes32) {
        return ProtocolStorage.layout().nftHashToCanvasId[keccak256(abi.encodePacked(daoId, tokenId))];
    }

    function getLastestDaoIndex() public view returns (uint256) {
        return ProtocolStorage.layout().daoIndex;
    }

    function getDaoId(uint256 daoIndex) public view returns (bytes32) {
        return ProtocolStorage.layout().daoIndexToId[daoIndex];
    }
}
