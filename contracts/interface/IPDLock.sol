// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";

interface IPDLock {
    //question: merge this
    event TopUpNftLock(bytes32 daoId, NftIdentifier nft, uint256 lockStartBlock, uint256 duration);
    //event TopUpNftUnlock(bytes32 daoId, address nftAddress, uint256 nftId);

    function lockTopUpNFT(bytes32 daoId, NftIdentifier calldata nft, uint256 duration) external;
    function checkTopUpNftLockedStatus(bytes32 daoId, NftIdentifier calldata nft) external view returns (bool locked);
    function getTopUpNftLockedInfo(
        bytes32 daoId,
        NftIdentifier calldata nft
    )
        external
        view
        returns (uint256 lockStartTime, uint256 duration);
}
