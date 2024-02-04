// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
import { ID4AOwnerProxy } from "contracts/interface/ID4AOwnerProxy.sol";

interface ID4ASettingsReadable {
    function permissionControl() external view returns (IPermissionControl);

    function ownerProxy() external view returns (ID4AOwnerProxy);

    function mintProtocolFeeRatio() external view returns (uint256);

    function protocolFeePool() external view returns (address);

    function tradeProtocolFeeRatio() external view returns (uint256);

    function ratioBase() external view returns (uint256);

    function getPriceTemplates() external view returns (address[] memory priceTemplates);

    function getRewardTemplates() external view returns (address[] memory rewardTemplates);
}
