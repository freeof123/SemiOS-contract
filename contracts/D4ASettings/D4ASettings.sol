// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { Initializable } from "@solidstate/contracts/security/initializable/Initializable.sol";

import { BASIS_POINT, PROTOCOL_ROLE, OPERATION_ROLE, DAO_ROLE, SIGNER_ROLE } from "contracts/interface/D4AConstants.sol";
import { TemplateChoice } from "../interface/D4AEnums.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { ID4ASettings } from "./ID4ASettings.sol";
import { ID4ADrb } from "../interface/ID4ADrb.sol";
import { ID4AProtocolReadable } from "../interface/ID4AProtocolReadable.sol";
import { IPermissionControl } from "../interface/IPermissionControl.sol";
import { ID4AFeePoolFactory } from "../interface/ID4AFeePoolFactory.sol";
import { ID4AERC20Factory } from "../interface/ID4AERC20Factory.sol";
import { ID4AOwnerProxy } from "../interface/ID4AOwnerProxy.sol";
import { ID4AERC721Factory } from "../interface/ID4AERC721Factory.sol";
import { ID4ARoyaltySplitterFactory } from "contracts/interface/ID4ARoyaltySplitterFactory.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { D4ASettingsReadable } from "./D4ASettingsReadable.sol";

contract D4ASettings is ID4ASettings, Initializable, AccessControl, D4ASettingsReadable {
    function initializeD4ASettings(uint256 reservedDaoAmount) public initializer {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DAO_ROLE, OPERATION_ROLE);
        _setRoleAdmin(SIGNER_ROLE, OPERATION_ROLE);
        //some default value here
        l.protocolMintFeeRatioInBps = 250;
        l.protocolRoyaltyFeeRatioInBps = 250;
        l.minRoyaltyFeeRatioInBps = 500;
        l.maxRoyaltyFeeRatioInBps = 1000;

        l.protocolERC20RatioInBps = 200;
        l.reservedDaoAmount = reservedDaoAmount;
    }

    function changeProtocolFeePool(address protocolFeePool) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolFeePool = protocolFeePool;
        emit ChangeProtocolFeePool(protocolFeePool);
    }

    function changeTradeFeeRatio(uint256 protocolRoyaltyFeeRatioInBps) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolRoyaltyFeeRatioInBps = protocolRoyaltyFeeRatioInBps;
        emit ChangeTradeFeeRatio(protocolRoyaltyFeeRatioInBps);
    }

    function changeERC20TotalSupply(uint256 tokenMaxSupply) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.tokenMaxSupply = tokenMaxSupply;
        emit ChangeERC20TotalSupply(tokenMaxSupply);
    }

    function changeAddress(
        address drb,
        address erc20Factory,
        address erc721Factory,
        address feePoolFactory,
        address ownerProxy,
        address permissionControl
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.drb = ID4ADrb(drb);
        l.erc20Factory = ID4AERC20Factory(erc20Factory);
        l.erc721Factory = ID4AERC721Factory(erc721Factory);
        l.feePoolFactory = ID4AFeePoolFactory(feePoolFactory);
        l.ownerProxy = ID4AOwnerProxy(ownerProxy);
        l.permissionControl = IPermissionControl(permissionControl);
        emit ChangeAddress(drb, erc20Factory, erc721Factory, feePoolFactory, ownerProxy, permissionControl);
    }

    function changeAssetPoolOwner(address assetOwner) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.assetOwner = assetOwner;
        emit ChangeAssetPoolOwner(assetOwner);
    }

    function changeMaxNFTAmounts(uint256[] memory nftMaxSupplies) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        delete l.nftMaxSupplies; // TODO: check if this is necessary
        l.nftMaxSupplies = nftMaxSupplies;
        emit ChangeMaxNFTAmounts(nftMaxSupplies);
    }

    function changeD4APause(bool isPaused) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.isProtocolPaused = isPaused;
        emit ChangeD4APause(isPaused);
    }

    function setProjectPause(bytes32 daoId, bool isPaused) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        require(
            (_hasRole(DAO_ROLE, msg.sender) && l.ownerProxy.ownerOf(daoId) == msg.sender)
                || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pauseStatuses[daoId] = isPaused;
        emit D4ASetProjectPaused(daoId, isPaused);
    }

    function setCanvasPause(bytes32 canvasId, bool isPaused) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        require(
            (
                _hasRole(DAO_ROLE, msg.sender)
                    && l.ownerProxy.ownerOf(ID4AProtocolReadable(address(this)).getCanvasDaoId(canvasId)) == msg.sender
            ) || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pauseStatuses[canvasId] = isPaused;
        emit D4ASetCanvasPaused(canvasId, isPaused);
    }

    function transferMembership(bytes32 role, address previousMember, address newMember) public {
        require(!_hasRole(role, newMember), "new member already has the role");
        require(_hasRole(role, previousMember), "previous member does not have the role");
        require(newMember != address(0x0) && previousMember != address(0x0), "invalid address");
        _grantRole(role, newMember);
        _revokeRole(role, previousMember);

        emit MembershipTransferred(role, previousMember, newMember);
    }

    function setTemplateAddress(
        TemplateChoice templateChoice,
        uint8 index,
        address template
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (templateChoice == TemplateChoice.PRICE) {
            l.priceTemplates[index] = template;
        } else {
            l.rewardTemplates[index] = template;
        }
    }

    function setReservedDaoAmount(uint256 reservedDaoAmount) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.layout().reservedDaoAmount = reservedDaoAmount;
    }

    function setRoyaltySplitterAndSwapFactoryAddress(
        address newRoyaltySplitterFactory,
        address newRoyaltySplitterOwner,
        address newD4AswapFactory
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.royaltySplitterFactory = ID4ARoyaltySplitterFactory(newRoyaltySplitterFactory);
        l.royaltySplitterOwner = newRoyaltySplitterOwner;
        l.d4aswapFactory = IUniswapV2Factory(newD4AswapFactory);
    }
    //Todo need set in 1.3

    function changeETHRewardRatio(uint256 protocolETHRewardRatio) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolETHRewardRatio = protocolETHRewardRatio;

        emit ChangeETHRewardRatio(protocolETHRewardRatio);
    }
}
