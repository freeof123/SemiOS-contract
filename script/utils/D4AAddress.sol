// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { CommonBase } from "forge-std/Base.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import { D4ADrb } from "contracts/D4ADrb.sol";
import { D4AFeePool, D4AFeePoolFactory } from "contracts/feepool/D4AFeePool.sol";
import { D4ARoyaltySplitter, D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import { D4AERC20, D4AERC20Factory } from "contracts/D4AERC20.sol";
import { D4AERC721WithFilter, D4AERC721WithFilterFactory } from "contracts/D4AERC721WithFilter.sol";
import { D4AProject } from "contracts/impl/D4AProject.sol";
import { D4ACanvas } from "contracts/impl/D4ACanvas.sol";
import { D4APrice } from "contracts/impl/D4APrice.sol";
import { D4AReward } from "contracts/impl/D4AReward.sol";
import { NaiveOwner } from "contracts/NaiveOwner.sol";
import { D4AProtocolWithPermission } from "contracts/D4AProtocolWithPermission.sol";
import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { D4ACreateProjectProxy } from "contracts/proxy/D4ACreateProjectProxy.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { ProtoDAOSettings } from "contracts/ProtoDAOSettings/ProtoDAOSettings.sol";
import { D4AClaimer } from "contracts/D4AClaimer.sol";

contract D4AAddress is CommonBase {
    using stdJson for string;

    string path = string.concat(vm.projectRoot(), "/deployed-contracts-info/", vm.envString("ENV"), "-d4a.json");
    string json = vm.readFile(path);

    // D4AClaimer
    D4AClaimer public d4aClaimer = D4AClaimer(json.readAddress(".D4AClaimer"));

    // Drb
    D4ADrb public d4aDrb = D4ADrb(json.readAddress(".D4ADrb"));

    // factories
    D4AFeePoolFactory public d4aFeePoolFactory = D4AFeePoolFactory(json.readAddress(".factories.D4AFeePoolFactory"));
    D4ARoyaltySplitterFactory public d4aRoyaltySplitterFactory =
        D4ARoyaltySplitterFactory(json.readAddress(".factories.D4ARoyaltySplitterFactory"));
    D4AERC20Factory public d4aERC20Factory = D4AERC20Factory(json.readAddress(".factories.D4AERC20Factory"));
    D4AERC721WithFilterFactory public d4aERC721WithFilterFactory =
        D4AERC721WithFilterFactory(json.readAddress(".factories.D4AERC721WithFilterFactory"));

    // proxy admin
    ProxyAdmin public proxyAdmin = ProxyAdmin(json.readAddress(".ProxyAdmin"));

    // D4AProtocolWithPermission
    TransparentUpgradeableProxy public d4aProtocolWithPermission_proxy =
        TransparentUpgradeableProxy(payable(json.readAddress(".D4AProtocolWithPermission.proxy")));
    D4AProtocolWithPermission public d4aProtocolWithPermission_impl =
        D4AProtocolWithPermission(json.readAddress(".D4AProtocolWithPermission.impl"));
    D4ADiamond public d4aDiamond = D4ADiamond(payable(json.readAddress(".D4AProtocolWithPermission.D4ADiamond")));
    D4ASettings public d4aSettings = D4ASettings(json.readAddress(".D4AProtocolWithPermission.D4ASettings"));
    ProtoDAOSettings public protoDaoSettings =
        ProtoDAOSettings(json.readAddress(".D4AProtocolWithPermission.ProtoDAOSettings"));

    // permission control
    TransparentUpgradeableProxy public permissionControl_proxy =
        TransparentUpgradeableProxy(payable(json.readAddress(".PermissionControl.proxy")));
    PermissionControl public permissionControl_impl = PermissionControl(json.readAddress(".PermissionControl.impl"));

    // create project proxy
    TransparentUpgradeableProxy public d4aCreateProjectProxy_proxy =
        TransparentUpgradeableProxy(payable(json.readAddress(".D4ACreateProjectProxy.proxy")));
    D4ACreateProjectProxy public d4aCreateProjectProxy_impl =
        D4ACreateProjectProxy(payable(json.readAddress(".D4ACreateProjectProxy.impl")));

    IWETH public immutable WETH = IWETH(json.readAddress(".WETH"));
    address public immutable uniswapV2Factory = json.readAddress(".D4ASwapFactory");
    address public immutable uniswapV2Router = json.readAddress(".UniswapV2Router");
    address public immutable oracleRegistry = json.readAddress(".OracleRegistry");
}
