// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ProtocolStorage } from "contracts/storages/ProtocolStorage.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";

import { InheritTreeStorage } from "contracts/storages/InheritTreeStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";

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
}
