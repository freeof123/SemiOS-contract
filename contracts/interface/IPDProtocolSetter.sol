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

    event DaoTopUpBalanceOutRatioSet(bytes32 daoId, uint256 topupEthToRedeemPoolRatio, uint256 erc20ToTreasuryRatio);
    event DefaultDaoTopUpBalanceOutRatioSet(
        bytes32 daoId, uint256 topupEthToRedeemPoolRatio, uint256 erc20ToTreasuryRatio
    );

    event DaoEditInformationNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event DaoEditParameterNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event DaoEditStrategyNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event DaoRewardNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);
    event DaoTreasuryNftOwnerSet(bytes32 daoId, address nftAddress, uint256 tokenId);

    function setDaoParams(SetDaoParam calldata vars) external;
    function setChildren(bytes32 daoId, SetChildrenParam calldata vars) external;
    function setRatio(bytes32 daoId, AllRatioParam calldata vars) external;

    function setInitialTokenSupplyForSubDao(bytes32 daoId, uint256 tokenMaxSupply) external;
    function setDaoRemainingRound(bytes32 daoId, uint256 newRemainingRound) external;
    function changeDaoInfiniteMode(bytes32 daoId, uint256 remainingRound) external;
    function setDaoControlPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setDaoEditInformationPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setDaoEditParamPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setDaoEditStrategyPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;
    function setDaoRewardPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) external;

    function setTopUpBalanceSplitRatio(
        bytes32 daoId,
        uint256 topupEthToRedeemPoolRatio,
        uint256 erc20ToTreasuryRatio
    )
        external;
    function setDefaultTopUpBalanceSplitRatio(
        bytes32 daoId,
        uint256 topupEthToRedeemPoolRatio,
        uint256 erc20ToTreasuryRatio
    )
        external;
}
