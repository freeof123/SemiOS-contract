// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";

library GrantStorage {
    struct GrantInfo {
        address granter;
        uint256 grantAmount;
        bool isUseTreasury;
        uint256 grantBlock;
        bytes32 receiverDao;
        address token;
    }

    struct Layout {
        mapping(bytes32 daoId => address vestingWallet) vestingWallets;
        mapping(address token => bool isTokenAllowed) tokensAllowed;
        address[] allowedTokenList;
        mapping(bytes32 nftHash => GrantInfo) grantInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.GrantStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
