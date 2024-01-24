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
import { OwnerStorage } from "contracts/storages/OwnerStorage.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";
import { ID4AProtocolReadable } from "./interface/ID4AProtocolReadable.sol";
import { IPDProtocolReadable } from "./interface/IPDProtocolReadable.sol";
import { IPDRound } from "./interface/IPDRound.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

    function setDaoNftMaxSupply(bytes32 daoId, uint256 newMaxSupply) public virtual {
        DaoStorage.layout().daoInfos[daoId].nftMaxSupply = newMaxSupply;

        emit DaoNftMaxSupplySet(daoId, newMaxSupply);
    }

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
        // if (
        //     msg.sender != IERC721(nftAddress).ownerOf(tokenId) && msg.sender != l.createProjectProxy
        //         && msg.sender != address(this)
        // ) revert NotDaoOwner();

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
