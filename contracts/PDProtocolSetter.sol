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
    SetChildrenParam
} from "contracts/interface/D4AStructs.sol";
import { PriceTemplateType, DaoTag } from "contracts/interface/D4AEnums.sol";
import "contracts/interface/D4AErrors.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";

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

import { D4AERC20 } from "./D4AERC20.sol";

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
        _checkSetAbility(daoId, true, true);

        super.setMintCapAndPermission(
            daoId, daoMintCap, userMintCapParams, nftMinterCapInfo, whitelist, blacklist, unblacklist
        );
    }

    // 修改Dao参数方法
    // function setDaoParams(SetDaoParam memory vars) public override(ID4AProtocolSetter, D4AProtocolSetter) {
    //     _checkSetAbility(vars.daoId, true, false);
    //     super.setDaoParams(vars);
    // }

    function setDaoNftMaxSupply(
        bytes32 daoId,
        uint256 newMaxSupply
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        _checkSetAbility(daoId, true, true);

        super.setDaoNftMaxSupply(daoId, newMaxSupply);
    }

    // function setDaoMintableRound(
    //     bytes32 daoId,
    //     uint256 newMintableRound
    // )
    //     public
    //     override(ID4AProtocolSetter, D4AProtocolSetter)
    // {
    //     _checkSetAbility(daoId, true, false);

    //     super.setDaoMintableRound(daoId, newMintableRound);
    // }

    function setDaoFloorPrice(
        bytes32 daoId,
        uint256 newFloorPrice
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        _checkSetAbility(daoId, true, true);

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
        _checkSetAbility(daoId, true, true);
        super.setDaoPriceTemplate(daoId, priceTemplateType, nftPriceFactor);
    }

    function setTemplate(
        bytes32 daoId,
        TemplateParam calldata templateParam
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        _checkSetAbility(daoId, false, true);
        super.setTemplate(daoId, templateParam);
    }

    // function setRatio(
    //     bytes32 daoId,
    //     uint256 daoCreatorERC20Ratio,
    //     uint256 canvasCreatorERC20Ratio,
    //     uint256 nftMinterERC20Ratio,
    //     uint256 daoFeePoolETHRatio,
    //     uint256 daoFeePoolETHRatioFlatPrice
    // )
    //     public
    //     override(ID4AProtocolSetter, D4AProtocolSetter)
    // {
    //     _checkSetAbility(daoId, true, false);

    //     super.setRatio(
    //         daoId,
    //         daoCreatorERC20Ratio,
    //         canvasCreatorERC20Ratio,
    //         nftMinterERC20Ratio,
    //         daoFeePoolETHRatio,
    //         daoFeePoolETHRatioFlatPrice
    //     );
    // }

    function setCanvasRebateRatioInBps(
        bytes32 canvasId,
        uint256 newCanvasRebateRatioInBps
    )
        public
        payable
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        bytes32 daoId = D4AProtocolReadable(address(this)).getCanvasDaoId(canvasId);
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].version > 12) revert VersionDenied();

        if (
            DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO
                && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
        ) revert BasicDaoLocked();

        super.setCanvasRebateRatioInBps(canvasId, newCanvasRebateRatioInBps);
    }

    function setRoundMintCap(
        bytes32 daoId,
        uint256 dailyMintCap
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        _checkSetAbility(daoId, true, true);

        super.setRoundMintCap(daoId, dailyMintCap);
    }

    // function setDaoTokenSupply(
    //     bytes32 daoId,
    //     uint256 addedDaoToken
    // )
    //     public
    //     override(ID4AProtocolSetter, D4AProtocolSetter)
    // {
    //     _checkSetAbility(daoId, true, false);
    //     super.setDaoTokenSupply(daoId, addedDaoToken);
    // }

    function setWhitelistMintCap(
        bytes32 daoId,
        address whitelistUser,
        uint32 whitelistUserMintCap
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        _checkSetAbility(daoId, true, true);
        super.setWhitelistMintCap(daoId, whitelistUser, whitelistUserMintCap);
    }

    function setDaoUnifiedPrice(
        bytes32 daoId,
        uint256 newUnifiedPrice
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        _checkSetAbility(daoId, true, true);
        super.setDaoUnifiedPrice(daoId, newUnifiedPrice);
    }
    // 1.3 add--------------------------------------
    // check set ability, protocol always can set

    function _checkSetAbility(bytes32 daoId, bool ownerSet, bool v13set) internal view {
        BasicDaoStorage.BasicDaoInfo memory basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

        if (basicDaoInfo.version < 12) {
            if (msg.sender == settingsStorage.createProjectProxy || msg.sender == address(this)) {
                return;
            }
            if (
                DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.BASIC_DAO
                    && !BasicDaoStorage.layout().basicDaoInfos[daoId].unlocked
            ) revert BasicDaoLocked();
            if (ownerSet && msg.sender == settingsStorage.ownerProxy.ownerOf(daoId)) return;
        } else {
            if (!v13set) revert VersionDenied();
            if (msg.sender == address(this)) return;
            bytes32 ancestor = InheritTreeStorage.layout().inheritTreeInfos[daoId].ancestor;
            if (
                ownerSet
                    && (
                        msg.sender == settingsStorage.ownerProxy.ownerOf(daoId)
                            || msg.sender == settingsStorage.ownerProxy.ownerOf(ancestor)
                    )
            ) return;
        }
        revert NotDaoOwner();
    }

    function setDaoParams(SetDaoParam calldata vars) public {
        _checkSetAbility(vars.daoId, true, true);
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        bytes32 ancestor = InheritTreeStorage.layout().inheritTreeInfos[vars.daoId].ancestor;
        if (msg.sender == settingsStorage.ownerProxy.ownerOf(ancestor)) {
            setInitialTokenSupplyForSubDao(vars.daoId, vars.initialTokenSupply);
        } //1
        setDaoRemainingRound(vars.daoId, vars.remainingRound); //2
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

        _checkSetAbility(daoId, true, true);

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
        _checkSetAbility(daoId, true, true);
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
        InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        bytes32 ancestor = treeInfo.ancestor;
        address daoToken = DaoStorage.layout().daoInfos[ancestor].token;

        if (msg.sender != settingsStorage.ownerProxy.ownerOf(ancestor)) revert NotDaoOwner();
        BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();
        if (!InheritTreeStorage.layout().inheritTreeInfos[ancestor].isAncestorDao) revert NotAncestorDao();

        address daoAssetPool = basicDaoStorage.basicDaoInfos[daoId].daoAssetPool;
        D4AERC20(daoToken).mint(daoAssetPool, initialTokenSupply);
        DaoStorage.layout().daoInfos[daoId].tokenMaxSupply += initialTokenSupply;

        if (D4AERC20(daoToken).totalSupply() > settingsStorage.tokenMaxSupply) revert SupplyOutOfRange();

        emit InitialTokenSupplyForSubDaoSet(daoId, initialTokenSupply);
    }

    function setDaoRemainingRound(bytes32 daoId, uint256 newRemainingRound) public {
        _checkSetAbility(daoId, true, true);
        if (newRemainingRound == 0) return;
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        uint256 remainingRound = IPDProtocolReadable(address(this)).getDaoRemainingRound(daoId);
        if (remainingRound == 0) {
            RoundStorage.RoundInfo storage roundInfo = RoundStorage.layout().roundInfos[daoId];
            roundInfo.roundInLastModify = 1;
            roundInfo.blockInLastModify = block.number;
            delete RewardStorage.layout().rewardInfos[daoId].activeRounds;
            daoInfo.mintableRound = newRemainingRound;
            delete PriceStorage.layout().daoMaxPrices[daoId];
            bytes32[] memory canvases = IPDProtocolReadable(address(this)).getDaoCanvases(daoId);
            for (uint256 i; i < canvases.length;) {
                delete PriceStorage.layout().canvasLastMintInfos[canvases[i]];
                unchecked {
                    ++i;
                }
            }
            emit DaoRestart(daoId, newRemainingRound, block.number);
        } else {
            daoInfo.mintableRound += newRemainingRound;
            daoInfo.mintableRound -= remainingRound;
            emit DaoMintableRoundSet(daoId, newRemainingRound);
        }
    }
}
