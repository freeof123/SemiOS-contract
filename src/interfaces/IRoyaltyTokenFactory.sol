// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IRoyaltyTokenFactory {
    function createRoyaltyToken(
        uint256 daoIndex,
        address admin,
        address minter,
        address burner
    )
        external
        returns (address royaltyToken);
}
