// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

import { OPERATION_ROLE } from "contracts/interface/D4AConstants.sol";
import { NotOperationRole } from "contracts/interface/D4AErrors.sol";
import { IPDGrant } from "contracts/interface/IPDGrant.sol";
import { ID4AProtocol } from "contracts/interface/ID4AProtocol.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { GrantStorage } from "contracts/storages/GrantStorage.sol";
import { D4AVestingWallet } from "contracts/feepool/D4AVestingWallet.sol";

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
        if (msg.value > 0) SafeTransferLib.existFeePoolAddress(vestingWallet, msg.value);
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
}
