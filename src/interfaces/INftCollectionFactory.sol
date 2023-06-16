// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface INftCollectionFactory {
    function createNftCollection(
        uint256 daoIndex,
        string calldata contractUri,
        address admin,
        address minter,
        address royaltySetter
    )
        external
        returns (address);
}
