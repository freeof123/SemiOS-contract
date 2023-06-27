// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/Console2.sol";

import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import { D4AFeePoolFactory } from "contracts/feepool/D4AFeePool.sol";
import { D4ARoyaltySplitter } from "contracts/royalty-splitter/D4ARoyaltySplitter.sol";
import { D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import { D4AERC20Factory } from "contracts/D4AERC20.sol";
import { D4AERC721WithFilterFactory } from "contracts/D4AERC721WithFilter.sol";
import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { NaiveOwner } from "contracts/NaiveOwner.sol";
import { D4AProtocol } from "contracts/D4AProtocol.sol";
import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { D4ACreateProjectProxy } from "contracts/proxy/D4ACreateProjectProxy.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import { D4ADrb } from "contracts/D4ADrb.sol";
import { ID4ASettings } from "contracts/D4ASettings/ID4ASettings.sol";
import { D4AAddress } from "./utils/D4AAddress.sol";
import { D4AClaimer } from "contracts/D4AClaimer.sol";

contract Deploy is Script, Test, D4AAddress {
    using stdJson for string;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address public owner = vm.addr(deployerPrivateKey);

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        _deployClaimer();

        // _deployDrb();

        // _deployFeePoolFactory();

        // _deployRoyaltySplitterFactory();

        // _deployERC20Factory();

        // _deployERC721WithFilterFactory();

        // _deploySettings();

        // _deployProtocol();

        // _deployPermissionControl();

        // _deployCreateProjectProxy();

        // _initSettings();

        vm.stopBroadcast();
    }

    function _deployClaimer() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AClaimer");

        d4aClaimer = new D4AClaimer(address(d4aProtocol_proxy));

        vm.toString(address(d4aClaimer)).write(path, ".D4AClaimer");

        console2.log("D4AClaimer address: ", address(d4aClaimer));
        console2.log("================================================================================\n");
    }

    function _deployDrb() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ADrb");

        // start from block 8335355 which is Jan-19-2023 12:00:00 AM +UTC on Goerli testnet
        // blockPerDrbE18 = 5737324520819563996120 which is calculated till block 9058736 on May-25-2023 02:00:00 AM
        // +UTC
        d4aDrb = new D4ADrb({startBlock: 8335355, blocksPerDrbE18: 5737324520819563996120});
        assertTrue(address(d4aDrb) != address(0));

        vm.toString(address(d4aDrb)).write(path, ".D4ADrb");

        console2.log("D4ADrb address: ", address(d4aDrb));
        console2.log("================================================================================\n");
    }

    function _deployFeePoolFactory() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AFeePoolFactory");

        d4aFeePoolFactory = new D4AFeePoolFactory();
        assertTrue(address(d4aFeePoolFactory) != address(0));

        vm.toString(address(d4aFeePoolFactory)).write(path, ".factories.D4AFeePoolFactory");

        console2.log("D4AFeePoolFactory address: ", address(d4aFeePoolFactory));
        console2.log("================================================================================\n");
    }

    function _deployRoyaltySplitterFactory() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ARoyaltySplitterFactory");

        d4aRoyaltySplitterFactory = new D4ARoyaltySplitterFactory(address(WETH), uniswapV2Router, oracleRegistry);
        assertTrue(address(d4aRoyaltySplitterFactory) != address(0));
        D4ACreateProjectProxy(payable(address(d4aCreateProjectProxy_proxy))).set(
            address(d4aProtocol_proxy), address(d4aRoyaltySplitterFactory), owner, uniswapV2Factory
        );

        vm.toString(address(d4aRoyaltySplitterFactory)).write(path, ".factories.D4ARoyaltySplitterFactory");

        console2.log("D4ARoyaltySplitterFactory address: ", address(d4aRoyaltySplitterFactory));
        console2.log("================================================================================\n");
    }

    function _deployERC20Factory() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AERC20Factory");

        d4aERC20Factory = new D4AERC20Factory();
        assertTrue(address(d4aERC20Factory) != address(0));

        vm.toString(address(d4aERC20Factory)).write(path, ".factories.D4AERC20Factory");

        console2.log("D4AERC20Factory address: ", address(d4aERC20Factory));
        console2.log("================================================================================\n");
    }

    function _deployERC721WithFilterFactory() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AERC721WithFilterFactory");

        d4aERC721WithFilterFactory = new D4AERC721WithFilterFactory();
        assertTrue(address(d4aERC721WithFilterFactory) != address(0));

        vm.toString(address(d4aERC721WithFilterFactory)).write(path, ".factories.D4AERC721WithFilterFactory");

        console2.log("D4AERC721WithFilterFactory address: ", address(d4aERC721WithFilterFactory));
        console2.log("================================================================================\n");
    }

    function _deploySettings() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ASettings");

        d4aSettings = new D4ASettings();
        assertTrue(address(d4aSettings) != address(0));

        vm.toString(address(d4aSettings)).write(path, ".D4AProtocol.D4ASettings");

        console2.log("D4ASetting address: ", address(d4aSettings));
        console2.log("================================================================================\n");
    }

    function _deployProtocol() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AProtocol");

        d4aProtocol_impl = new D4AProtocol();
        assertTrue(address(d4aProtocol_impl) != address(0));
        // proxyAdmin.upgrade(d4aProtocol_proxy, address(d4aProtocol_impl));
        D4ADiamond(payable(address(d4aProtocol_proxy))).setFallbackAddress(address(d4aProtocol_impl));

        vm.toString(address(d4aProtocol_impl)).write(path, ".D4AProtocol.impl");

        console2.log("D4AProtocol implementation address: ", address(d4aProtocol_impl));
        console2.log("================================================================================\n");
    }

    function _deployPermissionControl() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PermissionControl");

        permissionControl_impl = new PermissionControl(address(d4aProtocol_proxy), address(d4aCreateProjectProxy_proxy));
        assertTrue(address(permissionControl_impl) != address(0));
        proxyAdmin.upgrade(permissionControl_proxy, address(permissionControl_impl));

        vm.toString(address(permissionControl_impl)).write(path, ".PermissionControl.impl");

        console2.log("PermissionControl implementation address: ", address(permissionControl_impl));
        console2.log("================================================================================\n");
    }

    function _deployCreateProjectProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ACreateProjectProxy");

        d4aCreateProjectProxy_impl = new D4ACreateProjectProxy(address(WETH));
        assertTrue(address(d4aCreateProjectProxy_impl) != address(0));
        proxyAdmin.upgrade(d4aCreateProjectProxy_proxy, address(d4aCreateProjectProxy_impl));

        vm.toString(address(d4aCreateProjectProxy_impl)).write(path, ".D4ACreateProjectProxy.impl");

        console2.log("D4ACreateProjectProxy implementation address: ", address(d4aCreateProjectProxy_impl));
        console2.log("================================================================================\n");
    }

    function _initSettings() internal {
        console2.log("\n================================================================================");
        IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("PROTOCOL_ROLE"), owner);
        console2.log("Start initializing D4ASetting");
        {
            console2.log("Step 1: change address");
            ID4ASettings(address(d4aProtocol_proxy)).changeAddress(
                address(d4aDrb),
                address(d4aERC20Factory),
                address(d4aERC721WithFilterFactory),
                address(d4aFeePoolFactory),
                json.readAddress("NaiveOwner_proxy"),
                address(d4aCreateProjectProxy_proxy),
                address(permissionControl_proxy)
            );
        }
        {
            console2.log("Step 2: change protocol fee pool");
            ID4ASettings(address(d4aProtocol_proxy)).changeProtocolFeePool(owner);
        }
        {
            console2.log("Step 3: change ERC20 total supply");
            ID4ASettings(address(d4aProtocol_proxy)).changeERC20TotalSupply(1e9 ether);
        }
        {
            console2.log("Step 4: change asset pool owner");
            ID4ASettings(address(d4aProtocol_proxy)).changeAssetPoolOwner(owner);
        }
        {
            console2.log("Step 5: change floor prices");
            uint256[] memory floorPrices = new uint256[](14);
            floorPrices[0] = 0.01 ether;
            floorPrices[1] = 0.02 ether;
            floorPrices[2] = 0.03 ether;
            floorPrices[3] = 0.05 ether;
            floorPrices[4] = 0.1 ether;
            floorPrices[5] = 0.2 ether;
            floorPrices[6] = 0.3 ether;
            floorPrices[7] = 0.5 ether;
            floorPrices[8] = 1 ether;
            floorPrices[9] = 2 ether;
            floorPrices[10] = 3 ether;
            floorPrices[11] = 5 ether;
            floorPrices[12] = 10 ether;
            floorPrices[13] = 0 ether;
            ID4ASettings(address(d4aProtocol_proxy)).changeFloorPrices(floorPrices);
        }
        {
            console2.log("Step 6: change max NFT amounts");
            uint256[] memory maxNFTAmounts = new uint256[](5);
            maxNFTAmounts[0] = 1000;
            maxNFTAmounts[1] = 5000;
            maxNFTAmounts[2] = 10_000;
            maxNFTAmounts[3] = 50_000;
            maxNFTAmounts[4] = 100_000;
            ID4ASettings(address(d4aProtocol_proxy)).changeMaxNFTAmounts(maxNFTAmounts);
        }
        {
            console2.log("Step 7: grant INITIALIZER ROLE");
            NaiveOwner naiveOwner_proxy = NaiveOwner(json.readAddress("NaiveOwner_proxy"));
            naiveOwner_proxy.grantRole(naiveOwner_proxy.INITIALIZER_ROLE(), address(d4aProtocol_proxy));
        }

        {
            console2.log("Step 8: grant role");
            IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("PROTOCOL_ROLE"), owner);
            IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("OPERATION_ROLE"), owner);
            IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("DAO_ROLE"), owner);
            IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("SIGNER_ROLE"), owner);
        }
        console2.log("================================================================================\n");
    }
}
