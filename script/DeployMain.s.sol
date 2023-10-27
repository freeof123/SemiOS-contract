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
import { DiamondWritable, IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/DiamondWritable.sol";
import { DiamondFallback } from "@solidstate/contracts/proxy/diamond/fallback/DiamondFallback.sol";
import "contracts/interface/D4AEnums.sol";
import "contracts/interface/D4AConstants.sol";
import {
    getSettingsSelectors,
    getProtocolReadableSelectors,
    getProtocolSetterSelectors,
    getD4ACreateSelectors,
    getPDCreateSelectors,
    getPDBasicDaoSelectors
} from "contracts/utils/CutFacetFunctions.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import "./utils/D4AAddress.sol";

contract DeployDemo is Script, Test, D4AAddress {
    using stdJson for string;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    //     address public owner = 0x778c35DEc2f75dC959c53B6929C74efb0043358A;
    //     // address public owner = vm.addr(deployerPrivateKey);
    // =======
    //     //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address public owner = 0x778c35DEc2f75dC959c53B6929C74efb0043358A;
    // address public owner = vm.addr(deployerPrivateKey);
    //address public owner = 0x28cdd6D234f6301FbFb207DD9e5AC82E7E60833e;
    address multisig = json.readAddress(".MultiSig1");
    address multisig2 = json.readAddress(".MultiSig2");

    function run() public {
        //vm.startBroadcast(owner);
        //vm.startPrank(owner);

        // _deployDrb();

        // _deployFeePoolFactory();  // transfer proxyAdmin owner to multisig

        // _deployRoyaltySplitterFactory();

        // _deployERC20Factory();

        // _deployERC721WithFilterFactory();

        // _deployProxyAdmin();

        // _deployProtocolProxy();
        //_deployProtocol();

        //_deployProtocolReadable();
        //_cutProtocolReadableFacet(DeployMethod.REMOVE_AND_ADD);

        // _deployProtocolSetter();
        // _cutFacetsProtocolSetter(DeployMethod.REMOVE_AND_ADD);

        // _deployD4ACreate();
        // _cutFacetsD4ACreate();

        //_deployPDCreate();
        // _cutFacetsPDCreate(DeployMethod.REPLACE);

        // _deployPDBasicDao();
        // _cutFacetsPDBasicDao();

        // _deployD4ACreate();
        // _cutFacetsD4ACreate();

        // _deployPDCreate();
        // _cutFacetsPDCreate();

        // _deployPDBasicDao();
        // _cutFacetsPDBasicDao();

        // _deploySettings();
        // _cutSettingsFacet();

        // _deployClaimer();
        // _deployUniversalClaimer();

        //_deployCreateProjectProxy();
        // _deployCreateProjectProxyProxy();

        //_deployPermissionControl();
        // _deployPermissionControlProxy();

        // _initSettings();

        // _deployLinearPriceVariation();
        // _deployExponentialPriceVariation();
        _deployLinearRewardIssuance();
        _deployExponentialRewardIssuance();

        // pdProtocol_proxy.initialize();

        // PDBasicDao(address(pdProtocol_proxy)).setBasicDaoNftFlatPrice(0.01 ether);
        // PDBasicDao(address(pdProtocol_proxy)).setSpecialTokenUriPrefix(
        //     "https://protodao.s3.ap-southeast-1.amazonaws.com/meta/work/"
        // );

        _transferOwnership();
        //_deployUnlocker();
        //_transferOwnership();

        //_checkStatus();
        //vm.stopBroadcast();
        //vm.stopPrank();
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
        PDCreateProjectProxy(payable(address(pdCreateProjectProxy_proxy))).set(
            address(pdProtocol_proxy), address(d4aRoyaltySplitterFactory), owner, uniswapV2Factory
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
                    0xce6a9F68ae3c2cA5212018190D31fa0E7C78D1b8
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
                    0x70F4E21518b51e8A0248B51E58af324b4bED882e
                    )
            });
            // console2.log("Remove PDProtocolSetter Facet Data:");
            // console2.logBytes(abi.encodeCall(DiamondWritable.diamondCut, (facetCuts, address(0), "")));
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
                    0xf90282C227a5018dCee69de5F4a43bF71db0fc7d
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

    function _deployD4ACreate() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ACreate");

        d4aCreate = new D4ACreate();
        assertTrue(address(d4aCreate) != address(0));

        vm.toString(address(d4aCreate)).write(path, ".PDProtocol.D4ACreate");

        console2.log("D4ACreate address: ", address(d4aCreate));
        console2.log("================================================================================\n");
    }

    function _cutFacetsD4ACreate() internal {
        console2.log("\n================================================================================");
        console2.log("Start cut D4ACreate facet");

        //------------------------------------------------------------------------------------------------------
        // D4ACreate facet cut
        bytes4[] memory selectors = getD4ACreateSelectors();
        console2.log("D4ACreate facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(d4aCreate),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");

        console2.log("================================================================================\n");
    }

    function _deployPDCreate() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDCreate");

        pdCreate = new PDCreate();
        assertTrue(address(pdCreate) != address(0));

        vm.toString(address(pdCreate)).write(path, ".PDProtocol.PDCreate");

        console2.log("PDCreate address: ", address(pdCreate));
        console2.log("================================================================================\n");
    }

    function _cutFacetsPDCreate() internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDCreate facet");

        //------------------------------------------------------------------------------------------------------
        // PDCreate facet cut
        bytes4[] memory selectors = getPDCreateSelectors();
        console2.log("PDCreate facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(pdCreate),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");

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

    function _cutFacetsPDBasicDao() internal {
        console2.log("\n================================================================================");
        console2.log("Start cut PDBasicDao facet");

        //------------------------------------------------------------------------------------------------------
        // PDBasicDao facet cut
        bytes4[] memory selectors = getPDBasicDaoSelectors();
        console2.log("PDBasicDao facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(pdBasicDao),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");

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

        // TODO: change 137 to different when deploying to mainnet
        // (bool succ, bytes memory data) =
        //     address(0x7995198FE6A9668911927c67C8184BbF24E42774).call(abi.encodeWithSignature("project_num()"));
        // assertTrue(succ);
        // uint256 daoIndex = abi.decode(data, (uint256));
        // assertEq(daoIndex, 127);
        // console2.log("daoIndex: %s", daoIndex);
        D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(
            facetCuts, address(d4aSettings), abi.encodeWithSelector(D4ASettings.initializeD4ASettings.selector, 111)
        );

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

        // console2.log("Set Fallback Address Data:");
        // console2.logBytes(abi.encodeCall(DiamondFallback.setFallbackAddress, (address(pdProtocol_impl))));

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

    function _deployLinearRewardIssuance() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy LinearRewardIssuance");

        //linearRewardIssuance = new LinearRewardIssuance();
        //assertTrue(address(linearRewardIssuance) != address(0));

        //vm.toString(address(linearRewardIssuance)).write(path, ".PDProtocol.LinearRewardIssuance");

        console2.log("Set Linear Reward Template Data:");
        console2.logBytes(
            abi.encodeCall(
                D4ASettings.setTemplateAddress,
                (
                    TemplateChoice.REWARD,
                    uint8(RewardTemplateType.LINEAR_REWARD_ISSUANCE),
                    0xAc8362825D4bC08d50F7B195Bcebe4E302C7965a
                )
            )
        );
        // D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
        //     TemplateChoice.REWARD, uint8(RewardTemplateType.LINEAR_REWARD_ISSUANCE), address(linearRewardIssuance)
        // );

        console2.log("LinearRewardIssuance address: ", address(linearRewardIssuance));
        console2.log("================================================================================\n");
    }

    function _deployExponentialRewardIssuance() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy ExponentialRewardIssuance");

        //exponentialRewardIssuance = new ExponentialRewardIssuance();
        //assertTrue(address(exponentialRewardIssuance) != address(0));

        //vm.toString(address(exponentialRewardIssuance)).write(path, ".PDProtocol.ExponentialRewardIssuance");

        console2.log("Set Exponential Reward Template Data:");
        console2.logBytes(
            abi.encodeCall(
                D4ASettings.setTemplateAddress,
                (
                    TemplateChoice.REWARD,
                    uint8(RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE),
                    0x555D5FdC1fcbEB86d404D9D861A4481876c65524
                )
            )
        );

        // D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
        //     TemplateChoice.REWARD,
        //     uint8(RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE),
        //     address(exponentialRewardIssuance)
        // );

        console2.log("ExponentialRewardIssuance address: ", address(exponentialRewardIssuance));
        console2.log("================================================================================\n");
    }

    function _deployClaimer() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AClaimer");

        d4aClaimer = new D4AClaimer(address(pdProtocol_proxy));

        vm.toString(address(d4aClaimer)).write(path, ".D4AClaimer");

        console2.log("D4AClaimer address: ", address(d4aClaimer));
        console2.log("================================================================================\n");
    }

    function _deployUniversalClaimer() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4AUniversalClaimer");

        d4aUniversalClaimer = new D4AUniversalClaimer();

        vm.toString(address(d4aUniversalClaimer)).write(path, ".D4AUniversalClaimer");

        console2.log("D4AUniversalClaimer address: ", address(d4aUniversalClaimer));
        console2.log("================================================================================\n");
    }

    function _deployCreateProjectProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDCreateProjectProxy");

        pdCreateProjectProxy_impl = new PDCreateProjectProxy(address(WETH));
        assertTrue(address(pdCreateProjectProxy_impl) != address(0));

        console2.log("Update Create Project Proxy Data:");
        console2.logBytes(
            abi.encodeCall(
                ProxyAdmin.upgrade,
                (ITransparentUpgradeableProxy(address(pdCreateProjectProxy_proxy)), address(pdCreateProjectProxy_impl))
            )
        );

        // proxyAdmin.upgrade(
        //     ITransparentUpgradeableProxy(address(pdCreateProjectProxy_proxy)), address(pdCreateProjectProxy_impl)
        // );

        vm.toString(address(pdCreateProjectProxy_impl)).write(path, ".PDCreateProjectProxy.impl");

        console2.log("PDCreateProjectProxy implementation address: ", address(pdCreateProjectProxy_impl));
        console2.log("================================================================================\n");
    }

    function _deployCreateProjectProxyProxy() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PDCreateProjectProxy proxy");

        pdCreateProjectProxy_proxy = PDCreateProjectProxy(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(pdCreateProjectProxy_impl),
                        address(proxyAdmin),
                        abi.encodeWithSignature(
                            "initialize(address,address,address,address)",
                            address(uniswapV2Factory),
                            address(pdProtocol_proxy),
                            address(d4aRoyaltySplitterFactory), 
                            address(owner) 
                        )
                    )
                )
            )
        );
        assertTrue(address(pdCreateProjectProxy_proxy) != address(0));

        vm.toString(address(pdCreateProjectProxy_proxy)).write(path, ".PDCreateProjectProxy.proxy");

        console2.log("PDCreateProjectProxy proxy address: ", address(pdCreateProjectProxy_proxy));
        console2.log("================================================================================\n");
    }

    function _deployPermissionControl() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy PermissionControl");

        permissionControl_impl = new PermissionControl(address(pdProtocol_proxy), address(pdCreateProjectProxy_proxy));
        assertTrue(address(permissionControl_impl) != address(0));

        console2.log("Update Permission Control Data:");
        console2.logBytes(
            abi.encodeCall(
                ProxyAdmin.upgrade,
                (ITransparentUpgradeableProxy(address(permissionControl_proxy)), address(permissionControl_impl))
            )
        );
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

    function _deployUnlocker() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy BasicDaoUnlocker");

        basicDaoUnlocker = new BasicDaoUnlocker(address(pdProtocol_proxy));
        assertTrue(address(basicDaoUnlocker) != address(0));

        vm.toString(address(basicDaoUnlocker)).write(path, ".BasicDaoUnlocker");

        console2.log("basicDaoUnlocker address: ", address(basicDaoUnlocker));
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
                json.readAddress(".NaiveOwner.proxy"),
                address(pdCreateProjectProxy_proxy),
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
            D4ASettings(address(pdProtocol_proxy)).setMintableRounds(mintableRounds);
        }
        {
            console2.log("Step 6: change floor prices");
            uint256[] memory floorPrices = new uint256[](13);
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
            D4ASettings(address(pdProtocol_proxy)).changeFloorPrices(floorPrices);
        }
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
        // {
        //     console2.log("Step 8: grant INITIALIZER ROLE");
        //     NaiveOwner naiveOwner_proxy = NaiveOwner(json.readAddress(".NaiveOwner.proxy"));
        //     naiveOwner_proxy.grantRole(naiveOwner_proxy.INITIALIZER_ROLE(), address(pdProtocol_proxy));
        // }
        {
            console2.log("Step 9: grant role");
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("PROTOCOL_ROLE"), owner);
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("OPERATION_ROLE"), owner);
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("DAO_ROLE"), owner);
        }
        {
            console2.log("Step 10: change create DOA and Canvas Fee to 0");
            D4ASettings(address(pdProtocol_proxy)).changeCreateFee(0 ether, 0 ether);
        }
        console2.log("================================================================================\n");
    }

    function _transferOwnership() internal {
        // create project proxy
        pdCreateProjectProxy_proxy.set(
            address(pdProtocol_proxy), address(d4aRoyaltySplitterFactory), multisig, uniswapV2Factory
        );
        pdCreateProjectProxy_proxy.transferOwnership(multisig);

        // protocol
        D4ADiamond(payable(address(pdProtocol_proxy))).transferOwnership(multisig);

        // settings
        D4ASettings(address(pdProtocol_proxy)).changeProtocolFeePool(multisig);
        D4ASettings(address(pdProtocol_proxy)).changeAssetPoolOwner(multisig2);
        D4ASettings(address(pdProtocol_proxy)).grantRole(DEFAULT_ADMIN_ROLE, multisig);
        D4ASettings(address(pdProtocol_proxy)).grantRole(PROTOCOL_ROLE, multisig);
        D4ASettings(address(pdProtocol_proxy)).grantRole(OPERATION_ROLE, multisig2);
        D4ASettings(address(pdProtocol_proxy)).renounceRole(DEFAULT_ADMIN_ROLE);
        D4ASettings(address(pdProtocol_proxy)).renounceRole(PROTOCOL_ROLE);
        D4ASettings(address(pdProtocol_proxy)).renounceRole(OPERATION_ROLE);
    }

    function _checkStatus() internal {
        // proxy admin
        assertEq(proxyAdmin.owner(), multisig);
        assertEq(
            proxyAdmin.getProxyAdmin(ITransparentUpgradeableProxy(address(pdCreateProjectProxy_proxy))),
            address(proxyAdmin)
        );
        assertEq(
            proxyAdmin.getProxyAdmin(ITransparentUpgradeableProxy(address(permissionControl_proxy))),
            address(proxyAdmin)
        );
        assertEq(
            proxyAdmin.getProxyImplementation(ITransparentUpgradeableProxy(address(pdCreateProjectProxy_proxy))),
            address(pdCreateProjectProxy_impl)
        );
        assertEq(
            proxyAdmin.getProxyImplementation(ITransparentUpgradeableProxy(address(permissionControl_proxy))),
            address(permissionControl_impl)
        );

        // create project proxy
        assertEq(pdCreateProjectProxy_proxy.WETH(), address(WETH));
        assertEq(address(pdCreateProjectProxy_proxy.d4aswapFactory()), address(uniswapV2Factory));
        assertEq(pdCreateProjectProxy_proxy.owner(), multisig);
        assertEq(address(pdCreateProjectProxy_proxy.protocol()), address(pdProtocol_proxy));
        assertEq(address(pdCreateProjectProxy_proxy.royaltySplitterFactory()), address(d4aRoyaltySplitterFactory));
        assertEq(pdCreateProjectProxy_proxy.royaltySplitterOwner(), multisig);

        // protocol
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetAddresses()[0], address(pdProtocol_proxy));
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetAddresses()[1], address(pdProtocolReadable));
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetAddresses()[2], address(pdProtocolSetter));
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetAddresses()[3], address(d4aCreate));
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetAddresses()[4], address(pdCreate));
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetAddresses()[5], address(pdBasicDao));
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetAddresses()[6], address(d4aSettings));
        assertEq(
            D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(address(pdProtocol_proxy)).length, 12
        );
        assertEq(
            D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(address(pdProtocolReadable)).length,
            64
        );
        assertEq(
            D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(address(pdProtocolSetter)).length, 12
        );
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(address(d4aCreate)).length, 3);
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(address(pdCreate)).length, 4);
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).facetFunctionSelectors(address(d4aSettings)).length, 35);
        assertEq(D4ADiamond(payable(address(pdProtocol_proxy))).getFallbackAddress(), address(pdProtocol_impl));
        assertTrue(
            D4ADiamond(payable(address(pdProtocol_proxy))).owner() == multisig
                || D4ADiamond(payable(address(pdProtocol_proxy))).nomineeOwner() == multisig
        );
        (, string memory name, string memory version,,,,) = pdProtocol_proxy.eip712Domain();
        assertEq(name, "ProtoDaoProtocol");
        assertEq(version, "1");

        // settings
        assertEq(D4ASettings(address(pdProtocol_proxy)).createCanvasFee(), 0);
        assertEq(D4ASettings(address(pdProtocol_proxy)).createProjectFee(), 0);
        assertEq(D4ASettings(address(pdProtocol_proxy)).getPriceTemplates()[0], address(exponentialPriceVariation));
        assertEq(D4ASettings(address(pdProtocol_proxy)).getPriceTemplates()[1], address(linearPriceVariation));
        assertEq(D4ASettings(address(pdProtocol_proxy)).getRewardTemplates()[0], address(linearRewardIssuance));
        assertEq(D4ASettings(address(pdProtocol_proxy)).getRewardTemplates()[1], address(exponentialRewardIssuance));
        assertTrue(D4ASettings(address(pdProtocol_proxy)).hasRole(DEFAULT_ADMIN_ROLE, multisig));
        assertTrue(D4ASettings(address(pdProtocol_proxy)).hasRole(PROTOCOL_ROLE, multisig));
        assertTrue(D4ASettings(address(pdProtocol_proxy)).hasRole(OPERATION_ROLE, multisig2));
        assertEq(D4ASettings(address(pdProtocol_proxy)).mintProjectFeeRatio(), 3000);
        assertEq(D4ASettings(address(pdProtocol_proxy)).mintProjectFeeRatioFlatPrice(), 3500);
        assertEq(D4ASettings(address(pdProtocol_proxy)).mintProtocolFeeRatio(), 250);
        assertEq(address(D4ASettings(address(pdProtocol_proxy)).ownerProxy()), address(naiveOwner_proxy));
        assertEq(address(D4ASettings(address(pdProtocol_proxy)).permissionControl()), address(permissionControl_proxy));
        assertEq(address(D4ASettings(address(pdProtocol_proxy)).protocolFeePool()), multisig);
        assertEq(D4ASettings(address(pdProtocol_proxy)).ratioBase(), BASIS_POINT);
        assertEq(D4ASettings(address(pdProtocol_proxy)).tradeProtocolFeeRatio(), 250);

        // permission control
        assertEq(address(permissionControl_proxy.createProjectProxy()), address(pdCreateProjectProxy_proxy));
        (, name, version,,,,) = permissionControl_proxy.eip712Domain();
        assertEq(name, "D4APermissionControl");
        assertEq(version, "2");
        assertEq(address(permissionControl_proxy.ownerProxy()), address(naiveOwner_proxy));
        assertEq(address(permissionControl_proxy.protocol()), address(pdProtocol_proxy));
    }
}
