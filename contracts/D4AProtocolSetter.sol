// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { FixedPointMathLib as Math } from "solady/utils/FixedPointMathLib.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol";

import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import {
    UserMintCapParam,
    TemplateParam,
    DaoMintInfo,
    Whitelist,
    Blacklist,
    SetDaoParam,
    NftMinterCapInfo,
    NftMinterCap
} from "contracts/interface/D4AStructs.sol";
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import "contracts/interface/D4AErrors.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { CanvasStorage } from "contracts/storages/CanvasStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RewardStorage } from "./storages/RewardStorage.sol";
import { SettingsStorage } from "./storages/SettingsStorage.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";
import { ID4AProtocolReadable } from "./interface/ID4AProtocolReadable.sol";
import { IPDProtocolReadable } from "./interface/IPDProtocolReadable.sol";
import { IPDRound } from "./interface/IPDRound.sol";

contract D4AProtocolSetter is ID4AProtocolSetter {
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
        virtual
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        DaoMintInfo storage daoMintInfo = DaoStorage.layout().daoInfos[daoId].daoMintInfo;
        daoMintInfo.daoMintCap = daoMintCap;
        address daoNft = DaoStorage.layout().daoInfos[daoId].nft;

        uint256 length = userMintCapParams.length;
        for (uint256 i; i < length;) {
            daoMintInfo.userMintInfos[userMintCapParams[i].minter].mintCap = userMintCapParams[i].mintCap;
            unchecked {
                ++i;
            }
        }
        delete DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo;

        require(DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo.length == 0, "delete failed");
        // length = DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo.length;
        // for (uint256 i; i < length;) {
        //     DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo.pop();
        //     unchecked {
        //         ++i;
        //     }
        // }

        length = nftMinterCapInfo.length;
        for (uint256 i; i < length;) {
            if (nftMinterCapInfo[i].nftAddress == address(0)) {
                DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo.push(
                    NftMinterCapInfo(daoNft, nftMinterCapInfo[i].nftMintCap)
                );
            } else {
                DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo.push(nftMinterCapInfo[i]);
            }
            unchecked {
                ++i;
            }
        }

        emit MintCapSet(daoId, daoMintCap, userMintCapParams, nftMinterCapInfo);

        l.permissionControl.modifyPermission(daoId, whitelist, blacklist, unblacklist);
    }

    // 修改Dao参数
    // function setDaoParams(SetDaoParam memory vars) public virtual {
    //     SettingsStorage.Layout storage l = SettingsStorage.layout();
    //     setDaoNftMaxSupply(vars.daoId, l.nftMaxSupplies[vars.nftMaxSupplyRank]); //3
    //     setDaoFloorPrice(vars.daoId, vars.daoFloorPriceRank == 9999 ? 0 : l.daoFloorPrices[vars.daoFloorPriceRank]);
    // //5
    //     setDaoPriceTemplate(vars.daoId, vars.priceTemplateType, vars.nftPriceFactor); //6
    //     setRatio(
    //         vars.daoId,
    //         vars.daoCreatorERC20Ratio,
    //         vars.canvasCreatorERC20Ratio,
    //         vars.nftMinterERC20Ratio,
    //         vars.daoFeePoolETHRatio,
    //         vars.daoFeePoolETHRatioFlatPrice
    //     ); // 8 mint fee , 9 reward roles ratio
    //     setDailyMintCap(vars.daoId, vars.dailyMintCap); //4

    //     setDaoTokenSupply(vars.daoId, vars.addedDaoToken); //1
    //     setDaoMintableRound(vars.daoId, l.mintableRounds[vars.mintableRoundRank]); //2

    //     //7:set children 7

    //     setDaoUnifiedPrice(vars.daoId, vars.unifiedPrice);
    // }

    function setDaoNftMaxSupply(bytes32 daoId, uint256 newMaxSupply) public virtual {
        DaoStorage.layout().daoInfos[daoId].nftMaxSupply = newMaxSupply;

        emit DaoNftMaxSupplySet(daoId, newMaxSupply);
    }

    // function setDaoMintableRound(bytes32 daoId, uint256 newMintableRound) public virtual {
    //     DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
    //     if (daoInfo.mintableRound == newMintableRound) return;
    //     SettingsStorage.Layout storage l = SettingsStorage.layout();
    //     RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
    //     RewardStorage.RewardCheckpoint storage rewardCheckpoint =
    //         rewardInfo.rewardCheckpoints[rewardInfo.rewardCheckpoints.length - 1];
    //     uint256 currentRound = l.drb.currentRound();
    //     uint256 oldMintableRound = daoInfo.mintableRound;
    //     int256 mintableRoundDelta = SafeCastLib.toInt256(newMintableRound) - SafeCastLib.toInt256(oldMintableRound);
    //     if (newMintableRound > l.maxMintableRound) revert ExceedMaxMintableRound();
    //     if (rewardInfo.isProgressiveJackpot) {
    //         if (currentRound >= rewardCheckpoint.startRound + rewardCheckpoint.totalRound) {
    //             revert ExceedDaoMintableRound();
    //         }
    //         if (
    //             SafeCastLib.toInt256(rewardCheckpoint.startRound + rewardCheckpoint.totalRound) + mintableRoundDelta
    //                 < SafeCastLib.toInt256(currentRound)
    //         ) revert NewMintableRoundsFewerThanRewardIssuedRounds();
    //     } else {
    //         uint256 finalActiveRound;
    //         {
    //             for (uint256 i = rewardInfo.rewardCheckpoints.length - 1; ~i != 0;) {
    //                 uint256[] storage activeRounds = rewardInfo.rewardCheckpoints[i].activeRounds;
    //                 if (activeRounds.length > 0) finalActiveRound = activeRounds[activeRounds.length - 1];
    //                 unchecked {
    //                     --i;
    //                 }
    //             }
    //         }

    //         if (rewardCheckpoint.activeRounds.length >= rewardCheckpoint.totalRound && currentRound >
    // finalActiveRound)
    //         {
    //             revert ExceedDaoMintableRound();
    //         }
    //         if (
    //             SafeCastLib.toInt256(rewardCheckpoint.totalRound) + mintableRoundDelta
    //                 < SafeCastLib.toInt256(rewardCheckpoint.activeRounds.length)
    //         ) {
    //             revert NewMintableRoundsFewerThanRewardIssuedRounds();
    //         }
    //     }

    //     daoInfo.mintableRound = newMintableRound;

    //     (bool succ,) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
    //         abi.encodeWithSelector(IRewardTemplate.setRewardCheckpoint.selector, daoId, mintableRoundDelta, 0)
    //     );
    //     require(succ);

    //     emit DaoMintableRoundSet(daoId, newMintableRound);
    // }

    function setDaoFloorPrice(bytes32 daoId, uint256 newFloorPrice) public virtual {
        PriceStorage.Layout storage priceStorage = PriceStorage.layout();
        if (priceStorage.daoFloorPrices[daoId] == newFloorPrice) return;
        if (newFloorPrice == 0) revert CannotUseZeroFloorPrice();
        bytes32[] memory canvases = DaoStorage.layout().daoInfos[daoId].canvases;
        uint256 length = canvases.length;
        uint256 currentRound = IPDRound(address(this)).getDaoCurrentRound(daoId);
        for (uint256 i; i < length;) {
            uint256 canvasNextPrice = IPDProtocolReadable(address(this)).getCanvasNextPrice(daoId, canvases[i]);
            if (canvasNextPrice >= newFloorPrice) {
                //recall that currentRound must begin at 1
                priceStorage.canvasLastMintInfos[canvases[i]] =
                    PriceStorage.MintInfo({ round: currentRound - 1, price: canvasNextPrice });
            }
            unchecked {
                ++i;
            }
        }
        priceStorage.daoMaxPrices[daoId] = PriceStorage.MintInfo({ round: currentRound, price: newFloorPrice });
        priceStorage.daoFloorPrices[daoId] = newFloorPrice;

        emit DaoFloorPriceSet(daoId, newFloorPrice);
    }

    function setDaoPriceTemplate(
        bytes32 daoId,
        PriceTemplateType priceTemplateType,
        uint256 nftPriceFactor
    )
        public
        virtual
    {
        if (priceTemplateType == PriceTemplateType.EXPONENTIAL_PRICE_VARIATION) require(nftPriceFactor >= 10_000);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        daoInfo.priceTemplateType = priceTemplateType;
        daoInfo.nftPriceFactor = nftPriceFactor;

        emit DaoPriceTemplateSet(daoId, priceTemplateType, nftPriceFactor);
    }

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) public virtual {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.ownerProxy.ownerOf(daoId) && msg.sender != address(this)) revert NotDaoOwner();

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        daoInfo.priceTemplateType = templateParam.priceTemplateType;
        daoInfo.nftPriceFactor = templateParam.priceFactor;
        daoInfo.rewardTemplateType = templateParam.rewardTemplateType;
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];

        rewardInfo.rewardDecayFactor = templateParam.rewardDecayFactor;
        rewardInfo.isProgressiveJackpot = templateParam.isProgressiveJackpot;
        if (uint256(templateParam.rewardTemplateType) < 2) revert InvalidTemplate();

        emit DaoTemplateSet(daoId, templateParam);
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
    //     virtual
    // {
    //     SettingsStorage.Layout storage l = SettingsStorage.layout();
    //     if (
    //         msg.sender != l.ownerProxy.ownerOf(daoId) && msg.sender != l.createProjectProxy
    //             && msg.sender != address(this)
    //     ) revert NotDaoOwner();

    //     if (
    //         daoFeePoolETHRatioFlatPrice > BASIS_POINT - l.protocolMintFeeRatioInBps
    //             || daoFeePoolETHRatio > daoFeePoolETHRatioFlatPrice
    //     ) revert InvalidETHRatio();

    //     RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
    //     uint256 sum = daoCreatorERC20Ratio + canvasCreatorERC20Ratio + nftMinterERC20Ratio;

    //     //store ratio respect to 3 roles, DaoCreator + CanvasCreator + NftMinter
    //     uint256 daoCreatorERC20RatioInBps = Math.fullMulDivUp(daoCreatorERC20Ratio, BASIS_POINT, sum);
    //     uint256 canvasCreatorERC20RatioInBps = Math.fullMulDivUp(canvasCreatorERC20Ratio, BASIS_POINT, sum);
    //     rewardInfo.daoCreatorERC20RatioInBps = daoCreatorERC20RatioInBps;
    //     rewardInfo.canvasCreatorERC20RatioInBps = canvasCreatorERC20RatioInBps;

    //     DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
    //     daoInfo.daoFeePoolETHRatioInBps = daoFeePoolETHRatio;
    //     daoInfo.daoFeePoolETHRatioInBpsFlatPrice = daoFeePoolETHRatioFlatPrice;

    //     emit DaoRatioSet(
    //         daoId,
    //         daoCreatorERC20Ratio,
    //         canvasCreatorERC20Ratio,
    //         nftMinterERC20Ratio,
    //         daoFeePoolETHRatio,
    //         daoFeePoolETHRatioFlatPrice
    //     );
    // }

    function setCanvasRebateRatioInBps(bytes32 canvasId, uint256 newCanvasRebateRatioInBps) public payable virtual {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.ownerProxy.ownerOf(canvasId)) revert NotCanvasOwner();
        require(newCanvasRebateRatioInBps <= 10_000);
        CanvasStorage.layout().canvasInfos[canvasId].canvasRebateRatioInBps = newCanvasRebateRatioInBps;

        emit CanvasRebateRatioInBpsSet(canvasId, newCanvasRebateRatioInBps);
    }

    function setRoundMintCap(bytes32 daoId, uint256 roundMintCap) public virtual {
        BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();
        basicDaoStorage.basicDaoInfos[daoId].roundMintCap = roundMintCap;

        emit DailyMintCapSet(daoId, roundMintCap);
    }

    // function setDaoTokenSupply(bytes32 daoId, uint256 addedDaoToken) public virtual {
    //     SettingsStorage.Layout storage l = SettingsStorage.layout();
    //     if (addedDaoToken == 0) return;
    //     DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

    //     // 追加tokenMaxSupply并判断总数小于10亿
    //     if (daoInfo.tokenMaxSupply + addedDaoToken > 1_000_000_000 ether) {
    //         revert SupplyOutOfRange();
    //     } else {
    //         daoInfo.tokenMaxSupply += addedDaoToken;
    //     }

    //     (bool succ,) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
    //         abi.encodeWithSelector(IRewardTemplate.setRewardCheckpoint.selector, daoId, 0, addedDaoToken)
    //     );
    //     require(succ);

    //     emit DaoTokenSupplySet(daoId, addedDaoToken);
    // }

    function setWhitelistMintCap(bytes32 daoId, address whitelistUser, uint32 whitelistUserMintCap) public virtual {
        DaoMintInfo storage daoMintInfo = DaoStorage.layout().daoInfos[daoId].daoMintInfo;

        daoMintInfo.userMintInfos[whitelistUser].mintCap = whitelistUserMintCap;

        emit WhiteListMintCapSet(daoId, whitelistUser, whitelistUserMintCap);
    }

    function setDaoUnifiedPrice(bytes32 daoId, uint256 newUnifiedPrice) public virtual {
        BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();
        basicDaoStorage.basicDaoInfos[daoId].unifiedPrice = newUnifiedPrice;
        emit DaoUnifiedPriceSet(daoId, ID4AProtocolReadable(address(this)).getDaoUnifiedPrice(daoId));
    }
}
