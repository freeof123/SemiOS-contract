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
        bool topUpMode
    );

    event NewProject(
        bytes32 daoId, string daoUri, address token, address nft, uint256 royaltyFeeRatioInBps, bool isAncestorDao
    );

    event NewPools(bytes32 daoId, address daoAssetPool, address daoRedeemPool, bool isThirdPartyToken);

    function createDao(
        bytes32 existDaoId,
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        NftMinterCapInfo[] calldata nftMinterCapInfo,
        TemplateParam calldata templateParam,
        BasicDaoParam calldata basicDaoParam,
        ContinuousDaoParam calldata continuousDaoParam,
        AllRatioParam calldata allRatioParam,
        uint256 actionType
    )
        external
        payable
        returns (bytes32 daoId);
}
