// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/interface/D4AErrors.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { PDProtocol } from "contracts/PDProtocol.sol";
import { IPDLock } from "contracts/interface/IPDLock.sol";

contract PDLock is IPDLock {
    function lockTopUpNFT(bytes32 daoId, NftIdentifier calldata nft, uint256 duration) public {
        if (msg.sender != IERC721(nft.erc721Address).ownerOf(nft.tokenId)) {
            revert NotNftOwner();
        }
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        //nft hash
        if (checkTopUpNftLockedStatus(daoId, nft)) revert TopUpNftHadLocked();

        poolInfo.lockedInfo[_nftHash(nft)].lockStartBlock = block.number;
        poolInfo.lockedInfo[_nftHash(nft)].duration = duration;
        emit TopUpNftLock(daoId, nft, block.number, duration);
    }

    function checkTopUpNftLockedStatus(bytes32 daoId, NftIdentifier calldata nft) public view returns (bool locked) {
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        if (
            poolInfo.lockedInfo[_nftHash(nft)].lockStartBlock + poolInfo.lockedInfo[_nftHash(nft)].duration
                < block.number
        ) {
            //_unstakeTopUpNFT(daoId, nft);
            return false;
        }
        return true;
    }

    // function _unstakeTopUpNFT(bytes32 daoId, NftIdentifier memory nft) internal {
    //     if (msg.sender != IERC721(nft.erc721Address).ownerOf(nft.tokenId)) {
    //         revert NotNftOwner();
    //     }
    //     PoolStorage.PoolInfo storage poolInfo =
    //         PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
    //     if (!poolInfo.lockedInfo[_nftHash(nft)].lockedStatus) return;
    //     if (
    //         poolInfo.lockedInfo[_nftHash(nft)].lockStartTime + poolInfo.lockedInfo[_nftHash(nft)].duration
    //             > block.timestamp
    //     ) revert TopUpNFTIsLocking();
    //     poolInfo.lockedInfo[_nftHash(nft)].lockedStatus = false;
    //     poolInfo.lockedInfo[_nftHash(nft)].duration = 0;
    //     poolInfo.lockedInfo[_nftHash(nft)].lockStartTime = 0;
    //     emit TopUpNftUnlock(daoId, nft.erc721Address, nft.tokenId);
    // }

    function getTopUpNftLockedInfo(
        bytes32 daoId,
        NftIdentifier calldata nft
    )
        public
        view
        returns (uint256 lockStartTime, uint256 duration)
    {
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        lockStartTime = poolInfo.lockedInfo[_nftHash(nft)].lockStartBlock;
        duration = poolInfo.lockedInfo[_nftHash(nft)].duration;
    }

    function _nftHash(NftIdentifier memory nft) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nft.erc721Address, nft.tokenId));
    }
}
