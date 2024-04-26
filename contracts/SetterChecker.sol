// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/interface/D4AErrors.sol";
import { OwnerStorage } from "contracts/storages/OwnerStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract SetterChecker {
    function _checkEditParamAbility(bytes32 daoId) internal view {
        OwnerStorage.DaoOwnerInfo storage ownerInfo = OwnerStorage.layout().daoOwnerInfos[daoId];
        address nftAddress = ownerInfo.daoEditParameterOwner.erc721Address;
        uint256 tokenId = ownerInfo.daoEditParameterOwner.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkEditStrategyAbility(bytes32 daoId) internal view {
        OwnerStorage.DaoOwnerInfo storage ownerInfo = OwnerStorage.layout().daoOwnerInfos[daoId];
        address nftAddress = ownerInfo.daoEditStrategyOwner.erc721Address;
        uint256 tokenId = ownerInfo.daoEditStrategyOwner.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkEditInformationAbility(bytes32 daoId) internal view {
        OwnerStorage.DaoOwnerInfo storage ownerInfo = OwnerStorage.layout().daoOwnerInfos[daoId];
        address nftAddress = ownerInfo.daoEditInformationOwner.erc721Address;
        uint256 tokenId = ownerInfo.daoEditInformationOwner.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkEditDaoCreatorRewardAbility(bytes32 daoId) internal view {
        OwnerStorage.DaoOwnerInfo storage ownerInfo = OwnerStorage.layout().daoOwnerInfos[daoId];
        address nftAddress = ownerInfo.daoRewardOwner.erc721Address;
        uint256 tokenId = ownerInfo.daoRewardOwner.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkTreasuryEditInformationAbility(bytes32 daoId) internal view {
        address pool = DaoStorage.layout().daoInfos[daoId].daoFeePool;
        OwnerStorage.TreasuryOwnerInfo storage ownerInfo = OwnerStorage.layout().treasuryOwnerInfos[pool];
        address nftAddress = ownerInfo.treasuryEditInformationOwner.erc721Address;
        uint256 tokenId = ownerInfo.treasuryEditInformationOwner.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkTreasuryTransferAssetAbility(bytes32 daoId) internal view {
        address pool = DaoStorage.layout().daoInfos[daoId].daoFeePool;
        OwnerStorage.TreasuryOwnerInfo storage ownerInfo = OwnerStorage.layout().treasuryOwnerInfos[pool];
        address nftAddress = ownerInfo.treasuryTransferAssetOwner.erc721Address;
        uint256 tokenId = ownerInfo.treasuryTransferAssetOwner.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }

    function _checkTreasurySetTopUpRatioAbility(bytes32 daoId) internal view {
        address pool = DaoStorage.layout().daoInfos[daoId].daoFeePool;
        OwnerStorage.TreasuryOwnerInfo storage ownerInfo = OwnerStorage.layout().treasuryOwnerInfos[pool];
        address nftAddress = ownerInfo.treasurySetTopUpRatioOwner.erc721Address;
        uint256 tokenId = ownerInfo.treasurySetTopUpRatioOwner.tokenId;
        if (msg.sender != address(this) && msg.sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert NotNftOwner();
        }
    }
}
