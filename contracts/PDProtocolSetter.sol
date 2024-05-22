// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    UserMintCapParam,
    TemplateParam,
    Whitelist,
    Blacklist,
    SetDaoParam,
    NftMinterCapInfo,
    NftMinterCapIdInfo,
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
import { TreeStorage } from "contracts/storages/TreeStorage.sol";
import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IPDProtocolSetter } from "./interface/IPDProtocolSetter.sol";
import { IPDProtocolReadable } from "./interface/IPDProtocolReadable.sol";
import { IPDRound } from "contracts/interface/IPDRound.sol";
import { OwnerStorage } from "contracts/storages/OwnerStorage.sol";
import { SetterChecker } from "contracts/SetterChecker.sol";
import { D4AERC20 } from "./D4AERC20.sol";
//import "forge-std/Test.sol";

contract PDProtocolSetter is IPDProtocolSetter, D4AProtocolSetter, SetterChecker {
    // 修改黑白名单方法
    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        NftMinterCapInfo[] calldata nftMinterCapInfo,
        NftMinterCapIdInfo[] calldata nftMinterCapIdInfo,
        Whitelist memory whitelist,
        Blacklist memory blacklist,
        Blacklist memory unblacklist
    )
        public
        override(ID4AProtocolSetter, D4AProtocolSetter)
    {
        // _checkSetAbility(daoId, true, true);
        _checkEditStrategyAbility(daoId);

        super.setMintCapAndPermission(
            daoId,
            daoMintCap,
            userMintCapParams,
            nftMinterCapInfo,
            nftMinterCapIdInfo,
            whitelist,
            blacklist,
            unblacklist
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
        if (msg.sender != address(this)) {
            revert OnlyProtocolCanSet();
        }
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
        require(vars.childrenDaoId.length == vars.outputRatios.length, "invalid length");
        require(vars.childrenDaoId.length == vars.inputRatios.length, "invalid length");

        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);

        if (BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode) {
            emit ChildrenSet(daoId, new bytes32[](0), new uint256[](0), new uint256[](0), 0, 10_000, 0);
            return;
        }

        uint256 sumOutput;
        uint256 sumInput;
        TreeStorage.TreeInfo storage treeInfo = TreeStorage.layout().treeInfos[daoId];

        for (uint256 i = 0; i < vars.childrenDaoId.length;) {
            _checkDaoMember(treeInfo.ancestor, vars.childrenDaoId[i]);
            sumOutput += vars.outputRatios[i];
            sumInput += vars.inputRatios[i];
            unchecked {
                ++i;
            }
        }
        sumOutput += vars.selfRewardOutputRatio + vars.treasuryOutputRatio;
        sumInput += vars.redeemPoolInputRatio + vars.treasuryInputRatio + vars.selfRewardInputRatio;

        if (sumOutput > BASIS_POINT) revert InvalidChildrenDaoRatio();
        if (sumInput > BASIS_POINT) revert InvalidChildrenDaoRatio();

        treeInfo.children = vars.childrenDaoId;
        treeInfo.childrenDaoOutputRatios = vars.outputRatios;
        treeInfo.childrenDaoInputRatios = vars.inputRatios;

        treeInfo.redeemPoolInputRatio = vars.redeemPoolInputRatio;
        treeInfo.selfRewardOutputRatio = vars.selfRewardOutputRatio;
        treeInfo.selfRewardInputRatio = vars.selfRewardInputRatio;
        treeInfo.treasuryInputRatio = vars.treasuryInputRatio;
        treeInfo.treasuryOutputRatio = vars.treasuryOutputRatio;

        emit ChildrenSet(
            daoId,
            vars.childrenDaoId,
            vars.outputRatios,
            vars.inputRatios,
            vars.redeemPoolInputRatio,
            vars.selfRewardOutputRatio,
            vars.selfRewardInputRatio
        );
    }

    //in PD1.3, we always use ratios w.r.t all 4 roles

    function setRatio(bytes32 daoId, AllRatioParam calldata vars) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        // _checkSetAbility(daoId, true, true);
        _checkEditParamAbility(daoId);
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode) {
            emit RatioSet(daoId, AllRatioParam(0, 0, 0, 0, 0, 0, 0, 0, 10_000, 0, 0, 0, 0, 0));
            return;
        }
        TreeStorage.TreeInfo storage treeInfo = TreeStorage.layout().treeInfos[daoId];
        if (
            vars.canvasCreatorMintFeeRatio + vars.assetPoolMintFeeRatio + vars.redeemPoolMintFeeRatio
                + vars.treasuryMintFeeRatio + l.protocolMintFeeRatioInBps != BASIS_POINT
        ) revert InvalidMintFeeRatio();
        treeInfo.canvasCreatorMintFeeRatio = vars.canvasCreatorMintFeeRatio;
        treeInfo.assetPoolMintFeeRatio = vars.assetPoolMintFeeRatio;
        treeInfo.redeemPoolMintFeeRatio = vars.redeemPoolMintFeeRatio;
        treeInfo.treasuryMintFeeRatio = vars.treasuryMintFeeRatio;
        if (
            vars.canvasCreatorMintFeeRatioFiatPrice + vars.assetPoolMintFeeRatioFiatPrice
                + vars.redeemPoolMintFeeRatioFiatPrice + vars.treasuryMintFeeRatioFiatPrice + l.protocolMintFeeRatioInBps
                != BASIS_POINT
        ) revert InvalidMintFeeRatio();
        treeInfo.canvasCreatorMintFeeRatioFiatPrice = vars.canvasCreatorMintFeeRatioFiatPrice;
        treeInfo.assetPoolMintFeeRatioFiatPrice = vars.assetPoolMintFeeRatioFiatPrice;
        treeInfo.redeemPoolMintFeeRatioFiatPrice = vars.redeemPoolMintFeeRatioFiatPrice;
        treeInfo.treasuryMintFeeRatioFiatPrice = vars.treasuryMintFeeRatioFiatPrice;
        if (
            vars.minterOutputRewardRatio + vars.canvasCreatorOutputRewardRatio + vars.daoCreatorOutputRewardRatio
                + l.protocolOutputRewardRatio != BASIS_POINT
        ) revert InvalidOutputRewardRatio();

        treeInfo.minterOutputRewardRatio = vars.minterOutputRewardRatio;
        treeInfo.canvasCreatorOutputRewardRatio = vars.canvasCreatorOutputRewardRatio;
        treeInfo.daoCreatorOutputRewardRatio = vars.daoCreatorOutputRewardRatio;
        if (
            vars.minterInputRewardRatio + vars.canvasCreatorInputRewardRatio + vars.daoCreatorInputRewardRatio
                + l.protocolInputRewardRatio != BASIS_POINT
        ) {
            revert InvalidInputRewardRatio();
        }
        treeInfo.minterInputRewardRatio = vars.minterInputRewardRatio;
        treeInfo.canvasCreatorInputRewardRatio = vars.canvasCreatorInputRewardRatio;
        treeInfo.daoCreatorInputRewardRatio = vars.daoCreatorInputRewardRatio;
        emit RatioSet(daoId, vars);
    }

    function setDaoRemainingRound(bytes32 daoId, uint256 newRemainingRound) public {
        _checkEditParamAbility(daoId);
        if (newRemainingRound == 0) return;
        //for infinite mode, we do not need to set remaining round, because it will be set when turn off infinite mode
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

    //1.6add-------------------------------------------
    function setTopUpInputSplitRatio(
        bytes32 daoId,
        uint256 defaultInputRatio,
        bytes32[] calldata subDaoIds,
        uint256[] calldata inputRatios
    )
        public
    {
        _checkTreasurySetTopUpRatioAbility(daoId);
        if (subDaoIds.length != inputRatios.length) revert InvalidLength();

        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        poolInfo.defaultTopUpInputToRedeemPoolRatio = defaultInputRatio;
        for (uint256 i; i < subDaoIds.length;) {
            _checkDaoMember(daoId, subDaoIds[i]);
            BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[subDaoIds[i]];
            basicDaoInfo.topUpInputToRedeemPoolRatio = inputRatios[i];
            unchecked {
                ++i;
            }
        }
        emit TopUpInputSplitRatioSet(daoId, defaultInputRatio, subDaoIds, inputRatios);
    }

    function setTopUpOutputSplitRatio(
        bytes32 daoId,
        uint256 defaultOutputRatio,
        bytes32[] calldata subDaoIds,
        uint256[] calldata outputRatios
    )
        public
    {
        _checkTreasurySetTopUpRatioAbility(daoId);
        if (subDaoIds.length != outputRatios.length) revert InvalidLength();

        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        poolInfo.defaultTopUpOutputToTreasuryRatio = defaultOutputRatio;
        for (uint256 i; i < subDaoIds.length;) {
            _checkDaoMember(daoId, subDaoIds[i]);
            BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[subDaoIds[i]];
            basicDaoInfo.topUpOutputToTreasuryRatio = outputRatios[i];
            unchecked {
                ++i;
            }
        }
        emit TopUpOutputSplitRatioSet(daoId, defaultOutputRatio, subDaoIds, outputRatios);
    }

    function setDefaultTopUpInputToRedeemPoolRatio(bytes32 daoId, uint256 inputToRedeemPoolRatio) public {
        _checkTreasurySetTopUpRatioAbility(daoId);
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        poolInfo.defaultTopUpInputToRedeemPoolRatio = inputToRedeemPoolRatio;

        emit DefaultTopUpInputToRedeemPoolRatioSet(daoId, inputToRedeemPoolRatio);
    }

    function setDefaultTopUpOutputToTreasuryRatio(bytes32 daoId, uint256 outputToTreasuryRatio) public {
        _checkTreasurySetTopUpRatioAbility(daoId);
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];
        poolInfo.defaultTopUpOutputToTreasuryRatio = outputToTreasuryRatio;

        emit DefaultTopUpOutputToTreasuryRatioSet(daoId, outputToTreasuryRatio);
    }

    function setDaoTopUpInputToRedeemPoolRatio(bytes32 daoId, uint256 inputToRedeemPoolRatio) public {
        _checkTreasurySetTopUpRatioAbility(daoId);

        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        basicDaoInfo.topUpInputToRedeemPoolRatio = inputToRedeemPoolRatio;

        emit DaoTopUpInputToRedeemPoolRatioSet(daoId, inputToRedeemPoolRatio);
    }

    function setDaoTopUpOutputToTreasuryRatio(bytes32 daoId, uint256 outputToTreasuryRatio) public {
        _checkTreasurySetTopUpRatioAbility(daoId);

        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        basicDaoInfo.topUpOutputToTreasuryRatio = outputToTreasuryRatio;

        emit DaoTopUpOutputToTreasuryRatioSet(daoId, outputToTreasuryRatio);
    }

    function setDaoControlPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        setDaoEditInformationPermission(daoId, daoNftAddress, tokenId);
        setDaoEditParamPermission(daoId, daoNftAddress, tokenId);
        setDaoEditStrategyPermission(daoId, daoNftAddress, tokenId);
        setDaoRewardPermission(daoId, daoNftAddress, tokenId);
    }

    function setDaoEditInformationPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkEditInformationAbility(daoId);
        OwnerStorage.layout().daoOwnerInfos[daoId].daoEditInformationOwner = NftIdentifier(daoNftAddress, tokenId);
        emit DaoEditInformationNftOwnerSet(daoId, daoNftAddress, tokenId);
    }

    function setDaoEditParamPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkEditParamAbility(daoId);
        OwnerStorage.layout().daoOwnerInfos[daoId].daoEditParameterOwner = NftIdentifier(daoNftAddress, tokenId);

        emit DaoEditParameterNftOwnerSet(daoId, daoNftAddress, tokenId);
    }

    function setDaoEditStrategyPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkEditStrategyAbility(daoId);
        OwnerStorage.layout().daoOwnerInfos[daoId].daoEditStrategyOwner = NftIdentifier(daoNftAddress, tokenId);

        emit DaoEditStrategyNftOwnerSet(daoId, daoNftAddress, tokenId);
    }

    function setDaoRewardPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkEditDaoCreatorRewardAbility(daoId);
        OwnerStorage.layout().daoOwnerInfos[daoId].daoRewardOwner = NftIdentifier(daoNftAddress, tokenId);
        emit DaoRewardNftOwnerSet(daoId, daoNftAddress, tokenId);
    }

    function setTreasuryControlPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        setTreasuryEditInformationPermission(daoId, daoNftAddress, tokenId);
        setTreasuryTransferAssetPermission(daoId, daoNftAddress, tokenId);
        setTreasurySetTopUpRatioPermission(daoId, daoNftAddress, tokenId);
    }

    function setTreasuryEditInformationPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkTreasuryEditInformationAbility(daoId);
        OwnerStorage.layout().treasuryOwnerInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool]
            .treasuryEditInformationOwner = NftIdentifier(daoNftAddress, tokenId);
        emit TreasuryEditInformationOwnerSet(daoId, daoNftAddress, tokenId);
    }

    function setTreasuryTransferAssetPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkTreasuryTransferAssetAbility(daoId);
        OwnerStorage.layout().treasuryOwnerInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool]
            .treasuryTransferAssetOwner = NftIdentifier(daoNftAddress, tokenId);
        emit TreasuryTransferAssetOwnerSet(daoId, daoNftAddress, tokenId);
    }

    function setTreasurySetTopUpRatioPermission(bytes32 daoId, address daoNftAddress, uint256 tokenId) public {
        _checkTreasurySetTopUpRatioAbility(daoId);
        OwnerStorage.layout().treasuryOwnerInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool]
            .treasurySetTopUpRatioOwner = NftIdentifier(daoNftAddress, tokenId);
        emit TreasurySetTopUpRatioOwnerSet(daoId, daoNftAddress, tokenId);
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
        //Todo do not push active round for dao restart, use lastRestartRoundMinuesOne instead
        //we can not do this since we can not handle the round when turn on infinite mode
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

    function _checkDaoMember(bytes32 ancestor, bytes32 subDaoId) internal view {
        if (TreeStorage.layout().treeInfos[subDaoId].ancestor != ancestor) {
            revert InvalidDaoAncestor(subDaoId);
        }
    }
}
