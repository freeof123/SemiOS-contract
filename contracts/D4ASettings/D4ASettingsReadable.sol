// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { BASIS_POINT } from "contracts/D4AProtocol.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { ID4ASettingsReadable } from "./ID4ASettingsReadable.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
import { ID4AOwnerProxy } from "contracts/interface/ID4AOwnerProxy.sol";

contract D4ASettingsReadable is ID4ASettingsReadable {
    function permissionControl() public view returns (IPermissionControl) {
        return SettingsStorage.layout().permission_control;
    }

    function ownerProxy() public view returns (ID4AOwnerProxy) {
        return SettingsStorage.layout().owner_proxy;
    }

    function mintProtocolFeeRatio() public view returns (uint256) {
        return SettingsStorage.layout().mint_d4a_fee_ratio;
    }

    function protocolFeePool() public view returns (address) {
        return SettingsStorage.layout().protocolFeePool;
    }

    function tradeProtocolFeeRatio() public view returns (uint256) {
        return SettingsStorage.layout().trade_d4a_fee_ratio;
    }

    function mintProjectFeeRatio() public view returns (uint256) {
        return SettingsStorage.layout().mint_project_fee_ratio;
    }

    function mintProjectFeeRatioFlatPrice() public view returns (uint256) {
        return SettingsStorage.layout().mint_project_fee_ratio_flat_price;
    }

    function ratioBase() public pure returns (uint256) {
        return BASIS_POINT;
    }

    function createProjectFee() public view returns (uint256) {
        return SettingsStorage.layout().create_project_fee;
    }

    function createCanvasFee() public view returns (uint256) {
        return SettingsStorage.layout().create_canvas_fee;
    }
}
