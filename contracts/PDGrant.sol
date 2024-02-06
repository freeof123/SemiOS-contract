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
import { ID4AProtocol } from "contracts/interface/ID4AProtocol.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";
import { OwnerStorage } from "contracts/storages/OwnerStorage.sol";

import { GrantStorage } from "contracts/storages/GrantStorage.sol";
import { D4AVestingWallet } from "contracts/feepool/D4AVestingWallet.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "./D4AERC721.sol";
import { LibString } from "solady/utils/LibString.sol";

import "contracts/interface/D4AErrors.sol";

contract PDGrant is IPDGrant {
    function addAllowedToken(address token) external {
        if (!IAccessControl(address(this)).hasRole(OPERATION_ROLE, msg.sender)) revert NotOperationRole();

        GrantStorage.Layout storage grantStorage = GrantStorage.layout();
        if (grantStorage.tokensAllowed[token]) return;
        grantStorage.tokensAllowed[token] = true;
        grantStorage.allowedTokenList.push(token);
    }

    function removeAllowedToken(address token) external {
        if (!IAccessControl(address(this)).hasRole(OPERATION_ROLE, msg.sender)) revert NotOperationRole();

        GrantStorage.Layout storage grantStorage = GrantStorage.layout();
        if (!grantStorage.tokensAllowed[token]) return;
        grantStorage.tokensAllowed[token] = false;
        uint256 length = grantStorage.allowedTokenList.length;
        for (uint256 i; i < length; ++i) {
            if (grantStorage.allowedTokenList[i] == token) {
                grantStorage.allowedTokenList[i] = grantStorage.allowedTokenList[length - 1];
                grantStorage.allowedTokenList.pop();
                break;
            }
        }
    }

    function grantETH(bytes32 daoId) external payable {
        GrantStorage.Layout storage grantStorage = GrantStorage.layout();
        address vestingWallet = grantStorage.vestingWallets[daoId];
        if (vestingWallet == address(0)) {
            DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
            ID4AProtocol(address(this)).claimProjectERC20Reward(daoId);
            vestingWallet = address(
                new D4AVestingWallet(daoInfo.daoFeePool, daoInfo.token, SettingsStorage.layout().tokenMaxSupply - IERC20(daoInfo.token).totalSupply())
            );
            grantStorage.vestingWallets[daoId] = vestingWallet;
        }
        if (msg.value > 0) SafeTransferLib.safeTransferETH(vestingWallet, msg.value);
    }

    function grant(bytes32 daoId, address token, uint256 amount) external {
        GrantStorage.Layout storage grantStorage = GrantStorage.layout();
        if (!grantStorage.tokensAllowed[token]) revert TokenNotAllowed(token);
        address vestingWallet = grantStorage.vestingWallets[daoId];
        if (vestingWallet == address(0)) {
            DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
            ID4AProtocol(address(this)).claimProjectERC20Reward(daoId);
            vestingWallet = address(
                new D4AVestingWallet(daoInfo.daoFeePool, daoInfo.token, SettingsStorage.layout().tokenMaxSupply - IERC20(daoInfo.token).totalSupply())
            );
            grantStorage.vestingWallets[daoId] = vestingWallet;
        }
        SafeTransferLib.safeTransferFrom(token, msg.sender, vestingWallet, amount);
    }

    function grantWithPermit(
        bytes32 daoId,
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        GrantStorage.Layout storage grantStorage = GrantStorage.layout();
        if (!grantStorage.tokensAllowed[token]) revert TokenNotAllowed(token);
        address vestingWallet = grantStorage.vestingWallets[daoId];
        if (vestingWallet == address(0)) {
            DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
            ID4AProtocol(address(this)).claimProjectERC20Reward(daoId);
            vestingWallet = address(
                new D4AVestingWallet(daoInfo.daoFeePool, daoInfo.token, SettingsStorage.layout().tokenMaxSupply - IERC20(daoInfo.token).totalSupply())
            );
            grantStorage.vestingWallets[daoId] = vestingWallet;
        }
        IERC20Permit(token).permit(msg.sender, address(this), amount, deadline, v, r, s);
        SafeTransferLib.safeTransferFrom(token, msg.sender, vestingWallet, amount);
    }

    function getVestingWallet(bytes32 daoId) external view returns (address) {
        return GrantStorage.layout().vestingWallets[daoId];
    }

    function getAllowedTokensList() external view returns (address[] memory) {
        return GrantStorage.layout().allowedTokenList;
    }

    function isTokenAllowed(address token) external view returns (bool) {
        return GrantStorage.layout().tokensAllowed[token];
    }

    function grantDaoAssetPool(bytes32 daoId, uint256 amount, bool useTreasury, string calldata tokenUri) external {
        address daoAssetPool = BasicDaoStorage.layout().basicDaoInfos[daoId].daoAssetPool;
        address daoToken = DaoStorage.layout().daoInfos[daoId].token;
        if (useTreasury) {
            _checkTreasuryTransferAssetAbility(daoId);
            address treasury = PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].treasury;
            D4AFeePool(payable(treasury)).transfer(daoToken, payable(daoAssetPool), amount);
        } else {
            SafeTransferLib.safeTransferFrom(daoToken, msg.sender, daoAssetPool, amount);
        }
        _mintGrantAssetPoolNft(daoId, amount, useTreasury, msg.sender, daoToken, tokenUri);
    }

    function grantDaoAssetPoolWithPermit(
        bytes32 daoId,
        uint256 amount,
        string calldata tokenUri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        address daoAssetPool = BasicDaoStorage.layout().basicDaoInfos[daoId].daoAssetPool;
        address daoToken = DaoStorage.layout().daoInfos[daoId].token;
        IERC20Permit(daoToken).permit(msg.sender, address(this), amount, deadline, v, r, s);
        SafeTransferLib.safeTransferFrom(daoToken, msg.sender, daoAssetPool, amount);
        _mintGrantAssetPoolNft(daoId, amount, false, msg.sender, daoToken, tokenUri);
    }

    function grantTreasury(bytes32 daoId, uint256 amount, string calldata tokenUri) external {
        address treasury = PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].treasury;
        address daoToken = DaoStorage.layout().daoInfos[daoId].token;

        SafeTransferLib.safeTransferFrom(daoToken, msg.sender, treasury, amount);
        bytes32 ancestor = IPDProtocolReadable(address(this)).getDaoAncestor(daoId);
        _mintGrantTreasuryNft(ancestor, amount, msg.sender, daoToken, tokenUri);
    }

    function grantTreasuryWithPermit(
        bytes32 daoId,
        uint256 amount,
        string calldata tokenUri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        address treasury = PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool].treasury;
        address daoToken = DaoStorage.layout().daoInfos[daoId].token;
        IERC20Permit(daoToken).permit(msg.sender, address(this), amount, deadline, v, r, s);
        SafeTransferLib.safeTransferFrom(daoToken, msg.sender, treasury, amount);
        bytes32 ancestor = IPDProtocolReadable(address(this)).getDaoAncestor(daoId);

        _mintGrantTreasuryNft(ancestor, amount, msg.sender, daoToken, tokenUri);
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
