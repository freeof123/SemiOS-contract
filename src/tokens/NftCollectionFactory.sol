// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { LibString } from "solady/utils/LibString.sol";

import { INftCollectionFactory } from "src/interfaces/INftCollectionFactory.sol";
import { NftCollectionUpgradeable } from "src/tokens/NftCollectionUpgradeable.sol";

contract NftCollectionFactory is INftCollectionFactory {
    using ClonesUpgradeable for address;

    NftCollectionUpgradeable implementation;

    event NewNftCollection(address addr);

    constructor() {
        implementation = new NftCollectionUpgradeable();
    }

    function createNftCollection(
        uint256 daoIndex,
        string calldata contractUri,
        address admin,
        address minter,
        address royaltySetter
    )
        public
        returns (address)
    {
        address t = address(implementation).clone();
        string memory name = string(abi.encodePacked("D4A NFT for No.", LibString.toString(daoIndex)));
        string memory symbol = string(abi.encodePacked("D4A.N", LibString.toString(daoIndex)));
        NftCollectionUpgradeable(t).initialize(name, symbol, contractUri, admin, minter, royaltySetter);

        emit NewNftCollection(t);
        return t;
    }
}
