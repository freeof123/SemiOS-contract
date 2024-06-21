// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    CreateSemiDaoParam,
    DaoMetadataParam,
    BasicDaoParam,
    ContinuousDaoParam,
    Whitelist,
    Blacklist,
    DaoMintCapParam,
    NftMinterCapInfo,
    NftMinterCapIdInfo,
    TemplateParam,
    AllRatioParam
} from "contracts/interface/D4AStructs.sol";

import { ICreate } from "contracts/interface/ICreate.sol";

interface IPDCreate is ICreate {
    // ============================== Events =============================
    event CreateProjectParamEmitted(
        bytes32 daoId,
        address daoFeePool,
        address token,
        address nft,
        DaoMetadataParam daoMetadataParam,
        Whitelist whitelist,
        Blacklist blacklist,
        DaoMintCapParam daoMintCapParam,
        NftMinterCapInfo[] nftMinterCapInfo,
        NftMinterCapIdInfo[] nftMinterCapIdInfo,
        TemplateParam templateParam,
        BasicDaoParam basicDaoParam,
        uint256 actionType,
        AllRatioParam allRatioParam
    );

    event CreateContinuousProjectParamEmitted(
        bytes32 existDaoId,
        bytes32 daoId,
        uint256 dailyMintCap,
        bool needMintableWork,
        bool unifiedPriceModeOff,
        uint256 unifiedPrice,
        uint256 reserveNftNumber,
        bool topUpMode,
        bool infiniteMode,
        bool outputPaymentMode,
        address inputToken
    );

    event NewProject(
        bytes32 daoId, string daoUri, address token, address nft, uint256 royaltyFeeRatioInBps, bool isAncestorDao
    );

    event NewPools(
        bytes32 daoId,
        address daoAssetPool,
        address daoRedeemPool,
        uint256 daoTopUpInputToRedeemPoolRatio,
        uint256 daoTopUpOutputToTreasuryRatio,
        bool isThirdPartyToken
    );

    event NewSemiTreasury(bytes32 daoId, address treasury, address grantTreasuryNft, uint256 initTokenSupply);

    event NewSemiDaoErc721Address(bytes32 daoId, address daoNft, address grantDaoNft);

    function createDao(CreateSemiDaoParam calldata createDaoParam) external payable returns (bytes32 daoId);
}
