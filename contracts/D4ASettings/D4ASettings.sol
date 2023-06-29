// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@solidstate/contracts/access/access_control/AccessControl.sol";
import "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { Initializable } from "@solidstate/contracts/security/initializable/Initializable.sol";

import "./ID4ASettings.sol";
import { PriceTemplateType, RewardTemplateType, TemplateChoice } from "../interface/D4AEnums.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import "./D4ASettingsReadable.sol";
import { ID4ADrb } from "../interface/ID4ADrb.sol";
import { ID4AProtocolReadable } from "../interface/ID4AProtocolReadable.sol";
import { ID4AProtocol } from "../interface/ID4AProtocol.sol";
import "../interface/ID4AFeePoolFactory.sol";
import "../interface/ID4AERC20Factory.sol";
import "../interface/ID4AOwnerProxy.sol";
import "../interface/ID4AERC721Factory.sol";

contract D4ASettings is ID4ASettings, Initializable, AccessControl, D4ASettingsReadable {
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant OPERATION_ROLE = keccak256("OPERATION_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    function initializeD4ASettings() public initializer {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DAO_ROLE, OPERATION_ROLE);
        _setRoleAdmin(SIGNER_ROLE, OPERATION_ROLE);
        //some default value here
        l.createDaoFeeAmount = 0.1 ether;
        l.createCanvasFeeAmount = 0.01 ether;
        l.protocolMintFeeRatioInBps = 250;
        l.protocolRoyaltyFeeRatioInBps = 250;
        l.daoFeePoolMintFeeRatioInBps = 3000;
        l.daoFeePoolMintFeeRatioInBpsFlatPrice = 3500;
        l.minRoyaltyFeeRatioInBps = 500;
        l.maxRoyaltyFeeRatioInBps = 1000;

        l.daoCreatorERC20RatioInBps = 300;
        l.protocolERC20RatioInBps = 200;
        l.canvasCreatorERC20RatioInBps = 9500;
        l.maxMintableRound = 366;
        l.reservedDaoAmount = 110;
    }

    event ChangeCreateFee(uint256 create_project_fee, uint256 create_canvas_fee);

    function changeCreateFee(
        uint256 createDaoFeeAmount,
        uint256 createCanvasFeeAmount
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.createDaoFeeAmount = createDaoFeeAmount;
        l.createCanvasFeeAmount = createCanvasFeeAmount;
        emit ChangeCreateFee(createDaoFeeAmount, createCanvasFeeAmount);
    }

    event ChangeProtocolFeePool(address addr);

    function changeProtocolFeePool(address addr) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolFeePool = addr;
        emit ChangeProtocolFeePool(addr);
    }

    event ChangeMintFeeRatio(uint256 d4a_ratio, uint256 project_ratio, uint256 project_fee_ratio_flat_price);

    function changeMintFeeRatio(
        uint256 protocolFeeRatioInBps,
        uint256 daoFeePoolMintFeeRatioInBps,
        uint256 daoFeePoolMintFeeRatioInBpsFlatPrice
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolMintFeeRatioInBps = protocolFeeRatioInBps;
        l.daoFeePoolMintFeeRatioInBps = daoFeePoolMintFeeRatioInBps;
        l.daoFeePoolMintFeeRatioInBpsFlatPrice = daoFeePoolMintFeeRatioInBpsFlatPrice;
        emit ChangeMintFeeRatio(
            protocolFeeRatioInBps, daoFeePoolMintFeeRatioInBps, daoFeePoolMintFeeRatioInBpsFlatPrice
        );
    }

    event ChangeTradeFeeRatio(uint256 trade_d4a_fee_ratio);

    function changeTradeFeeRatio(uint256 protocolRoyaltyFeeRatioInBps) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolRoyaltyFeeRatioInBps = protocolRoyaltyFeeRatioInBps;
        emit ChangeTradeFeeRatio(protocolRoyaltyFeeRatioInBps);
    }

    event ChangeERC20TotalSupply(uint256 total_supply);

    function changeERC20TotalSupply(uint256 tokenMaxSupply) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.tokenMaxSupply = tokenMaxSupply;
        emit ChangeERC20TotalSupply(tokenMaxSupply);
    }

    event ChangeERC20Ratio(uint256 d4a_ratio, uint256 project_ratio, uint256 canvas_ratio);

    function changeERC20Ratio(
        uint256 protocolERC20RatioInBps,
        uint256 daoCreatorERC20RatioInBps,
        uint256 canvasCreatorERC20RatioInBps
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolERC20RatioInBps = protocolERC20RatioInBps;
        l.daoCreatorERC20RatioInBps = daoCreatorERC20RatioInBps;
        l.canvasCreatorERC20RatioInBps = canvasCreatorERC20RatioInBps;
        require(
            protocolERC20RatioInBps + daoCreatorERC20RatioInBps + canvasCreatorERC20RatioInBps == BASIS_POINT,
            "invalid ratio"
        );

        emit ChangeERC20Ratio(protocolERC20RatioInBps, daoCreatorERC20RatioInBps, canvasCreatorERC20RatioInBps);
    }

    event ChangeMaxMintableRounds(uint256 old_rounds, uint256 new_rounds);

    function changeMaxMintableRounds(uint256 maxMintableRound) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        emit ChangeMaxMintableRounds(l.maxMintableRound, maxMintableRound);
        l.maxMintableRound = maxMintableRound;
    }

    event ChangeAddress(
        address PRB,
        address erc20_factory,
        address erc721_factory,
        address feepool_factory,
        address owner_proxy,
        address project_proxy,
        address permission_control
    );

    function changeAddress(
        address drb,
        address erc20Factory,
        address erc721Factory,
        address feePoolFactory,
        address ownerProxy,
        address createProjectProxy,
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
        l.createProjectProxy = createProjectProxy;
        l.permissionControl = IPermissionControl(permissionControl);
        emit ChangeAddress(
            drb, erc20Factory, erc721Factory, feePoolFactory, ownerProxy, createProjectProxy, permissionControl
        );
    }

    event ChangeAssetPoolOwner(address new_owner);

    function changeAssetPoolOwner(address _owner) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.asset_pool_owner = _owner;
        emit ChangeAssetPoolOwner(_owner);
    }

    event ChangeFloorPrices(uint256[] prices);

    function changeFloorPrices(uint256[] memory daoFloorPrices) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        delete l.daoFloorPrices; // TODO: check if this is necessary
        l.daoFloorPrices = daoFloorPrices;
        emit ChangeFloorPrices(daoFloorPrices);
    }

    event ChangeMaxNFTAmounts(uint256[] amounts);

    function changeMaxNFTAmounts(uint256[] memory nftMaxSupplies) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        delete l.nftMaxSupplies; // TODO: check if this is necessary
        l.nftMaxSupplies = nftMaxSupplies;
        emit ChangeMaxNFTAmounts(nftMaxSupplies);
    }

    event ChangeD4APause(bool isPaused);

    function changeD4APause(bool isPaused) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.isProtocolPaused = isPaused;
        emit ChangeD4APause(isPaused);
    }

    event D4ASetProjectPaused(bytes32 project_id, bool isPaused);

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

    event D4ASetCanvasPaused(bytes32 canvas_id, bool isPaused);

    function setCanvasPause(bytes32 canvasId, bool isPaused) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        require(
            (
                _hasRole(DAO_ROLE, msg.sender)
                    && l.ownerProxy.ownerOf(ID4AProtocolReadable(address(this)).getCanvasProject(canvasId)) == msg.sender
            ) || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pauseStatuses[canvasId] = isPaused;
        emit D4ASetCanvasPaused(canvasId, isPaused);
    }

    event MembershipTransferred(bytes32 indexed role, address indexed previousMember, address indexed newMember);

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
}
