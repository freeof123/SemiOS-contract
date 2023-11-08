// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    DaoMetadataParam,
    BasicDaoParam,
    ContinuousDaoParam,
    Whitelist,
    Blacklist,
    DaoMintCapParam,
    NftMinterCapInfo,
    DaoETHAndERC20SplitRatioParam,
    TemplateParam,
    AllRatioForFundingParam
} from "contracts/interface/D4AStructs.sol";

interface IPDCreateFunding {
    // ============================== Events =============================
    event CreateProjectParamEmittedForFunding(
        bytes32 daoId,
        address daoFeePool,
        address token,
        address nft,
        DaoMetadataParam daoMetadataParam,
        Whitelist whitelist,
        Blacklist blacklist,
        DaoMintCapParam daoMintCapParam,
        NftMinterCapInfo[] nftMinterCapInfo,
        TemplateParam templateParam,
        BasicDaoParam basicDaoParam,
        uint256 actionType,
        AllRatioForFundingParam allRatioForFundingParam
    );

    event CreateContinuousProjectParamEmittedForFunding(
        bytes32 existDaoId,
        bytes32 daoId,
        uint256 dailyMintCap,
        bool needMintableWork,
        bool unifiedPriceModeOff,
        uint256 unifiedPrice,
        uint256 reserveNftNumber,
        bool topUpMode
    );

    event NewProjectForFunding(
        bytes32 daoId,
        string daoUri,
        address daoFeePool,
        address token,
        address nft,
        uint256 royaltyFeeRatioInBps,
        bool isAncestorDao
    );

    event NewCanvasForFunding(bytes32 daoId, bytes32 canvasId, string canvasUri);

    event NewPoolsForFunding(
        address daoAssetPool, address daoRedeemPool, address daoFundingPool, bool isThirdPartyToken
    );

    function createDaoForFunding(
        bytes32 existDaoId,
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        NftMinterCapInfo[] calldata nftMinterCapInfo,
        TemplateParam calldata templateParam,
        BasicDaoParam calldata basicDaoParam,
        ContinuousDaoParam calldata continuousDaoParam,
        AllRatioForFundingParam calldata allRatioForFundingParam,
        uint256 actionType
    )
        external
        payable
        returns (bytes32 daoId);
}
