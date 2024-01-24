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
    NftIdentifier
} from "contracts/interface/D4AStructs.sol";
import { PriceTemplateType, DaoTag } from "contracts/interface/D4AEnums.sol";
import "contracts/interface/D4AErrors.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { RewardStorage } from "contracts/storages/RewardStorage.sol";
import { RoundStorage } from "contracts/storages/RoundStorage.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { InheritTreeStorage } from "contracts/storages/InheritTreeStorage.sol";
import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IPDProtocolSetter } from "./interface/IPDProtocolSetter.sol";
import { IPDProtocolReadable } from "./interface/IPDProtocolReadable.sol";
import { IPDRound } from "contracts/interface/IPDRound.sol";

import { OwnerStorage } from "contracts/storages/OwnerStorage.sol";

import { D4AERC20 } from "./D4AERC20.sol";
import "forge-std/Test.sol";

contract PDProtocolSetter is IPDProtocolSetter, D4AProtocolSetter {
    // 修改黑白名单方法
    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        NftMinterCapInfo[] calldata nftMinterCapInfo,
        Whitelist memory whitelist,
        Blacklist memory blacklist,
        Blacklist memory unblacklist
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        // _checkSetAbility(daoId, true, true);
        // question, set function not split
        _checkEditStrategyAbility(daoId);

        super.setMintCapAndPermission(
            daoId, daoMintCap, userMintCapParams, nftMinterCapInfo, whitelist, blacklist, unblacklist
        );
    }

    function setDaoNftMaxSupply(
        bytes32 daoId,
        uint256 newMaxSupply
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);

        super.setDaoNftMaxSupply(daoId, newMaxSupply);
    }

    function setDaoFloorPrice(
        bytes32 daoId,
        uint256 newFloorPrice
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        //_checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);

        super.setDaoFloorPrice(daoId, newFloorPrice);
    }

    function setDaoPriceTemplate(
        bytes32 daoId,
        PriceTemplateType priceTemplateType,
        uint256 nftPriceFactor
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);
        super.setDaoPriceTemplate(daoId, priceTemplateType, nftPriceFactor);
    }

    function setTemplate(
        bytes32 daoId,
        TemplateParam calldata templateParam
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        // _checkSetAbility(daoId, false, true);
        //Todo: only protocol can set
        //_checkEditParamAbility(daoId);
        super.setTemplate(daoId, templateParam);
    }

    function setRoundMintCap(
        bytes32 daoId,
        uint256 dailyMintCap
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);

        super.setRoundMintCap(daoId, dailyMintCap);
    }

    function setWhitelistMintCap(
        bytes32 daoId,
        address whitelistUser,
        uint32 whitelistUserMintCap
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        // _checkSetAbility(daoId, true, true);
        _checkEditStrategyAbility(daoId);
        super.setWhitelistMintCap(daoId, whitelistUser, whitelistUserMintCap);
    }

    function setDaoUnifiedPrice(
        bytes32 daoId,
        uint256 newUnifiedPrice
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);
        super.setDaoUnifiedPrice(daoId, newUnifiedPrice);
    }
    // 1.3 add--------------------------------------
    // check set ability, protocol always can set

    function setDaoParams(SetDaoParam calldata vars) public {
        // _checkSetAbility(vars.daoId, true, true);
        _checkEditParamAbility(vars.daoId);
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        bytes32 ancestor = InheritTreeStorage.layout().inheritTreeInfos[vars.daoId].ancestor;
        // 1.6 todo : treasury permission
        if (msg.sender == settingsStorage.ownerProxy.ownerOf(ancestor)) {
            setInitialTokenSupplyForSubDao(vars.daoId, vars.initialTokenSupply);
        } //1

        if (!vars.changeInfiniteMode) {
            setDaoRemainingRound(vars.daoId, vars.remainingRound); //2
        } else {
            changeDaoInfiniteMode(vars.daoId, vars.remainingRound);
        }
        setDaoNftMaxSupply(vars.daoId, settingsStorage.nftMaxSupplies[vars.nftMaxSupplyRank]); //3
        setRoundMintCap(vars.daoId, vars.dailyMintCap); //4
        setDaoFloorPrice(vars.daoId, vars.daoFloorPrice); //5
        setDaoUnifiedPrice(vars.daoId, vars.unifiedPrice);
        setDaoPriceTemplate(vars.daoId, vars.priceTemplateType, vars.nftPriceFactor); //6
        setChildren(vars.daoId, vars.setChildrenParam); //7
        setRatio(vars.daoId, vars.allRatioParam); // 8 mint fee , 9 reward roles ratio
    }

    function setChildren(bytes32 daoId, SetChildrenParam calldata vars) public {
        require(vars.childrenDaoId.length == vars.erc20Ratios.length, "invalid length");
        require(vars.childrenDaoId.length == vars.ethRatios.length, "invalid length");

        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);

        if (BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode) {
            emit ChildrenSet(daoId, new bytes32[](0), new uint256[](0), new uint256[](0), 0, 10_000, 0);
            return;
        }

        uint256 sumERC20;
        uint256 sumETH;
        InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        bytes32 ancestorDao = treeInfo.ancestor;

        for (uint256 i = 0; i < vars.childrenDaoId.length;) {
            //if (!BasicDaoStorage.layout().basicDaoInfos[daoId].exist) revert NotDaoForFunding();
            if (InheritTreeStorage.layout().inheritTreeInfos[vars.childrenDaoId[i]].ancestor != ancestorDao) {
                revert InvalidDaoAncestor(vars.childrenDaoId[i]);
            }
            sumERC20 += vars.erc20Ratios[i];
            sumETH += vars.ethRatios[i];
            unchecked {
                ++i;
            }
        }
        sumERC20 += vars.selfRewardRatioERC20;
        sumETH += vars.redeemPoolRatioETH;
        sumETH += vars.selfRewardRatioETH;
        if (sumERC20 > BASIS_POINT) revert InvalidChildrenDaoRatio();
        if (sumETH > BASIS_POINT) revert InvalidChildrenDaoRatio();

        treeInfo.children = vars.childrenDaoId;
        treeInfo.childrenDaoRatiosERC20 = vars.erc20Ratios;
        treeInfo.childrenDaoRatiosETH = vars.ethRatios;

        treeInfo.redeemPoolRatioETH = vars.redeemPoolRatioETH;
        treeInfo.selfRewardRatioERC20 = vars.selfRewardRatioERC20;
        treeInfo.selfRewardRatioETH = vars.selfRewardRatioETH;

        emit ChildrenSet(
            daoId,
            vars.childrenDaoId,
            vars.erc20Ratios,
            vars.ethRatios,
            vars.redeemPoolRatioETH,
            vars.selfRewardRatioERC20,
            vars.selfRewardRatioETH
        );
    }

    //in PD1.3, we always use ratios w.r.t all 4 roles

    function setRatio(bytes32 daoId, AllRatioParam calldata vars) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode) {
            emit RatioSet(daoId, AllRatioParam(0, 0, 0, 0, 0, 0, 10_000, 0, 0, 0, 0, 0));
            return;
        }
        InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        if (
            vars.canvasCreatorMintFeeRatio + vars.assetPoolMintFeeRatio + vars.redeemPoolMintFeeRatio
                + l.protocolMintFeeRatioInBps != BASIS_POINT
        ) revert InvalidMintFeeRatio();
        treeInfo.canvasCreatorMintFeeRatio = vars.canvasCreatorMintFeeRatio;
        treeInfo.assetPoolMintFeeRatio = vars.assetPoolMintFeeRatio;
        treeInfo.redeemPoolMintFeeRatio = vars.redeemPoolMintFeeRatio;

        if (
            vars.canvasCreatorMintFeeRatioFiatPrice + vars.assetPoolMintFeeRatioFiatPrice
                + vars.redeemPoolMintFeeRatioFiatPrice + l.protocolMintFeeRatioInBps != BASIS_POINT
        ) revert InvalidMintFeeRatio();
        treeInfo.canvasCreatorMintFeeRatioFiatPrice = vars.canvasCreatorMintFeeRatioFiatPrice;
        treeInfo.assetPoolMintFeeRatioFiatPrice = vars.assetPoolMintFeeRatioFiatPrice;
        treeInfo.redeemPoolMintFeeRatioFiatPrice = vars.redeemPoolMintFeeRatioFiatPrice;

        if (
            vars.minterERC20RewardRatio + vars.canvasCreatorERC20RewardRatio + vars.daoCreatorERC20RewardRatio
                + l.protocolERC20RatioInBps != BASIS_POINT
        ) revert InvalidERC20RewardRatio();

        treeInfo.minterERC20RewardRatio = vars.minterERC20RewardRatio;
        treeInfo.canvasCreatorERC20RewardRatio = vars.canvasCreatorERC20RewardRatio;
        treeInfo.daoCreatorERC20RewardRatio = vars.daoCreatorERC20RewardRatio;

        if (
            vars.minterETHRewardRatio + vars.canvasCreatorETHRewardRatio + vars.daoCreatorETHRewardRatio
                + l.protocolETHRewardRatio != BASIS_POINT
        ) {
            revert InvalidETHRewardRatio();
        }
        treeInfo.minterETHRewardRatio = vars.minterETHRewardRatio;
        treeInfo.canvasCreatorETHRewardRatio = vars.canvasCreatorETHRewardRatio;
        treeInfo.daoCreatorETHRewardRatio = vars.daoCreatorETHRewardRatio;

        emit RatioSet(daoId, vars);
    }

    function setInitialTokenSupplyForSubDao(bytes32 daoId, uint256 initialTokenSupply) public {
        //todo: treasury permission
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken) return;
        InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        bytes32 ancestor = treeInfo.ancestor;
        address daoToken = DaoStorage.layout().daoInfos[ancestor].token;

        // if (msg.sender != settingsStorage.ownerProxy.ownerOf(ancestor)) revert NotDaoOwner();
        _checkEditParamAbility(daoId);
        BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();
        if (!InheritTreeStorage.layout().inheritTreeInfos[ancestor].isAncestorDao) revert NotAncestorDao();

        address daoAssetPool = basicDaoStorage.basicDaoInfos[daoId].daoAssetPool;
        D4AERC20(daoToken).mint(daoAssetPool, initialTokenSupply);
        DaoStorage.layout().daoInfos[daoId].tokenMaxSupply += initialTokenSupply;

        if (D4AERC20(daoToken).totalSupply() > settingsStorage.tokenMaxSupply) revert SupplyOutOfRange();

        emit InitialTokenSupplyForSubDaoSet(daoId, initialTokenSupply);
    }

    function setDaoRemainingRound(bytes32 daoId, uint256 newRemainingRound) public {
        //Todo infinitemode
        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);
        if (newRemainingRound == 0) return;
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].infiniteMode) return;
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        uint256 remainingRound = IPDProtocolReadable(address(this)).getDaoRemainingRound(daoId);
        if (remainingRound == 0) {
            _daoRestart(daoId, newRemainingRound);
        } else {
            daoInfo.mintableRound += newRemainingRound;
            daoInfo.mintableRound -= remainingRound;
        }
        emit DaoRemainingRoundSet(daoId, newRemainingRound);
    }

    function changeDaoInfiniteMode(bytes32 daoId, uint256 remainingRound) public {
        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);
        bool infiniteMode = BasicDaoStorage.layout().basicDaoInfos[daoId].infiniteMode;
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        uint256 currentRound = IPDRound(address(this)).getDaoCurrentRound(daoId);
        uint256 passedRound = IPDProtocolReadable(address(this)).getDaoPassedRound(daoId);

        if (!infiniteMode) {
            if (IPDProtocolReadable(address(this)).getDaoRemainingRound(daoId) == 0) {
                _daoRestart(daoId, 1);
            }
            BasicDaoStorage.layout().basicDaoInfos[daoId].infiniteMode = true;
        } else {
            if (remainingRound == 0) revert TurnOffInfiniteModeWithZeroRemainingRound();
            BasicDaoStorage.layout().basicDaoInfos[daoId].infiniteMode = false;
            daoInfo.mintableRound = passedRound + remainingRound;
            if (rewardInfo.isProgressiveJackpot) {
                if (
                    rewardInfo.activeRounds.length == 0
                        || rewardInfo.activeRounds[rewardInfo.activeRounds.length - 1] != currentRound
                            && rewardInfo.activeRounds[rewardInfo.activeRounds.length - 1] != currentRound - 1
                ) {
                    if (currentRound > 1) {
                        rewardInfo.activeRounds.push(currentRound - 1);
                    }
                }
            }
        }
        emit DaoInfiniteModeChanged(daoId, !infiniteMode, remainingRound);
    }

    function setTopUpBalanceOutRatio(
        bytes32 daoId,
        uint256 ethToRedeemPoolRatio,
        uint256 erc20ToTreasuryRatio
    )
        public
    {
        //todo
        //_checkTreasuryNFTOwner(daoId, msg.sender);
        _checkEditParamAbility(daoId);
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        poolInfo.ethToRedeemPoolRatio = ethToRedeemPoolRatio;
        poolInfo.erc20ToTreasuryRatio = erc20ToTreasuryRatio;
        emit DaoTopUpBalanceOutRatioSet(daoId, ethToRedeemPoolRatio, erc20ToTreasuryRatio);
    }

    event checkPoint(address msg);

    function setDaoControlPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        //check ownership nft
        // todo: get from daoId
        if (msg.sender != IERC721(daoNftAddress).ownerOf(tokenId) && msg.sender != address(this)) {
            emit checkPoint(msg.sender);
            emit checkPoint(address(this));
            revert NotNftOwner();
        }

        OwnerStorage.OwnerInfo storage ownerInfo = OwnerStorage.layout().ownerInfos[daoId];

        ownerInfo.ownerForDaoEditInformation = NftIdentifier(daoNftAddress, tokenId);
        // todo event name nft ->nftOwner
        emit DaoEditInformationNftSet(daoId, daoNftAddress, tokenId);
        ownerInfo.ownerForDaoEditParameter = NftIdentifier(daoNftAddress, tokenId);
        emit DaoEditParameterNftSet(daoId, daoNftAddress, tokenId);
        ownerInfo.ownerForDaoEditStrategy = NftIdentifier(daoNftAddress, tokenId);
        emit DaoEditStrategyNftSet(daoId, daoNftAddress, tokenId);
        ownerInfo.ownerForDaoReward = NftIdentifier(daoNftAddress, tokenId);
        emit DaoRewardNftSet(daoId, daoNftAddress, tokenId);
    }

    function setDaoEditInformationPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkEditInformationAbility(daoId);
        OwnerStorage.layout().ownerInfos[daoId].ownerForDaoEditInformation = NftIdentifier(daoNftAddress, tokenId);
        emit DaoEditInformationNftSet(daoId, daoNftAddress, tokenId);
    }

    function setDaoEditParamPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkEditParamAbility(daoId);
        OwnerStorage.layout().ownerInfos[daoId].ownerForDaoEditInformation = NftIdentifier(daoNftAddress, tokenId);

        emit DaoEditParameterNftSet(daoId, daoNftAddress, tokenId);
    }

    function setDaoEditStrategyPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkEditStrategyAbility(daoId);
        OwnerStorage.layout().ownerInfos[daoId].ownerForDaoEditInformation = NftIdentifier(daoNftAddress, tokenId);

        emit DaoEditStrategyNftSet(daoId, daoNftAddress, tokenId);
    }

    function setDaoRewardPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkEditDaoCreatorRewardAbility(daoId);
        OwnerStorage.layout().ownerInfos[daoId].ownerForDaoEditInformation = NftIdentifier(daoNftAddress, tokenId);

        emit DaoRewardNftSet(daoId, daoNftAddress, tokenId);
    }

    function _daoRestart(bytes32 daoId, uint256 newRemainingRound) internal {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        RoundStorage.RoundInfo storage roundInfo = RoundStorage.layout().roundInfos[daoId];
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256 currentRound = IPDRound(address(this)).getDaoCurrentRound(daoId);
        uint256 passedRound = IPDProtocolReadable(address(this)).getDaoPassedRound(daoId);

        roundInfo.roundInLastModify = currentRound;
        roundInfo.blockInLastModify = block.number;
        //delete RewardStorage.layout().rewardInfos[daoId].activeRounds;
        daoInfo.mintableRound = newRemainingRound + passedRound;
        RoundStorage.layout().roundInfos[daoId].lastRestartRoundMinusOne = currentRound - 1;
        delete PriceStorage.layout().daoMaxPrices[daoId];
        if (rewardInfo.isProgressiveJackpot) {
            if (
                rewardInfo.activeRounds.length == 0
                    || rewardInfo.activeRounds[rewardInfo.activeRounds.length - 1] != currentRound
                        && rewardInfo.activeRounds[rewardInfo.activeRounds.length - 1] != currentRound - 1
            ) {
                if (currentRound > 1) {
                    rewardInfo.activeRounds.push(currentRound - 1);
                }
            }
        }

        bytes32[] memory canvases = IPDProtocolReadable(address(this)).getDaoCanvases(daoId);
        for (uint256 i; i < canvases.length;) {
            delete PriceStorage.layout().canvasLastMintInfos[canvases[i]];
            unchecked {
                ++i;
            }
        }
        emit DaoRestart(daoId, newRemainingRound, block.number);
    }

    function _checkEditParamAbility(bytes32 daoId) internal view {
        OwnerStorage.OwnerInfo storage ownerInfo = OwnerStorage.layout().ownerInfos[daoId];
        address nftAddress = ownerInfo.ownerForDaoEditParameter.erc721Address;
        uint256 tokenId = ownerInfo.ownerForDaoEditParameter.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkEditStrategyAbility(bytes32 daoId) internal view {
        OwnerStorage.OwnerInfo storage ownerInfo = OwnerStorage.layout().ownerInfos[daoId];
        address nftAddress = ownerInfo.ownerForDaoEditStrategy.erc721Address;
        uint256 tokenId = ownerInfo.ownerForDaoEditStrategy.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkEditInformationAbility(bytes32 daoId) internal view {
        OwnerStorage.OwnerInfo storage ownerInfo = OwnerStorage.layout().ownerInfos[daoId];
        address nftAddress = ownerInfo.ownerForDaoEditInformation.erc721Address;
        uint256 tokenId = ownerInfo.ownerForDaoEditInformation.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkEditDaoCreatorRewardAbility(bytes32 daoId) internal view {
        OwnerStorage.OwnerInfo storage ownerInfo = OwnerStorage.layout().ownerInfos[daoId];
        address nftAddress = ownerInfo.ownerForDaoReward.erc721Address;
        uint256 tokenId = ownerInfo.ownerForDaoReward.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    // function _checkSetAbility(bytes32 daoId, bool ownerSet, bool v13set) internal view {
    //     BasicDaoStorage.BasicDaoInfo memory basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
    //     SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

    //     if (basicDaoInfo.version < 12) {
    //         if (msg.sender == settingsStorage.createProjectProxy || msg.sender == address(this)) {
    //             return;
    //         }
    //         if (
    //             DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO
    //                 && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
    //         ) revert BasicDaoLocked();
    //         if (ownerSet && msg.sender == settingsStorage.ownerProxy.ownerOf(daoId)) return;
    //     } else {
    //         if (!v13set) revert VersionDenied();
    //         if (msg.sender == address(this)) return;
    //         bytes32 ancestor = InheritTreeStorage.layout().inheritTreeInfos[daoId].ancestor;
    //         if (
    //             ownerSet
    //                 && (
    //                     msg.sender == settingsStorage.ownerProxy.ownerOf(daoId)
    //                         || msg.sender == settingsStorage.ownerProxy.ownerOf(ancestor)
    //                 )
    //         ) return;
    //     }
    //     revert NotDaoOwner();
    // }

    function _checkTreasuryNFTOwner(bytes32 daoId, address owner) internal view { }
}
