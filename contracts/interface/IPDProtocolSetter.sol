// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    UserMintCapParam,
    TemplateParam,
    Whitelist,
    Blacklist,
    SetDaoParam,
    NftMinterCapInfo,
    AllRatioParam,
    SetChildrenParam,
    SetDaoParam
} from "contracts/interface/D4AStructs.sol";
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import { ID4AProtocolSetter } from "./ID4AProtocolSetter.sol";

interface IPDProtocolSetter is ID4AProtocolSetter {
    // ============================== Events =============================
    event ChildrenSet(
        bytes32 daoId,
        bytes32[] childrenDaoId,
        uint256[] outputRatios,
        uint256[] inputRatios,
        uint256 redeemPoolInputRatio,
        uint256 selfRewardOutputRatio,
        uint256 selfRewardInputRatio
    );

    event RatioSet(bytes32 daoId, AllRatioParam vars);

    event InitialTokenSupplyForSubDaoSet(bytes32 daoId, uint256 initialTokenSupply);

    event DaoRestart(bytes32 daoId, uint256 remainingRound, uint256 startBlock);
    event DaoInfiniteModeChanged(bytes32 daoId, bool infiniteMode, uint256 remainingRound);

    event DaoRemainingRoundSet(bytes32 daoId, uint256 remainingRound);

    event TopUpInputSplitRatioSet(bytes32 daoId, uint256 defaultInputRatio, bytes32[] subDaoIds, uint256[] inputRatios);
    event TopUpOutputSplitRatioSet(
        bytes32 daoId, uint256 defaultOutputRatio, bytes32[] subDaoIds, uint256[] outputRatios
    );
    event DefaultTopUpInputToRedeemPoolRatioSet(bytes32 daoId, uint256 InputToRedeemPoolRatio);
    event DefaultTopUpOutputToTreasuryRatioSet(bytes32 daoId, uint256 outputToTreasuryRatio);
    event DaoTopUpInputToRedeemPoolRatioSet(bytes32 daoId, uint256 InputToRedeemPoolRatio);
    event DaoTopUpOutputToTreasuryRatioSet(bytes32 daoId, uint256 outputToTreasuryRatio);

    event DaoEditInformationNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event DaoEditParameterNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event DaoEditStrategyNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event DaoRewardNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event TreasuryEditInformationOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event TreasuryTransferAssetOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event TreasurySetTopUpRatioOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);

    function setDaoParams(SetDaoParam calldata vars) external;
    function setChildren(bytes32 daoId, SetChildrenParam calldata vars) external;
    function setRatio(bytes32 daoId, AllRatioParam calldata vars) external;

    function setDaoRemainingRound(bytes32 daoId, uint256 newRemainingRound) external;
    function changeDaoInfiniteMode(bytes32 daoId, uint256 remainingRound) external;
    function setDaoControlPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setDaoEditInformationPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setDaoEditParamPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setDaoEditStrategyPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setDaoRewardPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setTreasuryControlPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setTreasuryEditInformationPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setTreasuryTransferAssetPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setTreasurySetTopUpRatioPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;

    function setTopUpInputSplitRatio(
        bytes32 daoId,
        uint256 defaultInputRatio,
        bytes32[] calldata subDaoIds,
        uint256[] calldata inputRatios
    )
        external;
    function setTopUpOutputSplitRatio(
        bytes32 daoId,
        uint256 defaultOutputRatio,
        bytes32[] calldata subDaoIds,
        uint256[] calldata outputRatios
    )
        external;
    function setDefaultTopUpInputToRedeemPoolRatio(bytes32 daoId, uint256 inputToRedeemPoolRatio) external;
    function setDefaultTopUpOutputToTreasuryRatio(bytes32 daoId, uint256 outputToTreasuryRatio) external;
    function setDaoTopUpInputToRedeemPoolRatio(bytes32 daoId, uint256 inputToRedeemPoolRatio) external;
    function setDaoTopUpOutputToTreasuryRatio(bytes32 daoId, uint256 outputToTreasuryRatio) external;
}
