// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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
    uint256 canvasCreatorERC20Ratio;
    uint256 nftMinterERC20Ratio;
    uint256 daoFeePoolETHRatio;
    uint256 daoFeePoolETHRatioFlatPrice;
}

struct TemplateParam {
    address priceTemplate;
    uint256 priceFactor;
    address rewardTemplate;
    uint256 rewardDecayFactor;
    uint256 rewardDecayLife;
    bool isProgressiveJackpot;
}

struct GetRoundRewardParam {
    uint256 totalReward;
    uint256 startRound;
    uint256 round;
    uint256[] activeRounds;
    uint256 totalRound;
    uint256 decayFactor;
    uint256 decayLife;
    bool isProgressiveJackpot;
}

struct UpdateRewardParam {
    bytes32 daoId;
    bytes32 canvasId;
    uint256 startRound;
    uint256 currentRound;
    uint256 totalRound;
    uint256 daoFeeAmount;
    uint256 protocolERC20RatioInBps;
    uint256 daoCreatorERC20RatioInBps;
    uint256 canvasCreatorERC20RatioInBps;
    uint256 nftMinterERC20RatioInBps;
    uint256 canvasRebateRatioInBps;
}
