// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/console2.sol";

import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";

import "contracts/interface/D4AEnums.sol";
import {
    getSettingsSelectors,
    getProtocolReadableSelectors,
    getProtocolSetterSelectors,
    getD4ACreateSelectors,
    getPDCreateSelectors,
    getPDBasicDaoSelectors,
    getPDRoundSelectors,
    getPDLockSelectors,
    getPDGrantSelectors
} from "contracts/utils/CutFacetFunctions.sol";
import "./utils/D4AAddress.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";

import "contracts/interface/D4AStructs.sol";

contract DeployDemo is Script, Test, D4AAddress {
    using stdJson for string;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address public owner = 0xe6046371B729f23206a94DDCace89FEceBBD565c;

    function run() public {
        vm.startBroadcast(0xe6046371B729f23206a94DDCace89FEceBBD565c);

        _deployFeePoolFactory();

        _deployRoyaltySplitterFactory();

        _deployERC20Factory();

        _deployERC721WithFilterFactory();

        _deployNaiveOwner();
        _deployNaiveOwnerProxy();

        _deployProxyAdmin();

        _deployProtocolProxy();
        _deployProtocol();

        _deployProtocolReadable();
        _cutProtocolReadableFacet(DeployMethod.ADD);

        _deployProtocolSetter();
        _cutFacetsProtocolSetter(DeployMethod.ADD);

        _deployPDCreate();
        _cutFacetsPDCreate(DeployMethod.ADD);

        _deployPDRound();
        _cutFacetsPDRound(DeployMethod.ADD);

        _deployPDLock();
        _cutFacetsPDLock(DeployMethod.ADD);

        _deployPDGrant();
        _cutFacetsPDGrant(DeployMethod.ADD);

        _deployPDBasicDao();
        _cutFacetsPDBasicDao(DeployMethod.ADD);

        _deploySettings();
        _cutSettingsFacet(DeployMethod.ADD);

        _deployUniversalClaimer();

        _deployPermissionControl();
        _deployPermissionControlProxy();

        _initSettings();
        _initSettings13();

        _deployLinearPriceVariation();
        _deployExponentialPriceVariation();

        _deployUniformDistributionRewardIssuance();

        pdProtocol_proxy.initialize();

        PDBasicDao(address(pdProtocol_proxy)).setBasicDaoNftFlatPrice(0.01 ether);
        PDBasicDao(address(pdProtocol_proxy)).setSpecialTokenUriPrefix(
            "https://test-protodao.s3.ap-southeast-1.amazonaws.com/meta/work/"
        );

        vm.stopBroadcast();
    }

    function _deployDrb() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ADrb");

        // start from block 10160609, which is 2023-12-05 15:06:27 UTC +8 on Goerli testnet
        // blockPerDrbE18 = 5737324520819563996120 which is calculated till block 9058736 on May-25-2023 02:00:00 AM
        // +UTC
        d4aDrb = new D4ADrb({startBlock: 10160609, blocksPerDrbE18: 5737324520819563996120});
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

        console2.log("set D4AERC721WithFilterFactory address in D4ASettings");
        console2.log("================================================================================\n");
    }

    function _deployProxyAdmin() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy ProxyAdmin");

        proxyAdmin = new ProxyAdmin();
        assertTrue(address(proxyAdmin) != address(0));

        vm.toString(address(proxyAdmin)).write(path, ".ProxyAdmin");

        console2.log("ProxyAdmin address: ", address(proxyAdmin));
        console2.log("================================================================================\n");
    }

    function _deployProtocolReadable() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDProtocolReadable");

        pdProtocolReadable = new PDProtocolReadable();
        assertTrue(address(pdProtocolReadable) != address(0));

        vm.toString(address(pdProtocolReadable)).write(path, ".PDProtocol.PDProtocolReadable");

        console2.log("PDProtocolReadable address: ", address(pdProtocolReadable));
        console2.log("================================================================================\n");
    }

    function _cutProtocolReadableFacet(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDProtocolReadable facet");

        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getProtocolReadableSelectors();
        console2.log("PDProtocolReadable facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(0),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(
                    0xE17b1cf18269e172Fe5Cc3400780EB8f81608362
                    )
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdProtocolReadable),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdProtocolReadable),
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }

        console2.log("================================================================================\n");
    }

    function _deployProtocolSetter() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDProtocolSetter");

        pdProtocolSetter = new PDProtocolSetter();
        assertTrue(address(pdProtocolSetter) != address(0));

        vm.toString(address(pdProtocolSetter)).write(path, ".PDProtocol.PDProtocolSetter");

        console2.log("PDProtocolSetter address: ", address(pdProtocolSetter));
        console2.log("================================================================================\n");
    }

    function _cutFacetsProtocolSetter(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDProtocolSetter facet");

        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getProtocolSetterSelectors();
        console2.log("PDProtocolSetter facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(0),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(
                    0x9363e9B9EDbbcC2b1d1A687b4AA4c2562BAcfA3b
                    )
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdProtocolSetter),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdProtocolSetter),
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }

        console2.log("================================================================================\n");
    }

    function _deployPDRound() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDRound");

        pdRound = new PDRound();
        assertTrue(address(pdRound) != address(0));

        vm.toString(address(pdRound)).write(path, ".PDProtocol.PDRound");

        console2.log("PDRound address: ", address(pdRound));
        console2.log("================================================================================\n");
    }

    function _cutFacetsPDRound(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDRound facet");

        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getPDRoundSelectors();
        console2.log("PDRound facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(0),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(
                    0xd788fAa86488D2E62cc4F4B66ac60Cf51dC94F8c
                    ) // 在目前的的流程中，使用remove后面要添加deploy-info中现有的合约地址，其他的Remove方法也要按照这个写法修改
             });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdRound),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdRound),
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }

        console2.log("================================================================================\n");
    }

    function _deployPDCreate() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDCreate");

        pdCreate = new PDCreate(address(WETH));
        assertTrue(address(pdCreate) != address(0));

        vm.toString(address(pdCreate)).write(path, ".PDProtocol.PDCreate");

        console2.log("PDCreate address: ", address(pdCreate));
        console2.log("================================================================================\n");
    }

    function _cutFacetsPDCreate(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDCreate facet");

        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getPDCreateSelectors();
        console2.log("PDCreate facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(0),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(
                    0x2041C554dA0b9b5B798511d92Cce5957BF22F8b5
                    ) // 在目前的的流程中，使用remove后面要添加deploy-info中现有的合约地址，其他的Remove方法也要按照这个写法修改
             });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdCreate),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdCreate),
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }

        console2.log("================================================================================\n");
    }

    // function _deployPDCreateFunding() internal {
    //     console2.log("\n================================================================================");
    //     console2.log("Start deploy PDCreate");

    //     pdCreateFunding = new PDCreateFunding(address(WETH));
    //     assertTrue(address(pdCreateFunding) != address(0));

    //     vm.toString(address(pdCreateFunding)).write(path, ".PDProtocol.PDCreateFunding");

    //     console2.log("PDCreate address: ", address(pdCreateFunding));
    //     console2.log("================================================================================\n");
    // }

    // function _cutFacetsPDCreateFunding(DeployMethod deployMethod) internal {
    //     console2.log("\n================================================================================");
    //     console2.log("Start cut PDCreate facet");

    //     //------------------------------------------------------------------------------------------------------
    //     // D4AProtoclReadable facet cut
    //     //bytes4[] memory selectors = getPDCreateFundingSelectors();
    //     //console2.log("PDCreateFunding facet cut selectors number: ", selectors.length);

    //     IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

    //     if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
    //         facetCuts[0] = IDiamondWritableInternal.FacetCut({
    //             target: address(0),
    //             action: IDiamondWritableInternal.FacetCutAction.REMOVE,
    //             selectors: D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(
    //                 0xCb2aF8F8aF3B0A4C4E6a6c90ac34b405F73c8F90
    //                 ) // 在目前的的流程中，使用remove后面要添加deploy-info中现有的合约地址，其他的Remove方法也要按照这个写法修改
    //          });
    //         D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
    //     }
    //     // if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
    //     //     facetCuts[0] = IDiamondWritableInternal.FacetCut({
    //     //         target: address(pdCreateFunding),
    //     //         action: IDiamondWritableInternal.FacetCutAction.ADD,
    //     //         selectors: selectors
    //     //     });
    //     //     D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
    //     // }
    //     // if (deployMethod == DeployMethod.REPLACE) {
    //     //     facetCuts[0] = IDiamondWritableInternal.FacetCut({
    //     //         target: address(pdCreateFunding),
    //     //         action: IDiamondWritableInternal.FacetCutAction.REPLACE,
    //     //         selectors: selectors
    //     //     });
    //     //     D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
    //     // }

    //     console2.log("================================================================================\n");
    // }

    function _deployPDLock() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDLock");

        pdLock = new PDLock();
        assertTrue(address(pdLock) != address(0));

        vm.toString(address(pdLock)).write(path, ".PDProtocol.PDLock");

        console2.log("PDLock address: ", address(pdLock));
        console2.log("================================================================================\n");
    }

    function _cutFacetsPDLock(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDLock facet");

        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getPDLockSelectors();
        console2.log("PDLock facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(0),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(
                    0xd788fAa86488D2E62cc4F4B66ac60Cf51dC94F8c
                    ) // 在目前的的流程中，使用remove后面要添加deploy-info中现有的合约地址，其他的Remove方法也要按照这个写法修改
             });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdLock),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdLock),
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }

        console2.log("================================================================================\n");
    }

    function _deployPDGrant() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDGrant");

        pdGrant = new PDGrant();
        assertTrue(address(pdGrant) != address(0));

        vm.toString(address(pdGrant)).write(path, ".PDProtocol.PDGrant");

        console2.log("PDGrant address: ", address(pdGrant));
        console2.log("================================================================================\n");
    }

    function _cutFacetsPDGrant(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDGrant facet");

        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getPDGrantSelectors();
        console2.log("PDGrant facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(0),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(
                    0xd788fAa86488D2E62cc4F4B66ac60Cf51dC94F8c
                    ) // 在目前的的流程中，使用remove后面要添加deploy-info中现有的合约地址，其他的Remove方法也要按照这个写法修改
             });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdGrant),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdGrant),
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }

        console2.log("================================================================================\n");
    }

    function _deployPDBasicDao() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDBasicDao");

        pdBasicDao = new PDBasicDao();
        assertTrue(address(pdBasicDao) != address(0));

        vm.toString(address(pdBasicDao)).write(path, ".PDProtocol.PDBasicDao");

        console2.log("PDBasicDao address: ", address(pdBasicDao));
        console2.log("================================================================================\n");
    }

    function _cutFacetsPDBasicDao(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDBasicDao facet");

        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getPDBasicDaoSelectors();
        console2.log("PDBasicDao facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdBasicDao),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdBasicDao),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(pdBasicDao),
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }

        console2.log("================================================================================\n");
    }

    function _deploySettings() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ASettings");

        d4aSettings = new D4ASettings();
        assertTrue(address(d4aSettings) != address(0));

        vm.toString(address(d4aSettings)).write(path, ".PDProtocol.D4ASettings");

        console2.log("D4ASettings address: ", address(d4aSettings));
        console2.log("================================================================================\n");
    }

    function _cutSettingsFacet(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut D4ASettings facet");

        //------------------------------------------------------------------------------------------------------
        // settings facet cut
        bytes4[] memory selectors = getSettingsSelectors();
        console2.log("D4ASettings facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(0),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(
                    0x8804090945e3bA1D307f339b660BEb72EaC81fF7
                    ) // 在目前的的流程中，使用remove后面要添加deploy-info中现有的合约地址，其他的Remove方法也要按照这个写法修改
             });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(d4aSettings),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(
                facetCuts, address(d4aSettings), abi.encodeWithSelector(D4ASettings.initializeD4ASettings.selector, 0)
            );
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(d4aSettings),
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }

        console2.log("================================================================================\n");
    }

    function _deployProtocolProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDProtocol proxy");

        pdProtocol_proxy = PDProtocol(payable(new D4ADiamond()));
        assertTrue(address(pdProtocol_proxy) != address(0));

        vm.toString(address(pdProtocol_proxy)).write(path, ".PDProtocol.proxy");

        console2.log("PDProtocol proxy address: ", address(pdProtocol_proxy));
        console2.log("================================================================================\n");
    }

    function _deployProtocol() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDProtocol");

        pdProtocol_impl = new PDProtocol();
        assertTrue(address(pdProtocol_impl) != address(0));
        // proxyAdmin.upgrade(pdProtocol_proxy, address(pdProtocol_impl));
        D4ADiamond(payable(address(pdProtocol_proxy))).setFallbackAddress(address(pdProtocol_impl));

        vm.toString(address(pdProtocol_impl)).write(path, ".PDProtocol.impl");

        console2.log("PDProtocol implementation address: ", address(pdProtocol_impl));
        console2.log("================================================================================\n");
    }

    function _deployLinearPriceVariation() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy LinearPriceVariation");

        linearPriceVariation = new LinearPriceVariation();
        assertTrue(address(linearPriceVariation) != address(0));

        vm.toString(address(linearPriceVariation)).write(path, ".PDProtocol.LinearPriceVariation");

        D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
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

        vm.toString(address(exponentialPriceVariation)).write(path, ".PDProtocol.ExponentialPriceVariation");

        D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
            TemplateChoice.PRICE,
            uint8(PriceTemplateType.EXPONENTIAL_PRICE_VARIATION),
            address(exponentialPriceVariation)
        );

        console2.log("ExponentialPriceVariation address: ", address(exponentialPriceVariation));
        console2.log("================================================================================\n");
    }

    // function _deployLinearRewardIssuance() internal {
    //     console2.log("\n================================================================================");
    //     console2.log("Start deploy LinearRewardIssuance");

    //     linearRewardIssuance = new LinearRewardIssuance();
    //     assertTrue(address(linearRewardIssuance) != address(0));

    //     vm.toString(address(linearRewardIssuance)).write(path, ".PDProtocol.LinearRewardIssuance");

    //     D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
    //         TemplateChoice.REWARD, uint8(RewardTemplateType.LINEAR_REWARD_ISSUANCE), address(linearRewardIssuance)
    //     );

    //     console2.log("LinearRewardIssuance address: ", address(linearRewardIssuance));
    //     console2.log("================================================================================\n");
    // }

    // function _deployExponentialRewardIssuance() internal {
    //     console2.log("\n================================================================================");
    //     console2.log("Start deploy ExponentialRewardIssuance");

    //     exponentialRewardIssuance = new ExponentialRewardIssuance();
    //     assertTrue(address(exponentialRewardIssuance) != address(0));

    //     vm.toString(address(exponentialRewardIssuance)).write(path, ".PDProtocol.ExponentialRewardIssuance");

    //     D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
    //         TemplateChoice.REWARD,
    //         uint8(RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE),
    //         address(exponentialRewardIssuance)
    //     );

    //     console2.log("ExponentialRewardIssuance address: ", address(exponentialRewardIssuance));
    //     console2.log("================================================================================\n");
    // }

    function _deployUniformDistributionRewardIssuance() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy UniformDistributionRewardIssuance");

        uniformDistributionRewardIssuance = new UniformDistributionRewardIssuance();
        assertTrue(address(uniformDistributionRewardIssuance) != address(0));

        vm.toString(address(uniformDistributionRewardIssuance)).write(
            path, ".PDProtocol.UniformDistributionRewardIssuance"
        );

        D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
            TemplateChoice.REWARD,
            uint8(RewardTemplateType.UNIFORM_DISTRIBUTION_REWARD),
            address(uniformDistributionRewardIssuance)
        );

        console2.log("UniformDistributionRewardIssuance address: ", address(uniformDistributionRewardIssuance));
        console2.log("================================================================================\n");
    }

    // function _deployClaimer() internal {
    //     console2.log("\n================================================================================");
    //     console2.log("Start deploy D4AClaimer");

    //     d4aClaimer = new D4AClaimer(address(pdProtocol_proxy));

    //     vm.toString(address(d4aClaimer)).write(path, ".D4AClaimer");

    //     console2.log("D4AClaimer address: ", address(d4aClaimer));
    //     console2.log("================================================================================\n");
    // }

    function _deployUniversalClaimer() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AUniversalClaimer");

        d4aUniversalClaimer = new D4AUniversalClaimer();

        vm.toString(address(d4aUniversalClaimer)).write(path, ".D4AUniversalClaimer");

        console2.log("D4AUniversalClaimer address: ", address(d4aUniversalClaimer));
        console2.log("================================================================================\n");
    }

    // function _deployCreateProjectProxy() internal {
    //     console2.log("\n================================================================================");
    //     console2.log("Start deploy PDCreateProjectProxy");

    //     // 下面这段在部署失败重新部署时需要被注释掉
    //     pdCreateProjectProxy_impl = new PDCreateProjectProxy(address(WETH));
    //     assertTrue(address(pdCreateProjectProxy_impl) != address(0));
    //     //pdCreateProjectProxy_impl = PDCreateProjectProxy(payable(0x23951139124dd1803BE081e781Ba563C554D0542));

    //     proxyAdmin.upgrade(
    //         ITransparentUpgradeableProxy(address(pdCreateProjectProxy_proxy)), address(pdCreateProjectProxy_impl)
    //     );

    //     vm.toString(address(pdCreateProjectProxy_impl)).write(path, ".PDCreateProjectProxy.impl");

    //     console2.log("PDCreateProjectProxy implementation address: ", address(pdCreateProjectProxy_impl));
    //     console2.log("================================================================================\n");
    // }

    // function _deployCreateProjectProxyProxy() internal {
    //     console2.log("\n================================================================================");
    //     console2.log("Start deploy PDCreateProjectProxy proxy");

    //     pdCreateProjectProxy_proxy = PDCreateProjectProxy(
    //         payable(
    //             address(
    //                 new TransparentUpgradeableProxy(
    //                     address(pdCreateProjectProxy_impl),
    //                     address(proxyAdmin),
    //                     abi.encodeWithSignature(
    //                         "initialize(address,address,address,address)",
    //                         address(uniswapV2Factory),
    //                         address(pdProtocol_proxy),
    //                         address(d4aRoyaltySplitterFactory),
    //                         address(owner)
    //                     )
    //                 )
    //             )
    //         )
    //     );
    //     assertTrue(address(pdCreateProjectProxy_proxy) != address(0));

    //     vm.toString(address(pdCreateProjectProxy_proxy)).write(path, ".PDCreateProjectProxy.proxy");

    //     console2.log("PDCreateProjectProxy proxy address: ", address(pdCreateProjectProxy_proxy));
    //     console2.log("================================================================================\n");
    // }

    function _deployPermissionControl() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PermissionControl");

        permissionControl_impl = new PermissionControl(address(pdProtocol_proxy));
        assertTrue(address(permissionControl_impl) != address(0));
        // proxyAdmin.upgrade(
        //     ITransparentUpgradeableProxy(address(permissionControl_proxy)), address(permissionControl_impl)
        // );

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

    function _deployNaiveOwner() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy NaiveOwner");

        naiveOwner_impl = new NaiveOwner();
        assertTrue(address(naiveOwner_impl) != address(0));
        // proxyAdmin.upgrade(
        //     ITransparentUpgradeableProxy(address(permissionControl_proxy)), address(permissionControl_impl)
        // );

        vm.toString(address(naiveOwner_impl)).write(path, ".NaiveOwner.impl");

        console2.log("NaiveOwner implementation address: ", address(naiveOwner_impl));
        console2.log("================================================================================\n");
    }

    function _deployNaiveOwnerProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy NaiveOwner proxy");

        naiveOwner_proxy = NaiveOwner(
            address(
                new TransparentUpgradeableProxy(
                    address(naiveOwner_impl),
                    address(proxyAdmin),
                    abi.encodeWithSignature("initialize()")
                )
            )
        );
        assertTrue(address(naiveOwner_proxy) != address(0));

        vm.toString(address(naiveOwner_proxy)).write(path, ".NaiveOwner.proxy");

        console2.log("NaiveOwner proxy address: ", address(naiveOwner_proxy));
        console2.log("================================================================================\n");
    }

    function _initSettings() internal {
        console2.log("\n================================================================================");
        IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("PROTOCOL_ROLE"), owner);
        console2.log("Start initializing D4ASetting");
        {
            console2.log("Step 1: change address");
            D4ASettings(address(pdProtocol_proxy)).changeAddress(
                address(d4aDrb),
                address(d4aERC20Factory),
                address(d4aERC721WithFilterFactory),
                address(d4aFeePoolFactory),
                address(naiveOwner_proxy),
                address(permissionControl_proxy)
            );
        }
        {
            console2.log("Step 2: change protocol fee pool");
            D4ASettings(address(pdProtocol_proxy)).changeProtocolFeePool(owner);
        }
        {
            console2.log("Step 3: change ERC20 total supply");
            D4ASettings(address(pdProtocol_proxy)).changeERC20TotalSupply(1e9 ether);
        }
        {
            console2.log("Step 4: change asset pool owner");
            D4ASettings(address(pdProtocol_proxy)).changeAssetPoolOwner(owner);
        }
        // {
        //     console2.log("Step 5: set mintable rounds");
        //     uint256[] memory mintableRounds = new uint256[](7);
        //     mintableRounds[0] = 30;
        //     mintableRounds[1] = 60;
        //     mintableRounds[2] = 90;
        //     mintableRounds[3] = 120;
        //     mintableRounds[4] = 180;
        //     mintableRounds[5] = 270;
        //     mintableRounds[6] = 360;
        //     D4ASettings(address(pdProtocol_proxy)).setMintableRounds(mintableRounds);
        // }
        // {
        //     console2.log("Step 6: change floor prices");
        //     uint256[] memory floorPrices = new uint256[](13);
        //     floorPrices[0] = 0.01 ether;
        //     floorPrices[1] = 0.02 ether;
        //     floorPrices[2] = 0.03 ether;
        //     floorPrices[3] = 0.05 ether;
        //     floorPrices[4] = 0.1 ether;
        //     floorPrices[5] = 0.2 ether;
        //     floorPrices[6] = 0.3 ether;
        //     floorPrices[7] = 0.5 ether;
        //     floorPrices[8] = 1 ether;
        //     floorPrices[9] = 2 ether;
        //     floorPrices[10] = 3 ether;
        //     floorPrices[11] = 5 ether;
        //     floorPrices[12] = 10 ether;
        //     D4ASettings(address(pdProtocol_proxy)).changeFloorPrices(floorPrices);
        // }
        {
            console2.log("Step 7: change max NFT amounts");
            uint256[] memory maxNFTAmounts = new uint256[](5);
            maxNFTAmounts[0] = 1000;
            maxNFTAmounts[1] = 5000;
            maxNFTAmounts[2] = 10_000;
            maxNFTAmounts[3] = 50_000;
            maxNFTAmounts[4] = 100_000;
            D4ASettings(address(pdProtocol_proxy)).changeMaxNFTAmounts(maxNFTAmounts);
        }
        {
            console2.log("Step 8: grant INITIALIZER ROLE");
            naiveOwner_proxy.grantRole(naiveOwner_proxy.INITIALIZER_ROLE(), address(pdProtocol_proxy));
        }
        {
            console2.log("Step 9: grant role");
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("PROTOCOL_ROLE"), owner);
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("OPERATION_ROLE"), owner);
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("DAO_ROLE"), owner);
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("SIGNER_ROLE"), owner);
        }
        // {
        //     console2.log("Step 10: change create DOA and Canvas Fee to 0");
        //     D4ASettings(address(pdProtocol_proxy)).changeCreateFee(0 ether, 0 ether);
        // }
        // console2.log("================================================================================\n");
    }

    function _initSettings13() internal {
        // _changeAddressInDaoProxy();
        // _changeSettingsRatio();
        console2.log("change address in dao proxy");
        D4ASettings(address(pdProtocol_proxy)).setRoyaltySplitterAndSwapFactoryAddress(
            address(d4aRoyaltySplitterFactory), owner, address(uniswapV2Factory)
        );
        console2.log("change settings ratio for eth");
        D4ASettings(address(pdProtocol_proxy)).changeETHRewardRatio(200);
    }

    // function _deployUnlocker() internal {
    //     console2.log("\n================================================================================");
    //     console2.log("Start deploy BasicDaoUnlocker");

    //     basicDaoUnlocker = new BasicDaoUnlocker(address(pdProtocol_proxy));
    //     assertTrue(address(basicDaoUnlocker) != address(0));

    //     vm.toString(address(basicDaoUnlocker)).write(path, ".BasicDaoUnlocker");

    //     console2.log("basicDaoUnlocker address: ", address(basicDaoUnlocker));
    //     console2.log("================================================================================\n");
    // }
}
