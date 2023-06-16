// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    DaoMetadataParam,
    Whitelist,
    Blacklist,
    DaoMintCapParam,
    DaoETHAndERC20SplitRatioParam
} from "src/interfaces/D4AStructs.sol";

interface IDaoFacet {
    event NewDao(
        bytes32 daoId,
        string daoUri,
        uint96 royaltyFeeInBps,
        address daoFeePool,
        address royaltyToken,
        address nftCollection
    );

    function createDao(
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        DaoETHAndERC20SplitRatioParam calldata splitRatioParam,
        uint32 daoMintCap,
        uint256 actionType
    )
        external
        payable
        returns (bytes32 daoId);
}
