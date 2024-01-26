// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";

interface IPDLock {
    event TopUpNftLock(NftIdentifier nft, uint256 lockStartBlock, uint256 duration);

    function lockTopUpNFT(NftIdentifier calldata nft, uint256 duration) external;
    function checkTopUpNftLockedStatus(NftIdentifier calldata nft) external view returns (bool locked);
    function getTopUpNftLockedInfo(NftIdentifier calldata nft)
        external
        view
        returns (uint256 lockStartBlock, uint256 duration);
}
