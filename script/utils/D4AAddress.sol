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
import { D4AERC721WithFilter } from "contracts/D4AERC721WithFilter.sol";
import { D4AERC721WithFilterFactory } from "contracts/D4AERC721WithFilterFactory.sol";
import { NaiveOwner } from "contracts/NaiveOwner.sol";
import { PDProtocolReadable } from "contracts/PDProtocolReadable.sol";
import { PDProtocolSetter } from "contracts/PDProtocolSetter.sol";
import { D4ACreate } from "contracts/D4ACreate.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { PDBasicDao } from "contracts/PDBasicDao.sol";
import { PDProtocol } from "contracts/PDProtocol.sol";
import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { PDCreateProjectProxy } from "contracts/proxy/PDCreateProjectProxy.sol";
import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { D4AClaimer } from "contracts/D4AClaimer.sol";
import { D4AUniversalClaimer } from "contracts/D4AUniversalClaimer.sol";
import { LinearPriceVariation } from "contracts/templates/LinearPriceVariation.sol";
import { ExponentialPriceVariation } from "contracts/templates/ExponentialPriceVariation.sol";
import { LinearRewardIssuance } from "contracts/templates/LinearRewardIssuance.sol";
import { ExponentialRewardIssuance } from "contracts/templates/ExponentialRewardIssuance.sol";
import { UniformDistributionRewardIssuance } from "contracts/templates/UniformDistributionRewardIssuance.sol";

import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";

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

    // PDProtocol
    PDProtocol public pdProtocol_proxy = PDProtocol(payable(json.readAddress(".PDProtocol.proxy")));
    PDProtocol public pdProtocol_impl = PDProtocol(json.readAddress(".PDProtocol.impl"));
    PDProtocolReadable public pdProtocolReadable =
        PDProtocolReadable(json.readAddress(".PDProtocol.PDProtocolReadable"));
    PDProtocolSetter public pdProtocolSetter = PDProtocolSetter(json.readAddress(".PDProtocol.PDProtocolSetter"));
    D4ACreate public d4aCreate = D4ACreate(json.readAddress(".PDProtocol.D4ACreate"));
    PDCreate public pdCreate = PDCreate(json.readAddress(".PDProtocol.PDCreate"));
    //PDCreateFunding public pdCreateFunding = PDCreateFunding(json.readAddress(".PDProtocol.PDCreateFunding"));

    PDBasicDao public pdBasicDao = PDBasicDao(json.readAddress(".PDProtocol.PDBasicDao"));
    D4ASettings public d4aSettings = D4ASettings(json.readAddress(".PDProtocol.D4ASettings"));
    LinearPriceVariation public linearPriceVariation =
        LinearPriceVariation(json.readAddress(".PDProtocol.LinearPriceVariation"));
    ExponentialPriceVariation public exponentialPriceVariation =
        ExponentialPriceVariation(json.readAddress(".PDProtocol.ExponentialPriceVariation"));
    LinearRewardIssuance public linearRewardIssuance =
        LinearRewardIssuance(json.readAddress(".PDProtocol.LinearRewardIssuance"));
    ExponentialRewardIssuance public exponentialRewardIssuance =
        ExponentialRewardIssuance(json.readAddress(".PDProtocol.ExponentialRewardIssuance"));
    UniformDistributionRewardIssuance public uniformDistributionRewardIssuance =
        UniformDistributionRewardIssuance(json.readAddress(".PDProtocol.UniformDistributionRewardIssuance"));

    // permission control
    PermissionControl public permissionControl_proxy = PermissionControl(json.readAddress(".PermissionControl.proxy"));
    PermissionControl public permissionControl_impl = PermissionControl(json.readAddress(".PermissionControl.impl"));

    // pd create project proxy
    PDCreateProjectProxy public pdCreateProjectProxy_proxy =
        PDCreateProjectProxy(payable(json.readAddress(".PDCreateProjectProxy.proxy")));
    PDCreateProjectProxy public pdCreateProjectProxy_impl =
        PDCreateProjectProxy(payable(json.readAddress(".PDCreateProjectProxy.impl")));

    // Basic Dao Unlocker
    BasicDaoUnlocker public basicDaoUnlocker = BasicDaoUnlocker(json.readAddress(".BasicDaoUnlocker"));

    // naive owner proxy
    NaiveOwner public naiveOwner_proxy = NaiveOwner(json.readAddress(".NaiveOwner.proxy"));
    NaiveOwner public naiveOwner_impl = NaiveOwner(json.readAddress(".NaiveOwner.impl"));

    IWETH public immutable WETH = IWETH(json.readAddress(".WETH"));
    address public immutable uniswapV2Factory = json.readAddress(".D4ASwapFactory");
    address public immutable uniswapV2Router = json.readAddress(".UniswapV2Router");
    address public immutable oracleRegistry = json.readAddress(".OracleRegistry");
    D4AUniversalClaimer public d4aUniversalClaimer = D4AUniversalClaimer(json.readAddress(".D4AUniversalClaimer"));
}
