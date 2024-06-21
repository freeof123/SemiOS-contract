// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { PriceTemplateType, RewardTemplateType, PlanTemplateType } from "./D4AEnums.sol";

// /**
//  * @dev create continuous dao
//  * @param existDaoId basic dao id
//  * @param daoMetadataParam metadata param for dao
//  * @param whitelist the whitelist
//  * @param blacklist the blacklist
//  * @param daoMintCapParam the mint cap param for dao
//  * @param templateParam the template param
//  * @param basicDaoParam the param for basic dao
//  * @param continuousDaoParam the param for continuous dao
//  * @param actionType the type of action
//  */

struct CreateSemiDaoParam {
    bytes32 existDaoId;
    DaoMetadataParam daoMetadataParam;
    Whitelist whitelist;
    Blacklist blacklist;
    DaoMintCapParam daoMintCapParam;
    NftMinterCapInfo[] nftMinterCapInfo;
    NftMinterCapIdInfo[] nftMinterCapIdInfo;
    TemplateParam templateParam;
    BasicDaoParam basicDaoParam;
    ContinuousDaoParam continuousDaoParam;
    AllRatioParam allRatioParam;
    uint256 actionType;
}

struct DaoMetadataParam {
    uint256 startBlock;
    uint256 mintableRounds;
    uint256 duration; // blocknumber * 1e18
    uint256 floorPrice;
    uint256 maxNftRank;
    uint96 royaltyFee;
    string projectUri;
    uint256 projectIndex;
}

struct DaoMintInfo {
    uint32 daoMintCap; // Dao的铸造上限
    uint32 NFTHolderMintCap; // NftHolder的铸造上限
    mapping(address minter => UserMintInfo) userMintInfos; // 给定minter的地址，获取已经mint的个数以及mintCap
}

struct NftMinterCapInfo {
    address nftAddress;
    uint256 nftMintCap;
}

struct NftMinterCapIdInfo {
    address nftAddress;
    uint256 tokenId;
    uint256 nftMintCap;
}

struct NftMinterCap {
    mapping(address nftAddress => bool) nftExistInMapping;
    mapping(address nftAddress => uint256) nftHolderMintCap;
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

struct TemplateParam {
    PriceTemplateType priceTemplateType;
    uint256 priceFactor;
    RewardTemplateType rewardTemplateType;
    uint256 rewardDecayFactor;
    bool isProgressiveJackpot;
}

struct MintNftInfo {
    string tokenUri;
    uint256 flatPrice;
}

struct Blacklist {
    address[] minterAccounts;
    address[] canvasCreatorAccounts;
}

struct Whitelist {
    bytes32 minterMerkleRoot;
    address[] minterNFTHolderPasses;
    NftIdentifier[] minterNFTIdHolderPasses;
    bytes32 canvasCreatorMerkleRoot;
    address[] canvasCreatorNFTHolderPasses;
    NftIdentifier[] canvasCreatorNFTIdHolderPasses;
}

struct BasicDaoParam {
    bytes32 canvasId;
    string canvasUri;
    string daoName;
}

struct ContinuousDaoParam {
    uint256 reserveNftNumber;
    bool unifiedPriceModeOff;
    uint256 unifiedPrice;
    bool needMintableWork;
    uint256 dailyMintCap;
    //1.3add-------------------//block reward distribution ratios
    bytes32[] childrenDaoId;
    uint256[] childrenDaoOutputRatios;
    uint256[] childrenDaoInputRatios;
    uint256 redeemPoolInputRatio;
    uint256 treasuryOutputRatio;
    uint256 treasuryInputRatio;
    uint256 selfRewardOutputRatio;
    uint256 selfRewardInputRatio;
    bool isAncestorDao;
    address daoToken;
    bool topUpMode;
    //1.4add--------------------
    bool infiniteMode;
    bool outputPaymentMode;
    //1.6add--------------------
    string ownershipUri;
    //1.7add--------------------
    address inputToken;
}
// 修改Dao中参数的结构体，被用于setDaoParams方法

struct SetMintCapAndPermissionParam {
    bytes32 daoId;
    uint32 daoMintCap;
    UserMintCapParam[] userMintCapParams;
    NftMinterCapInfo[] nftMinterCapInfo;
    NftMinterCapIdInfo[] nftMinterCapIdInfo;
    Whitelist whitelist;
    Blacklist blacklist;
    Blacklist unblacklist;
}

struct AllRatioParam {
    //mint fee ratios
    uint256 canvasCreatorMintFeeRatio;
    uint256 assetPoolMintFeeRatio;
    uint256 redeemPoolMintFeeRatio;
    uint256 treasuryMintFeeRatio;
    // add l.protocolMintFeeRatioInBps should be 10000
    uint256 canvasCreatorMintFeeRatioFiatPrice;
    uint256 assetPoolMintFeeRatioFiatPrice;
    uint256 redeemPoolMintFeeRatioFiatPrice;
    uint256 treasuryMintFeeRatioFiatPrice;
    // add l.protocolMintFeeRatioInBpsFiatPrice

