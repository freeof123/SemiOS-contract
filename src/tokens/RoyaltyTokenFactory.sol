// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { LibString } from "solady/utils/LibString.sol";

import { IRoyaltyTokenFactory } from "src/interfaces/IRoyaltyTokenFactory.sol";
import { RoyaltyTokenUpgradeable } from "src/tokens/RoyaltyTokenUpgradeable.sol";

contract RoyaltyTokenFactory is IRoyaltyTokenFactory {
    using ClonesUpgradeable for address;

    RoyaltyTokenUpgradeable public implementation;

    event NewD4AERC20(address addr);

    constructor() {
        implementation = new RoyaltyTokenUpgradeable();
    }

    function createRoyaltyToken(
        uint256 daoIndex,
        address admin,
        address minter,
        address burner
    )
        public
        returns (address)
    {
        address royaltyToken = address(implementation).clone();

        string memory name = string(abi.encodePacked("D4A Token for No.", LibString.toString(daoIndex)));
        string memory symbol = string(abi.encodePacked("D4A.T", LibString.toString(daoIndex)));
        RoyaltyTokenUpgradeable(royaltyToken).initialize(name, symbol, admin, minter, burner);

        emit NewD4AERC20(royaltyToken);

        return royaltyToken;
    }
}
