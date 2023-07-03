// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/Console2.sol";

import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import "contracts/interface/D4AEnums.sol";
import {
    getSettingsSelectors,
    getProtocolReadableSelectors,
    getProtocolSetterSelectors
} from "contracts/utils/CutFacetFunctions.sol";
import { D4AFeePoolFactory } from "contracts/feepool/D4AFeePool.sol";
import { D4ARoyaltySplitter } from "contracts/royalty-splitter/D4ARoyaltySplitter.sol";
import { D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import { D4AERC20Factory } from "contracts/D4AERC20.sol";
import { D4AERC721WithFilterFactory } from "contracts/D4AERC721WithFilter.sol";
import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { NaiveOwner } from "contracts/NaiveOwner.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { D4AProtocol } from "contracts/D4AProtocol.sol";
import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { D4ACreateProjectProxy } from "contracts/proxy/D4ACreateProjectProxy.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import { D4ADrb } from "contracts/D4ADrb.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4ASettings } from "contracts/D4ASettings/ID4ASettings.sol";
import { D4AAddress } from "./utils/D4AAddress.sol";
import { D4AClaimer } from "contracts/D4AClaimer.sol";
import { LinearPriceVariation } from "contracts/templates/LinearPriceVariation.sol";
import { ExponentialPriceVariation } from "contracts/templates/ExponentialPriceVariation.sol";
import { LinearRewardIssuance } from "contracts/templates/LinearRewardIssuance.sol";
import { ExponentialRewardIssuance } from "contracts/templates/ExponentialRewardIssuance.sol";

