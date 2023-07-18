// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocol } from "contracts/interface/ID4AProtocol.sol";

contract D4AUniversalClaimer {
    error InvalidId();

    address[] public protocols;
    mapping(bytes32 id => address protocol) public protocolMap;

    constructor(address[] memory protocols_) {
        protocols = protocols_;
    }

    function claimMultiReward(
        bytes32[] calldata canvasIds,
        bytes32[] calldata daoIds
    )
        public
        returns (uint256 tokenAmount)
    {
        address protocol;
        for (uint256 i; i < canvasIds.length;) {
            protocol = _findAndRegister(canvasIds[i]);
            tokenAmount += ID4AProtocol(protocol).claimCanvasReward(canvasIds[i]);
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < daoIds.length;) {
            protocol = _findAndRegister(daoIds[i]);
            tokenAmount += ID4AProtocol(protocol).claimProjectERC20Reward(daoIds[i]);
            tokenAmount += ID4AProtocol(protocol).claimNftMinterReward(daoIds[i], msg.sender);
            unchecked {
                ++i;
            }
        }
        return tokenAmount;
    }

    function _findAndRegister(bytes32 id) internal returns (address) {
        if (protocolMap[id] == address(0)) {
            uint256 length = protocols.length;
            for (uint256 i; i < length;) {
                if (
                    ID4AProtocolReadable(protocols[i]).getDaoExist(id)
                        || ID4AProtocolReadable(protocols[i]).getCanvasExist(id)
                ) {
                    protocolMap[id] = protocols[i];
                    return protocols[i];
                }
                unchecked {
                    ++i;
                }
            }
            revert InvalidId();
        } else {
            return protocolMap[id];
        }
    }
}
