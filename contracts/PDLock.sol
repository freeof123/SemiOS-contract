// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/interface/D4AErrors.sol";
import { ProtocolStorage } from "contracts/storages/ProtocolStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { PDProtocol } from "contracts/PDProtocol.sol";
import { IPDLock } from "contracts/interface/IPDLock.sol";

contract PDLock is IPDLock {
    function lockTopUpNFT(NftIdentifier calldata nft, uint256 duration) public {
        if (msg.sender != IERC721(nft.erc721Address).ownerOf(nft.tokenId)) {
            revert NotNftOwner();
        }
        ProtocolStorage.Layout storage protocolInfo = ProtocolStorage.layout();
        //nft hash
        if (checkTopUpNftLockedStatus(nft)) revert TopUpNftHadLocked();

        protocolInfo.lockedInfo[_nftHash(nft)].lockStartBlock = block.number;
        protocolInfo.lockedInfo[_nftHash(nft)].duration = duration;
        emit TopUpNftLock(nft, block.number, duration);
    }

    function checkTopUpNftLockedStatus(NftIdentifier calldata nft) public view returns (bool locked) {
        ProtocolStorage.Layout storage protocolInfo = ProtocolStorage.layout();
        if (
            protocolInfo.lockedInfo[_nftHash(nft)].lockStartBlock + protocolInfo.lockedInfo[_nftHash(nft)].duration
                < block.number
        ) {
            return false;
        }
        return true;
    }

    function getTopUpNftLockedInfo(NftIdentifier calldata nft)
        public
        view
        returns (uint256 lockStartTime, uint256 duration)
    {
        ProtocolStorage.Layout storage protocolInfo = ProtocolStorage.layout();
        lockStartTime = protocolInfo.lockedInfo[_nftHash(nft)].lockStartBlock;
        duration = protocolInfo.lockedInfo[_nftHash(nft)].duration;
    }

    function _nftHash(NftIdentifier memory nft) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nft.erc721Address, nft.tokenId));
    }
}
