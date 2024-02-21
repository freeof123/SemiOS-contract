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
        uint256[] erc20Ratios,
        uint256[] ethRatios,
        uint256 redeemPoolRatioETH,
        uint256 selfRewardRatioERC20,
        uint256 selfRewardRatioETH
    );

    event RatioSet(bytes32 daoId, AllRatioParam vars);

    event InitialTokenSupplyForSubDaoSet(bytes32 daoId, uint256 initialTokenSupply);

    event DaoRestart(bytes32 daoId, uint256 remainingRound, uint256 startBlock);
    event DaoInfiniteModeChanged(bytes32 daoId, bool infiniteMode, uint256 remainingRound);

    event DaoRemainingRoundSet(bytes32 daoId, uint256 remainingRound);

    event DefaultTopUpEthToRedeemPoolRatioSet(bytes32 daoId, uint256 ethToRedeemPoolRatio);
    event DefaultTopUpErc20ToTreasuryRatioSet(bytes32 daoId, uint256 erc20ToTreasuryRatio);
    event DaoTopUpEthToRedeemPoolRatioSet(bytes32 daoId, uint256 ethToRedeemPoolRatio);
    event DaoTopUpErc20ToTreasuryRatioSet(bytes32 daoId, uint256 erc20ToTreasuryRatio);

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

    function setTopUpEthSplitRatio(
        bytes32 daoId,
        uint256 defaultEthRatio,
        bytes32[] calldata subDaoIds,
        uint256[] calldata ethRatios
    )
        external;
    function setTopUpErc20SplitRatio(
        bytes32 daoId,
        uint256 defaultErc20Ratio,
        bytes32[] calldata subDaoIds,
        uint256[] calldata erc20Ratios
    )
        external;
    function setDefaultTopUpEthToRedeemPoolRatio(bytes32 daoId, uint256 ethToRedeemPoolRatio) external;
    function setDefaultTopUpErc20ToTreasuryRatio(bytes32 daoId, uint256 erc20ToTreasuryRatio) external;
    function setDaoTopUpEthToRedeemPoolRatio(bytes32 daoId, uint256 ethToRedeemPoolRatio) external;
    function setDaoTopUpErc20ToTreasuryRatio(bytes32 daoId, uint256 erc20ToTreasuryRatio) external;
}
