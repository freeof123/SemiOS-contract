// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { CommonBase } from "forge-std/Base.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import { D4ADrb } from "contracts/D4ADrb.sol";
import { D4AFeePool, D4AFeePoolFactory } from "contracts/feepool/D4AFeePool.sol";
import { D4ARoyaltySplitter, D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import { D4AERC20, D4AERC20Factory } from "contracts/D4AERC20.sol";
import { D4AERC721WithFilter, D4AERC721WithFilterFactory } from "contracts/D4AERC721WithFilter.sol";
import { NaiveOwner } from "contracts/NaiveOwner.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { D4AProtocol } from "contracts/D4AProtocol.sol";
import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { D4ACreateProjectProxy } from "contracts/proxy/D4ACreateProjectProxy.sol";
import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { D4AClaimer } from "contracts/D4AClaimer.sol";
import { D4AUniversalClaimer } from "contracts/D4AUniversalClaimer.sol";
import { LinearPriceVariation } from "contracts/templates/LinearPriceVariation.sol";
import { ExponentialPriceVariation } from "contracts/templates/ExponentialPriceVariation.sol";
import { LinearRewardIssuance } from "contracts/templates/LinearRewardIssuance.sol";
import { ExponentialRewardIssuance } from "contracts/templates/ExponentialRewardIssuance.sol";

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

    // D4AProtocol
    D4AProtocol public d4aProtocol_proxy = D4AProtocol(payable(json.readAddress(".D4AProtocol.proxy")));
    D4AProtocol public d4aProtocol_impl = D4AProtocol(json.readAddress(".D4AProtocol.impl"));
    D4AProtocolReadable public d4aProtocolReadable =
        D4AProtocolReadable(json.readAddress(".D4AProtocol.D4AProtocolReadable"));
    D4AProtocolSetter public d4aProtocolSetter = D4AProtocolSetter(json.readAddress(".D4AProtocol.D4AProtocolSetter"));
    D4ASettings public d4aSettings = D4ASettings(json.readAddress(".D4AProtocol.D4ASettings"));
    LinearPriceVariation public linearPriceVariation =
        LinearPriceVariation(json.readAddress(".D4AProtocol.LinearPriceVariation"));
    ExponentialPriceVariation public exponentialPriceVariation =
        ExponentialPriceVariation(json.readAddress(".D4AProtocol.ExponentialPriceVariation"));
    LinearRewardIssuance public linearRewardIssuance =
        LinearRewardIssuance(json.readAddress(".D4AProtocol.LinearRewardIssuance"));
    ExponentialRewardIssuance public exponentialRewardIssuance =
        ExponentialRewardIssuance(json.readAddress(".D4AProtocol.ExponentialRewardIssuance"));

    // permission control
    PermissionControl public permissionControl_proxy = PermissionControl(json.readAddress(".PermissionControl.proxy"));
    PermissionControl public permissionControl_impl = PermissionControl(json.readAddress(".PermissionControl.impl"));

    // create project proxy
    D4ACreateProjectProxy public d4aCreateProjectProxy_proxy =
        D4ACreateProjectProxy(payable(json.readAddress(".D4ACreateProjectProxy.proxy")));
    D4ACreateProjectProxy public d4aCreateProjectProxy_impl =
        D4ACreateProjectProxy(payable(json.readAddress(".D4ACreateProjectProxy.impl")));

    // naive owner proxy
    NaiveOwner public naiveOwner_proxy = NaiveOwner(json.readAddress(".NaiveOwner.proxy"));
    NaiveOwner public naiveOwner_impl = NaiveOwner(json.readAddress(".NaiveOwner.impl"));

    IWETH public immutable WETH = IWETH(json.readAddress(".WETH"));
    address public immutable uniswapV2Factory = json.readAddress(".D4ASwapFactory");
    address public immutable uniswapV2Router = json.readAddress(".UniswapV2Router");
    address public immutable oracleRegistry = json.readAddress(".OracleRegistry");
    D4AUniversalClaimer public d4aUniversalClaimer = D4AUniversalClaimer(json.readAddress(".D4AUniversalClaimer"));
    address public immutable protocolV1 = json.readAddress(".D4AProtocolV1");
}
