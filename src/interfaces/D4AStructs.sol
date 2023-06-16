// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct DaoMetadataParam {
    uint256 startDrb;
    uint256 daoIndex;
    uint256 mintableRounds;
    string daoUri;
    uint96 royaltyFeeInBps;
    uint256 floorPrice;
}

struct DaoMintInfo {
    uint32 daoMintCap;
    mapping(address minter => UserMintInfo) userMintInfos;
}

struct UserMintInfo {
    uint32 minted;
    uint32 mintCap;
}

struct DaoMintCapParam {
    uint32 daoMintCap;
    UserMintCapParam[] userMintCapParams;
}

struct UserMintCapParam {
    address minter;
    uint32 mintCap;
}

struct DaoETHAndERC20SplitRatioParam {
    uint256 canvasCreatorERC20RatioInBps;
    uint256 nftMinterERC20RatioInBps;
    uint256 daoFeePoolETHRatioInBps;
    uint256 daoFeePoolETHRatioInBpsFlatPrice;
}

struct Blacklist {
    address[] minterAccounts;
    address[] canvasCreatorAccounts;
}

struct Whitelist {
    bytes32 minterMerkleRoot;
    address[] minterNFTHolderPasses;
    bytes32 canvasCreatorMerkleRoot;
    address[] canvasCreatorNFTHolderPasses;
}
