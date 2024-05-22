// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import { D4AERC721WithFilter } from "contracts/D4AERC721WithFilter.sol";

contract PDERC721WithFilter is D4AERC721WithFilter {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    function initialize(string memory name, string memory symbol, uint256 startTokenId) public override initializer {
        __D4AERC721_init(name, symbol);
        __DefaultOperatorFilterer_init();
        _tokenIds._value = startTokenId;
    }

    function mintItem(
        address player,
        string memory uri,
        uint256 tokenId,
        bool zeroTokenId
    )
        //
        public
        override
        onlyRole(MINTER)
        returns (uint256)
    {
        if (zeroTokenId) {
            _mint(player, 0);
            _setTokenURI(0, uri);
            return 0;
        } else {
            if (tokenId == 0) {
                _tokenIds.increment();
                uint256 newItemId = _tokenIds.current();
                _mint(player, newItemId);
                _setTokenURI(newItemId, uri);
                return newItemId;
            } else {
                _mint(player, tokenId);
                _setTokenURI(tokenId, uri);
                return tokenId;
            }
        }
    }
}
