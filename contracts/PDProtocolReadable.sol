// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ProtocolStorage } from "contracts/storages/ProtocolStorage.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";

import { InheritTreeStorage } from "contracts/storages/InheritTreeStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";

import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";

import { RewardStorage } from "contracts/storages/RewardStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";

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

    function getDaoLastActiveRoundFunding(bytes32 daoId) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        if (rewardInfo.activeRoundsFunding.length == 0) return DaoStorage.layout().daoInfos[daoId].startRound;
        return rewardInfo.activeRoundsFunding[rewardInfo.activeRoundsFunding.length - 1];
    }

    function getDaoPassedRound(bytes32 daoId) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        if (!rewardInfo.isProgressiveJackpot) {
            if (rewardInfo.activeRoundsFunding.length == 0) return 0;
            if (
                rewardInfo.activeRoundsFunding[rewardInfo.activeRoundsFunding.length - 1]
                    == settingsStorage.drb.currentRound()
            ) {
                return rewardInfo.activeRoundsFunding.length - 1;
            } else {
                return rewardInfo.activeRoundsFunding.length;
            }
        } else {
            uint256 passedRound = settingsStorage.drb.currentRound() - daoInfo.startRound;
            if (passedRound > daoInfo.mintableRound) return daoInfo.mintableRound;
            return passedRound;
        }
    }

    function getDaoRemainingRound(bytes32 daoId) public view returns (uint256) {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        uint256 passedRound = getDaoPassedRound(daoId);
        if (daoInfo.mintableRound > passedRound) return daoInfo.mintableRound - passedRound;
        else return 0;
    }

    function getDaoChildren(bytes32 daoId) public view returns (bytes32[] memory) {
        InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
        return treeInfo.children;
    }
}
