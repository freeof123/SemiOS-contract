// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { PriceTemplateType, RewardTemplateType } from "./D4AEnums.sol";

struct DaoMetadataParam {
    uint256 startDrb;
    uint256 mintableRounds;
    uint256 floorPriceRank;
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

struct DaoETHAndERC20SplitRatioParam {
    uint256 daoCreatorERC20Ratio;
    uint256 canvasCreatorERC20Ratio;
    uint256 nftMinterERC20Ratio;
    uint256 daoFeePoolETHRatio;
    uint256 daoFeePoolETHRatioFlatPrice;
}

struct TemplateParam {
    PriceTemplateType priceTemplateType;
    uint256 priceFactor;
    RewardTemplateType rewardTemplateType;
    uint256 rewardDecayFactor;
    bool isProgressiveJackpot;
}

struct UpdateRewardParam {
    bytes32 daoId;
    bytes32 canvasId;
    address token;
    uint256 startRound;
    uint256 currentRound;
    uint256 totalRound;
    uint256 daoFeeAmount;
    uint256 protocolERC20RatioInBps;
    uint256 daoCreatorERC20RatioInBps;
    uint256 canvasCreatorERC20RatioInBps;
    uint256 nftMinterERC20RatioInBps;
    uint256 canvasRebateRatioInBps;
    address daoFeePool;
    bool zeroPrice;
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
    bytes32 canvasCreatorMerkleRoot;
    address[] canvasCreatorNFTHolderPasses;
}

struct BasicDaoParam {
    uint256 initTokenSupplyRatio;
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
    //1.3add-------------------
    bytes32[] childrenDaoId;
    uint256[] childrenDaoRatiosERC20;
    uint256[] childrenDaoRatiosETH;
    uint256 redeemPoolRatioETH;
    uint256 selfRewardRatioERC20;
    uint256 selfRewardRatioETH;
    bool isAncestorDao;
    address daoToken;
    bool topUpMode;
}
// 修改Dao中参数的结构体，被用于setDaoParams方法

struct SetDaoParam {
    bytes32 daoId;
    uint256 nftMaxSupplyRank;
    uint256 mintableRoundRank;
    uint256 daoFloorPriceRank;
    PriceTemplateType priceTemplateType;
    uint256 nftPriceFactor;
    uint256 daoCreatorERC20Ratio;
    uint256 canvasCreatorERC20Ratio;
    uint256 nftMinterERC20Ratio;
    uint256 daoFeePoolETHRatio;
    uint256 daoFeePoolETHRatioFlatPrice;
    uint256 dailyMintCap;
    uint256 addedDaoToken;
    uint256 unifiedPrice;
}

struct SetMintCapAndPermissionParam {
    bytes32 daoId;
    uint32 daoMintCap;
    UserMintCapParam[] userMintCapParams;
    NftMinterCapInfo[] nftMinterCapInfo;
    Whitelist whitelist;
    Blacklist blacklist;
    Blacklist unblacklist;
}

struct SetRatioParam {
    bytes32 daoId;
    uint256 daoCreatorERC20Ratio;
    uint256 canvasCreatorERC20Ratio;
    uint256 nftMinterERC20Ratio;
    uint256 daoFeePoolETHRatio;
    uint256 daoFeePoolETHRatioFlatPrice;
}

struct AllRatioForFundingParam {
    uint256 canvasCreatorMintFeeRatio;
    uint256 assetPoolMintFeeRatio;
    uint256 redeemPoolMintFeeRatio;
    // add l.protocolMintFeeRatioInBps should be 10000
    uint256 canvasCreatorMintFeeRatioFiatPrice;
    uint256 assetPoolMintFeeRatioFiatPrice;
    uint256 redeemPoolMintFeeRatioFiatPrice;
    // add l.protocolMintFeeRatioInBpsFiatPrice

    //erc20 reward ratio
    uint256 minterERC20RewardRatio;
    uint256 canvasCreatorERC20RewardRatio;
    uint256 daoCreatorERC20RewardRatio;
    // add l.protocolERC20RatioInBps,

    //eth reward ratio, add l.protocolETHRewardRatio
    uint256 minterETHRewardRatio;
    uint256 canvasCreatorETHRewardRatio;
    uint256 daoCreatorETHRewardRatio;
}
//1.3 add -------------------------

struct SetChildrenParam {
    bytes32[] childrenDaoId;
    uint256[] erc20Ratios;
    uint256[] ethRatios;
    uint256 redeemPoolRatioETH;
    uint256 selfRewardRatioERC20;
    uint256 selfRewardRatioETH;
}

struct UpdateRewardParamFunding {
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
}

struct SetDaoParamFunding {
    bytes32 daoId;
    uint256 nftMaxSupplyRank;
    uint256 mintableRoundRank;
    uint256 daoFloorPriceRank;
    PriceTemplateType priceTemplateType;
    uint256 nftPriceFactor;
    uint256 dailyMintCap;
    uint256 initialTokenSupply;
    uint256 unifiedPrice;
    SetChildrenParam setChildrenParam;
    AllRatioForFundingParam allRatioForFundingParam;
}
