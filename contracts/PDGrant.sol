// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { OPERATION_ROLE } from "contracts/interface/D4AConstants.sol";
import { NotOperationRole } from "contracts/interface/D4AErrors.sol";
import { IPDGrant } from "contracts/interface/IPDGrant.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";
import { OwnerStorage } from "contracts/storages/OwnerStorage.sol";
import { GrantStorage } from "contracts/storages/GrantStorage.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "./D4AERC721.sol";
import { LibString } from "solady/utils/LibString.sol";
import "contracts/interface/D4AErrors.sol";

contract PDGrant is IPDGrant {
    function grantDaoAssetPool(
        bytes32 daoId,
        uint256 amount,
        bool useTreasury,
        string calldata tokenUri,
        address token
    )
        external
    {
        address daoAssetPool = BasicDaoStorage.layout().basicDaoInfos[daoId].daoAssetPool;
        if (useTreasury) {
            _checkTreasuryTransferAssetAbility(daoId);
            address treasury = PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].treasury;
            D4AFeePool(payable(treasury)).transfer(token, payable(daoAssetPool), amount);
        } else {
            SafeTransferLib.safeTransferFrom(token, msg.sender, daoAssetPool, amount);
        }
        _mintGrantAssetPoolNft(daoId, amount, useTreasury, msg.sender, token, tokenUri);
    }

    function grantDaoAssetPoolWithPermit(
        bytes32 daoId,
        uint256 amount,
        string calldata tokenUri,
        address token,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        address daoAssetPool = BasicDaoStorage.layout().basicDaoInfos[daoId].daoAssetPool;
        IERC20Permit(token).permit(msg.sender, address(this), amount, deadline, v, r, s);
        SafeTransferLib.safeTransferFrom(token, msg.sender, daoAssetPool, amount);
        _mintGrantAssetPoolNft(daoId, amount, false, msg.sender, token, tokenUri);
    }

    function grantTreasury(bytes32 daoId, uint256 amount, string calldata tokenUri, address token) external {
        address treasury = PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].treasury;

        SafeTransferLib.safeTransferFrom(token, msg.sender, treasury, amount);
        bytes32 ancestor = IPDProtocolReadable(address(this)).getDaoAncestor(daoId);
        _mintGrantTreasuryNft(ancestor, amount, msg.sender, token, tokenUri);
    }

    function grantTreasuryWithPermit(
        bytes32 daoId,
        uint256 amount,
        string calldata tokenUri,
        address token,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        address treasury = PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].treasury;
        IERC20Permit(token).permit(msg.sender, address(this), amount, deadline, v, r, s);
        SafeTransferLib.safeTransferFrom(token, msg.sender, treasury, amount);
        bytes32 ancestor = IPDProtocolReadable(address(this)).getDaoAncestor(daoId);

        _mintGrantTreasuryNft(ancestor, amount, msg.sender, token, tokenUri);
    }

    function _mintGrantAssetPoolNft(
        bytes32 daoId,
        uint256 amount,
        bool useTreasury,
        address owner,
        address token,
        string calldata tokenUri
    )
        internal
    {
        address grantAssetPoolNft = BasicDaoStorage.layout().basicDaoInfos[daoId].grantAssetPoolNft;
        uint256 tokenId = D4AERC721(grantAssetPoolNft).mintItem(owner, tokenUri, 0, false);
        emit NewSemiOsGrantAssetPoolNft(
            grantAssetPoolNft, tokenId, daoId, owner, amount, useTreasury, block.number, token
        );
        DaoStorage.layout().daoInfos[daoId].tokenMaxSupply += amount;
        GrantStorage.GrantInfo storage grantInfo =
            GrantStorage.layout().grantInfos[keccak256(abi.encodePacked(grantAssetPoolNft, tokenId))];
        grantInfo.granter = owner;
        grantInfo.grantAmount = amount;
        grantInfo.isUseTreasury = useTreasury;
        grantInfo.grantBlock = block.number;
        grantInfo.receiverDao = daoId;
        grantInfo.token = token;
    }

    function _mintGrantTreasuryNft(
        bytes32 daoId,
        uint256 amount,
        address owner,
        address token,
        string calldata tokenUri
    )
        internal
    {
        address grantTreasuryNft =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].grantTreasuryNft;
        uint256 tokenId = D4AERC721(grantTreasuryNft).mintItem(owner, tokenUri, 0, false);
        emit NewSemiOsGrantTreasuryNft(grantTreasuryNft, tokenId, daoId, owner, amount, block.number, token);
        DaoStorage.layout().daoInfos[daoId].tokenMaxSupply += amount;
        GrantStorage.GrantInfo storage grantInfo =
            GrantStorage.layout().grantInfos[keccak256(abi.encodePacked(grantTreasuryNft, tokenId))];
        grantInfo.granter = owner;
        grantInfo.grantAmount = amount;
        grantInfo.grantBlock = block.number;
        grantInfo.receiverDao = daoId;
        grantInfo.token = token;
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
}
