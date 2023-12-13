// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ProtocolStorage } from "contracts/storages/ProtocolStorage.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";

import { InheritTreeStorage } from "contracts/storages/InheritTreeStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";

import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";

import { PriceStorage } from "contracts/storages/PriceStorage.sol";

import { RewardStorage } from "contracts/storages/RewardStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { IPriceTemplate } from "contracts/interface/IPriceTemplate.sol";
import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";
import { IPDRound } from "contracts/interface/IPDRound.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PDProtocolReadable is IPDProtocolReadable, D4AProtocolReadable {
    // protocol related functions
    function getNFTTokenCanvas(bytes32 daoId, uint256 tokenId) public view returns (bytes32) {
        return ProtocolStorage.layout().nftHashToCanvasId[keccak256(abi.encodePacked(daoId, tokenId))];
    }

    function getLastestDaoIndex(uint8 daoTag) public view returns (uint256) {
        return ProtocolStorage.layout().lastestDaoIndexes[daoTag];
    }

    function getDaoId(uint8 daoTag, uint256 daoIndex) public view returns (bytes32) {
        return ProtocolStorage.layout().daoIndexToIds[daoTag][daoIndex];
    }

    function getDaoAncestor(bytes32 daoId) public view returns (bytes32) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].ancestor;
    }

    //1.3 add----------------------------------------------------------
    function getDaoVersion(bytes32 daoId) public view returns (uint8) {
        return BasicDaoStorage.layout().basicDaoInfos[daoId].version;
    }

    function getCanvasCreatorMintFeeRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].canvasCreatorMintFeeRatio;
    }

    function getAssetPoolMintFeeRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].assetPoolMintFeeRatio;
    }

    function getRedeemPoolMintFeeRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].redeemPoolMintFeeRatio;
    }

    function getCanvasCreatorMintFeeRatioFiatPrice(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].canvasCreatorMintFeeRatioFiatPrice;
    }

    function getAssetPoolMintFeeRatioFiatPrice(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].assetPoolMintFeeRatioFiatPrice;
    }

    function getRedeemPoolMintFeeRatioFiatPrice(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].redeemPoolMintFeeRatioFiatPrice;
    }

    function getMinterERC20RewardRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].minterERC20RewardRatio;
    }

    function getCanvasCreatorERC20RewardRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].canvasCreatorERC20RewardRatio;
    }

    function getDaoCreatorERC20RewardRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].daoCreatorERC20RewardRatio;
    }

    function getMinterETHRewardRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].minterETHRewardRatio;
    }

    function getCanvasCreatorETHRewardRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].canvasCreatorETHRewardRatio;
    }

    function getDaoCreatorETHRewardRatio(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].daoCreatorETHRewardRatio;
    }

    function getDaoAssetPool(bytes32 daoId) public view returns (address) {
        return BasicDaoStorage.layout().basicDaoInfos[daoId].daoAssetPool;
    }

    function getIsAncestorDao(bytes32 daoId) public view returns (bool) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].isAncestorDao;
    }

    function getDaoLastActiveRound(bytes32 daoId) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        if (rewardInfo.activeRounds.length == 0) return 0;
        return rewardInfo.activeRounds[rewardInfo.activeRounds.length - 1];
    }

    function getDaoPassedRound(bytes32 daoId) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        if (!rewardInfo.isProgressiveJackpot) {
            if (rewardInfo.activeRounds.length == 0) return 0;
            if (
                rewardInfo.activeRounds[rewardInfo.activeRounds.length - 1]
                    == IPDRound(address(this)).getDaoCurrentRound(daoId)
            ) {
                return rewardInfo.activeRounds.length - 1;
            } else {
                return rewardInfo.activeRounds.length;
            }
        } else {
            uint256 passedRound = IPDRound(address(this)).getDaoCurrentRound(daoId) - 1;
            if (BasicDaoStorage.layout().basicDaoInfos[daoId].version < 14) {
                SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
                passedRound = settingsStorage.drb.currentRound() - DaoStorage.layout().daoInfos[daoId].startBlock;
            }
            return passedRound;
        }
    }

    function getDaoRemainingRound(bytes32 daoId) public view returns (uint256) {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        uint256 passedRound = getDaoPassedRound(daoId);
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].infiniteMode) return 1;
        if (daoInfo.mintableRound > passedRound) return daoInfo.mintableRound - passedRound;
        else return 0;
    }

    function getDaoChildren(bytes32 daoId) public view returns (bytes32[] memory) {
        InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        return treeInfo.children;
    }

    function getDaoChildrenRatiosERC20(bytes32 daoId) public view returns (uint256[] memory) {
        InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        return treeInfo.childrenDaoRatiosERC20;
    }

    function getDaoChildrenRatiosETH(bytes32 daoId) public view returns (uint256[] memory) {
        InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        return treeInfo.childrenDaoRatiosETH;
    }

    function getDaoRedeemPoolRatioETH(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].redeemPoolRatioETH;
    }

    function getDaoSelfRewardRatioERC20(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].selfRewardRatioERC20;
    }

    function getDaoSelfRewardRatioETH(bytes32 daoId) public view returns (uint256) {
        return InheritTreeStorage.layout().inheritTreeInfos[daoId].selfRewardRatioETH;
    }

    function getDaoTopUpMode(bytes32 daoId) public view returns (bool) {
        return BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode;
    }

    function getDaoIsThirdPartyToken(bytes32 daoId) public view returns (bool) {
        return BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken;
    }

    function getRoundERC20Reward(bytes32 daoId, uint256 round) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        return rewardInfo.selfRoundERC20Reward[round];
    }

    function getRoundETHReward(bytes32 daoId, uint256 round) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        return rewardInfo.selfRoundETHReward[round];
    }

    function getERC20RewardTillRound(bytes32 daoId, uint256 round) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        uint256 totalRoundReward;
        for (uint256 j; j < activeRounds.length && activeRounds[j] <= round; j++) {
            totalRoundReward += getRoundERC20Reward(daoId, activeRounds[j]);
        }

        return totalRoundReward;
    }

    function getETHRewardTillRound(bytes32 daoId, uint256 round) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        uint256 totalRoundReward;
        for (uint256 j; j < activeRounds.length && activeRounds[j] <= round; j++) {
            totalRoundReward += getRoundETHReward(daoId, activeRounds[j]);
        }

        return totalRoundReward;
    }

    function royaltySplitters(bytes32 daoId) public view returns (address) {
        return SettingsStorage.layout().royaltySplitters[daoId];
    }

    function getCanvasNextPrice(bytes32 daoId, bytes32 canvasId) public view returns (uint256) {
        uint256 daoFloorPrice = PriceStorage.layout().daoFloorPrices[daoId];
        PriceStorage.MintInfo memory maxPrice = PriceStorage.layout().daoMaxPrices[daoId];
        PriceStorage.MintInfo memory mintInfo = PriceStorage.layout().canvasLastMintInfos[canvasId];
        DaoStorage.DaoInfo storage pi = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        return IPriceTemplate(
            settingsStorage.priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)]
        ).getCanvasNextPrice(
            1, IPDRound(address(this)).getDaoCurrentRound(daoId), pi.nftPriceFactor, daoFloorPrice, maxPrice, mintInfo
        );
    }

    function getDaoCirculateTokenAmount(bytes32 daoId) public view returns (uint256) {
        bytes32 ancestor = InheritTreeStorage.layout().inheritTreeInfos[daoId].ancestor;
        bytes32[] memory daos = InheritTreeStorage.layout().inheritTreeInfos[ancestor].familyDaos;
        uint256 amount;
        address token = DaoStorage.layout().daoInfos[daoId].token;
        for (uint256 i; i < daos.length;) {
            amount += IERC20(token).balanceOf(BasicDaoStorage.layout().basicDaoInfos[daos[i]].daoAssetPool);
            unchecked {
                ++i;
            }
        }
        return IERC20(token).totalSupply() - amount;
    }

    function getDaoRoundDistributeAmount(
        bytes32 daoId,
        address token,
        uint256 currentRound,
        uint256 remainingRound
    )
        public
        view
        returns (uint256)
    {
        return _castgetDaoRoundDistributeAmountToView(_getDaoRoundDistributeAmount)(
            daoId, token, currentRound, remainingRound
        );
    }

    function _getDaoRoundDistributeAmount(
        bytes32 daoId,
        address token,
        uint256 currentRound,
        uint256 remainingRound
    )
        internal
        returns (uint256)
    {
        address rewardTemplate =
            SettingsStorage.layout().rewardTemplates[uint8(DaoStorage.layout().daoInfos[daoId].rewardTemplateType)];
        (bool succ, bytes memory data) = rewardTemplate.delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.getDaoRoundDistributeAmount.selector, daoId, token, currentRound, remainingRound
            )
        );
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        return abi.decode(data, (uint256));
    }

    function _castgetDaoRoundDistributeAmountToView(
        function(bytes32, address, uint256, uint256) internal returns (uint256) fnIn
    )
        internal
        pure
        returns (function(bytes32, address, uint256, uint256) internal view returns (uint256) fnOut)
    {
        assembly {
            fnOut := fnIn
        }
    }
}