    //output reward ratio
    uint256 minterOutputRewardRatio;
    uint256 canvasCreatorOutputRewardRatio;
    uint256 daoCreatorOutputRewardRatio;
    // add l.protocolOutputRewardRatio,

    //input reward ratio, add l.protocolInputRewardRatio
    uint256 minterInputRewardRatio;
    uint256 canvasCreatorInputRewardRatio;
    uint256 daoCreatorInputRewardRatio;
}
//1.3 add -------------------------

struct SetChildrenParam {
    bytes32[] childrenDaoId;
    uint256[] childrenDaoOutputRatios;
    uint256[] childrenDaoInputRatios;
    uint256 redeemPoolInputRatio;
    uint256 treasuryOutputRatio;
    uint256 treasuryInputRatio;
    uint256 selfRewardOutputRatio;
    uint256 selfRewardInputRatio;
}

struct UpdateRewardParam {
    bytes32 daoId;
    bytes32 canvasId;
    address token;
    uint256 startRound;
    uint256 currentRound;
    uint256 totalRound;
    uint256 daoFeeAmount;
    address daoFeePool;
    bool zeroPrice;
    bool topUpMode;
    bytes32 nftHash;
    address inputToken;
}

struct SetDaoParam {
    bytes32 daoId;
    uint256 nftMaxSupplyRank;
    uint256 remainingRound;
    uint256 daoFloorPrice;
    PriceTemplateType priceTemplateType;
    uint256 nftPriceFactor;
    uint256 dailyMintCap;
    uint256 unifiedPrice;
    bool changeInfiniteMode;
    SetChildrenParam setChildrenParam;
    AllRatioParam allRatioParam;
}

struct CreateCanvasAndMintNFTParam {
    bytes32 daoId;
    bytes32 canvasId;
    string canvasUri; // be empty when not creating a canvas
    address canvasCreator; // be empty when not creating a canvas
    string tokenUri;
    bytes nftSignature;
    uint256 flatPrice;
    bytes32[] proof;
    bytes32[] canvasProof; // be empty when not creating a canvas
    address nftOwner;
    bytes erc20Signature;
    uint256 deadline;
    NftIdentifier nftIdentifier;
}

struct MintNFTParam {
    bytes32 daoId;
    bytes32 canvasId;
    string tokenUri;
    bytes32[] proof;
    uint256 flatPrice;
    bytes nftSignature;
    address nftOwner;
    bytes erc20Signature;
    uint256 deadline;
    NftIdentifier nftIdentifier;
}

struct CreatePlanParam {
    bytes32 daoId;
    uint256 startBlock;
    uint256 duration;
    uint256 totalRounds;
    uint256 totalReward;
    address rewardToken;
    bool useTreasury;
    bool io;
    string uri;
    PlanTemplateType planTemplateType;
}

struct NftIdentifier {
    address erc721Address;
    uint256 tokenId;
}