contract Deploy is Script, Test, D4AAddress {
    using stdJson for string;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address public owner = vm.addr(deployerPrivateKey);

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        // _deployDrb();

        // _deployFeePoolFactory();

        // _deployRoyaltySplitterFactory();

        // _deployERC20Factory();

        // _deployERC721WithFilterFactory();

        // _deployProtocolProxy();
        // _deployProtocol();

        // _deployProtocolReadable();
        // _cutProtocolReadableFacet();

        // _deployProtocolSetter();
        // _cutFacetsProtocolSetter();

        // _deploySettings();
        // _cutSettingsFacet();

        // _deployClaimer();

        // _deployCreateProjectProxy();
        // _deployCreateProjectProxyProxy();

        // _deployPermissionControl();
        // _deployPermissionControlProxy();

        // _initSettings();

        // _deployLinearPriceVariation();
        // _deployExponentialPriceVariation();
        // _deployLinearRewardIssuance();
        // _deployExponentialRewardIssuance();

        vm.stopBroadcast();
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

    function _deployProtocolReadable() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AProtocolReadable");

        d4aProtocolReadable = new D4AProtocolReadable();
        assertTrue(address(d4aProtocolReadable) != address(0));

        vm.toString(address(d4aProtocolReadable)).write(path, ".D4AProtocol.D4AProtocolReadable");

        console2.log("D4AProtocolReadable address: ", address(d4aProtocolReadable));
        console2.log("================================================================================\n");
    }

    function _cutProtocolReadableFacet() internal {
        console2.log("\n================================================================================");
        console2.log("Start cut D4AProtocolRedable facet");

        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getProtocolReadableSelectors();
        console2.log("D4AProtocolReadable facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(d4aProtocolReadable),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(d4aProtocol_proxy))).diamondCut(facetCuts, address(0), "");

        console2.log("================================================================================\n");
    }

    function _deployProtocolSetter() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AProtocolSetter");

        d4aProtocolSetter = new D4AProtocolSetter();
        assertTrue(address(d4aProtocolSetter) != address(0));

        vm.toString(address(d4aProtocolSetter)).write(path, ".D4AProtocol.D4AProtocolSetter");

        console2.log("D4AProtocolSetter address: ", address(d4aProtocolSetter));
        console2.log("================================================================================\n");
    }

    function _cutFacetsProtocolSetter() internal {
        console2.log("\n================================================================================");
        console2.log("Start cut ProtocolSetter facet");

        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getProtocolSetterSelectors();
        console2.log("D4AProtocolSetter facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(d4aProtocolSetter),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(d4aProtocol_proxy))).diamondCut(facetCuts, address(0), "");

        console2.log("================================================================================\n");
    }

    function _deploySettings() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ASettings");

        d4aSettings = new D4ASettings();
        assertTrue(address(d4aSettings) != address(0));

        vm.toString(address(d4aSettings)).write(path, ".D4AProtocol.D4ASettings");

        console2.log("D4ASettings address: ", address(d4aSettings));
        console2.log("================================================================================\n");
    }

    function _cutSettingsFacet() internal {
        console2.log("\n================================================================================");
        console2.log("Start cut D4ASettings facet");

        //------------------------------------------------------------------------------------------------------
        // settings facet cut
        bytes4[] memory selectors = getSettingsSelectors();
        console2.log("D4ASettings facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(d4aSettings),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(d4aProtocol_proxy))).diamondCut(
            facetCuts, address(d4aSettings), abi.encodeWithSelector(ID4ASettings.initializeD4ASettings.selector)
        );

        console2.log("================================================================================\n");
    }

    function _deployProtocolProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AProtocol proxy");

        d4aProtocol_proxy = D4AProtocol(payable(new D4ADiamond()));
        assertTrue(address(d4aProtocol_proxy) != address(0));

        vm.toString(address(d4aProtocol_proxy)).write(path, ".D4AProtocol.proxy");

        console2.log("D4AProtocol proxy address: ", address(d4aProtocol_proxy));
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

    function _deployLinearPriceVariation() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy LinearPriceVariation");

        linearPriceVariation = new LinearPriceVariation();
        assertTrue(address(linearPriceVariation) != address(0));

        vm.toString(address(linearPriceVariation)).write(path, ".D4AProtocol.LinearPriceVariation");

        ID4ASettings(address(d4aProtocol_proxy)).setTemplateAddress(
            TemplateChoice.PRICE, uint8(PriceTemplateType.LINEAR_PRICE_VARIATION), address(linearPriceVariation)
        );

        console2.log("LinearPriceVariation address: ", address(linearPriceVariation));
        console2.log("================================================================================\n");
    }

    function _deployExponentialPriceVariation() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy ExponentialPriceVariation");

        exponentialPriceVariation = new ExponentialPriceVariation();
        assertTrue(address(exponentialPriceVariation) != address(0));

        vm.toString(address(exponentialPriceVariation)).write(path, ".D4AProtocol.ExponentialPriceVariation");

        ID4ASettings(address(d4aProtocol_proxy)).setTemplateAddress(
            TemplateChoice.PRICE,
            uint8(PriceTemplateType.EXPONENTIAL_PRICE_VARIATION),
            address(exponentialPriceVariation)
        );

        console2.log("ExponentialPriceVariation address: ", address(exponentialPriceVariation));
        console2.log("================================================================================\n");
    }

    function _deployLinearRewardIssuance() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy LinearRewardIssuance");

        linearRewardIssuance = new LinearRewardIssuance();
        assertTrue(address(linearRewardIssuance) != address(0));

        vm.toString(address(linearRewardIssuance)).write(path, ".D4AProtocol.LinearRewardIssuance");

        ID4ASettings(address(d4aProtocol_proxy)).setTemplateAddress(
            TemplateChoice.REWARD, uint8(RewardTemplateType.LINEAR_REWARD_ISSUANCE), address(linearRewardIssuance)
        );

        console2.log("LinearRewardIssuance address: ", address(linearRewardIssuance));
        console2.log("================================================================================\n");
    }

    function _deployExponentialRewardIssuance() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy ExponentialRewardIssuance");

        exponentialRewardIssuance = new ExponentialRewardIssuance();
        assertTrue(address(exponentialRewardIssuance) != address(0));

        vm.toString(address(exponentialRewardIssuance)).write(path, ".D4AProtocol.ExponentialRewardIssuance");

        ID4ASettings(address(d4aProtocol_proxy)).setTemplateAddress(
            TemplateChoice.REWARD,
            uint8(RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE),
            address(exponentialRewardIssuance)
        );

        console2.log("ExponentialRewardIssuance address: ", address(exponentialRewardIssuance));
        console2.log("================================================================================\n");
    }

    function _deployClaimer() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AClaimer");

        d4aClaimer = new D4AClaimer(address(d4aProtocol_proxy));

        vm.toString(address(d4aClaimer)).write(path, ".D4AClaimer");

        console2.log("D4AClaimer address: ", address(d4aClaimer));
        console2.log("================================================================================\n");
    }

    function _deployCreateProjectProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ACreateProjectProxy");

        d4aCreateProjectProxy_impl = new D4ACreateProjectProxy(address(WETH));
        assertTrue(address(d4aCreateProjectProxy_impl) != address(0));
        proxyAdmin.upgrade(
            ITransparentUpgradeableProxy(address(d4aCreateProjectProxy_proxy)), address(d4aCreateProjectProxy_impl)
        );

        vm.toString(address(d4aCreateProjectProxy_impl)).write(path, ".D4ACreateProjectProxy.impl");

        console2.log("D4ACreateProjectProxy implementation address: ", address(d4aCreateProjectProxy_impl));
        console2.log("================================================================================\n");
    }

    function _deployCreateProjectProxyProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ACreateProjectProxy proxy");

        d4aCreateProjectProxy_proxy = D4ACreateProjectProxy(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(d4aCreateProjectProxy_impl),
                        address(proxyAdmin),
                        abi.encodeWithSignature(
                            "initialize(address,address,address,address)",
                            address(uniswapV2Factory),
                            address(d4aProtocol_proxy),
                            address(d4aRoyaltySplitterFactory), 
                            address(owner) 
                        )
                    )
                )
            )
        );
        assertTrue(address(d4aCreateProjectProxy_proxy) != address(0));

        vm.toString(address(d4aCreateProjectProxy_proxy)).write(path, ".D4ACreateProjectProxy.proxy");

        console2.log("D4ACreateProjectProxy proxy address: ", address(d4aCreateProjectProxy_proxy));
        console2.log("================================================================================\n");
    }

    function _deployPermissionControl() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PermissionControl");

        permissionControl_impl = new PermissionControl(address(d4aProtocol_proxy), address(d4aCreateProjectProxy_proxy));
        assertTrue(address(permissionControl_impl) != address(0));
        proxyAdmin.upgrade(
            ITransparentUpgradeableProxy(address(permissionControl_proxy)), address(permissionControl_impl)
        );

        vm.toString(address(permissionControl_impl)).write(path, ".PermissionControl.impl");

        console2.log("PermissionControl implementation address: ", address(permissionControl_impl));
        console2.log("================================================================================\n");
    }

    function _deployPermissionControlProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PermissionControl proxy");

        permissionControl_proxy = PermissionControl(
            address(
                new TransparentUpgradeableProxy(
                    address(permissionControl_impl), 
                    address(proxyAdmin),
                    abi.encodeWithSignature(
                        "initialize(address)",
                        address(naiveOwner_proxy)
                    )
                )
            )
        );
        assertTrue(address(permissionControl_proxy) != address(0));

        vm.toString(address(permissionControl_proxy)).write(path, ".PermissionControl.proxy");

        console2.log("PermissionControl proxy address: ", address(permissionControl_proxy));
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
                json.readAddress(".NaiveOwner.proxy"),
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
            console2.log("Step 5: set mintable rounds");
            uint256[] memory mintableRounds = new uint256[](7);
            mintableRounds[0] = 30;
            mintableRounds[1] = 60;
            mintableRounds[2] = 90;
            mintableRounds[3] = 120;
            mintableRounds[4] = 180;
            mintableRounds[5] = 270;
            mintableRounds[6] = 360;
            ID4ASettings(address(d4aProtocol_proxy)).setMintableRounds(mintableRounds);
        }
        {
            console2.log("Step 6: change floor prices");
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
            ID4ASettings(address(d4aProtocol_proxy)).changeFloorPrices(floorPrices);
        }
        {
            console2.log("Step 7: change max NFT amounts");
            uint256[] memory maxNFTAmounts = new uint256[](5);
            maxNFTAmounts[0] = 1000;
            maxNFTAmounts[1] = 5000;
            maxNFTAmounts[2] = 10_000;
            maxNFTAmounts[3] = 50_000;
            maxNFTAmounts[4] = 100_000;
            ID4ASettings(address(d4aProtocol_proxy)).changeMaxNFTAmounts(maxNFTAmounts);
        }
        {
            console2.log("Step 8: grant INITIALIZER ROLE");
            NaiveOwner naiveOwner_proxy = NaiveOwner(json.readAddress(".NaiveOwner.proxy"));
            naiveOwner_proxy.grantRole(naiveOwner_proxy.INITIALIZER_ROLE(), address(d4aProtocol_proxy));
        }
        {
            console2.log("Step 9: grant role");
            IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("PROTOCOL_ROLE"), owner);
            IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("OPERATION_ROLE"), owner);
            IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("DAO_ROLE"), owner);
            IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("SIGNER_ROLE"), owner);
        }
        {
            console2.log("Step 10: change create DOA and Canvas Fee to 0");
            ID4ASettings(address(d4aProtocol_proxy)).changeCreateFee(0 ether, 0 ether);
        }
        console2.log("================================================================================\n");
    }
}
