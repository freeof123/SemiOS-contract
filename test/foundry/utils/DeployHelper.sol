// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IAccessControl } from "@solidstate/contracts/access/access_control/IAccessControl.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 as IUniswapV2Router } from
    "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { Denominations } from "@chainlink/contracts/src/v0.8/Denominations.sol";

import { LibString } from "solady/utils/LibString.sol";

import { FeedRegistryMock } from "test/foundry/utils/mocks/FeedRegistryMock.sol";
import { AggregatorV3Mock } from "test/foundry/utils/mocks/AggregatorV3Mock.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AConstants.sol";
import {
    PriceTemplateType, RewardTemplateType, TemplateChoice, PlanTemplateType
} from "contracts/interface/D4AEnums.sol";
import "contracts/interface/D4AStructs.sol";
import {
    getD4ACreateSelectors,
    getPDCreateSelectors,
    getPDBasicDaoSelectors,
    getSettingsSelectors,
    getProtocolReadableSelectors,
    getProtocolSetterSelectors,
    getPDGrantSelectors,
    getPDRoundSelectors,
    getPDLockSelectors,
    getPDPlanSelectors
} from "contracts/utils/CutFacetFunctions.sol";
import { ID4ASettings } from "contracts/D4ASettings/ID4ASettings.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4AERC721 } from "contracts/interface/ID4AERC721.sol";
import { IPDProtocolAggregate } from "contracts/interface/IPDProtocolAggregate.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
import { DaoTag } from "contracts/interface/D4AEnums.sol";
import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { D4AFeePoolFactory } from "contracts/feepool/D4AFeePool.sol";
import { D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { PDProtocolReadable } from "contracts/PDProtocolReadable.sol";
import { PDProtocolSetter } from "contracts/PDProtocolSetter.sol";
import { PDProtocol } from "contracts/PDProtocol.sol";
import { PDCreate } from "contracts/PDCreate.sol";
import { PDRound } from "contracts/PDRound.sol";
import { PDLock } from "contracts/PDLock.sol";
import { PDBasicDao } from "contracts/PDBasicDao.sol";
import { DummyPRB } from "contracts/test/DummyPRB.sol";
import { TestERC20 } from "contracts/test/TestERC20.sol";
import { TestERC721 } from "contracts/test/TestERC721.sol";
import { D4AUniversalClaimer } from "contracts/D4AUniversalClaimer.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import { D4AERC20Factory } from "contracts/D4AERC20.sol";
import { D4AERC721WithFilterFactory } from "contracts/D4AERC721WithFilterFactory.sol";
import { NaiveOwner } from "contracts/NaiveOwner.sol";
import { LinearPriceVariation } from "contracts/templates/LinearPriceVariation.sol";
import { ExponentialPriceVariation } from "contracts/templates/ExponentialPriceVariation.sol";
import { UniformDistributionRewardIssuance } from "contracts/templates/UniformDistributionRewardIssuance.sol";
import { DynamicPlan } from "contracts/templates/DynamicPlan.sol";
import { PDGrant } from "contracts/PDGrant.sol";
import { PDPlan } from "contracts/PDPlan.sol";

contract DeployHelper is Test {
    using LibString for string;

    ProxyAdmin public proxyAdmin = new ProxyAdmin();
    DummyPRB public drb;
    D4ASettings public settings;
    NaiveOwner public naiveOwner;
    NaiveOwner public naiveOwnerImpl;
    PDProtocolReadable public protocolReadable;
    PDProtocolSetter public protocolSetter;
    IPDProtocolAggregate public protocol;
    PDProtocol public protocolImpl;
    PDCreate public pdCreate;
    PDRound public pdRound;
    PDLock public pdLock;
    PDBasicDao public pdBasicDao;
    // PDCreateProjectProxy public daoProxy;
    // PDCreateProjectProxy public daoProxyImpl;
    PermissionControl public permissionControl;
    PermissionControl public permissionControlImpl;
    D4AERC20Factory public erc20Factory;
    D4AERC721WithFilterFactory public erc721Factory;
    D4AFeePoolFactory public feePoolFactory;
    D4ARoyaltySplitterFactory public royaltySplitterFactory;
    address public weth;
    TestERC20 internal _testERC20;
    TestERC721 internal _testERC721;
    D4AUniversalClaimer public universalClaimer;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router public uniswapV2Router;
    FeedRegistryMock public feedRegistry;
    LinearPriceVariation public linearPriceVariation;
    ExponentialPriceVariation public exponentialPriceVariation;
    UniformDistributionRewardIssuance public uniformDistributionRewardIssuance;
    DynamicPlan public dynamicPlan;
    MintNftSigUtils public mintNftSigUtils;
    PDGrant public pdGrant;
    PDPlan public pdPlan;
    //PDCreateFunding public pdCreateFunding;

    // actors
    Account public royaltySplitterOwner = makeAccount("Royalty Splitter Owner");
    Account public protocolRoleMember = makeAccount("Protocol Role Member");
    Account public operationRoleMember = makeAccount("Operation Role Member");
    Account public daoRoleMember = makeAccount("DAO Role Member");
    Account public signerRoleMember = makeAccount("Signer Role Member");
    Account public protocolFeePool = makeAccount("Protocol Fee Pool");
    Account public assetPoolOwner = makeAccount("Asset Pool Owner");
    Account public protocolOwner = makeAccount("Protocol Owner");
    Account public daoCreator = makeAccount("DAO Creator 1");
    Account public daoCreator2 = makeAccount("DAO Creator 2");
    Account public daoCreator3 = makeAccount("DAO Creator 3");

    Account public canvasCreator = makeAccount("Canvas Creator 1");
    Account public canvasCreator2 = makeAccount("Canvas Creator 2");
    Account public canvasCreator3 = makeAccount("Canvas Creator 3");
    Account public nftMinter = makeAccount("NFT Minter");
    Account public nftMinter1 = makeAccount("NFT Minter 1");
    Account public nftMinter2 = makeAccount("NFT Minter 2");
    Account public nftMinter3 = makeAccount("NFT Minter 3");

    Account public randomGuy = makeAccount("Random Guy");
    Account public randomGuy2 = makeAccount("Random Guy2");

    string public tokenUriPrefix = "https://dao4art.s3.ap-southeast-1.amazonaws.com/meta/work/";

    struct CreateContinuousDaoParam {
        bytes32 existDaoId;
        DaoMetadataParam daoMetadataParam;
        Whitelist whitelist;
        Blacklist blacklist;
        NftMinterCapInfo[] nftMinterCapInfo;
        NftMinterCapIdInfo[] nftMinterCapIdInfo;
        TemplateParam templateParam;
        BasicDaoParam basicDaoParam;
        ContinuousDaoParam continuousDaoParam;
        AllRatioParam allRatioParam;
        uint256 dailyMintCap;
    }

    function setUpEnv() public {
        _deployeWETH();
        _deployFeedRegistry();
        _deployUniswapV2Factory(protocolOwner.addr);
        _deployUniswapV2Router(address(uniswapV2Factory), address(weth));
        _deployDrb();
        _deployERC20Factory();
        _deployERC721Factory();
        _deployFeePoolFactory();
        _deployRoyaltySplitterFactory();
        _deployProtocol();
        _deployNaiveOwner();
        //_deployDaoProxy();
        _deployPermissionControl();
        _deployUniversalClaimer();
        _deployTestERC20();
        _deployAggregator();
        _deployTestERC721();
        _deployMintNftSigUtils();

        _grantRole();

        _deployPriceTemplate();
        _deployRewardTemplate();
        _deployPlanTemplate();

        _initSettings();

        drb.changeRound(1);
    }

    modifier prank(address addr) {
        vm.startPrank(addr);

        _;

        vm.stopPrank();
    }

    function _arrayToString(address[] memory accounts) internal pure returns (string memory) {
        uint256 length = accounts.length;
        string memory res;
        for (uint256 i = 0; i < length; i++) {
            res = string.concat(res, vm.toString(accounts[i]));
            if (i + 1 < length) res = string.concat(res, " ");
        }
        return res;
    }

    function getMerkleRoot(address[] memory accounts) public returns (bytes32) {
        string[] memory inputs = new string[](5);
        inputs[0] = "pnpm";
        inputs[1] = "exec";
        inputs[2] = "node";
        inputs[3] = "./test/helper/getMerkleRootFoundry.js";
        inputs[4] = _arrayToString(accounts);

        bytes memory output = vm.ffi(inputs);
        bytes32 res = abi.decode(output, (bytes32));
        return res;
    }

    function getMerkleProof(address[] memory accounts, address account) public returns (bytes32[] memory) {
        string[] memory inputs = new string[](6);
        inputs[0] = "pnpm";
        inputs[1] = "exec";
        inputs[2] = "node";
        inputs[3] = "./test/helper/getMerkleProofFoundry.js";
        inputs[4] = _arrayToString(accounts);
        inputs[5] = vm.toString(account);

        bytes memory output = vm.ffi(inputs);
        bytes32[] memory res = abi.decode(output, (bytes32[]));
        return res;
    }

    function _deployeWETH() internal prank(protocolOwner.addr) {
        weth = deployCode("contracts/build/WETH9.json");
        vm.label(address(weth), "WETH");
    }

    function _deployDrb() internal prank(protocolOwner.addr) {
        drb = new DummyPRB();
        vm.label(address(drb), "DRB");
    }

    function _deployNaiveOwner() internal prank(protocolOwner.addr) {
        naiveOwnerImpl = new NaiveOwner();
        naiveOwner = NaiveOwner(
            address(
                new TransparentUpgradeableProxy(
                    address(naiveOwnerImpl), address(proxyAdmin), abi.encodeWithSignature("initialize()")
                )
            )
        );
        vm.label(address(naiveOwner), "Naive Owner");
        vm.label(address(naiveOwnerImpl), "Naive Owner Impl");

        naiveOwner.grantRole(naiveOwner.INITIALIZER_ROLE(), address(protocol));
    }

    function _deployERC20Factory() internal prank(protocolOwner.addr) {
        erc20Factory = new D4AERC20Factory();
        vm.label(address(erc20Factory), "ERC20 Factory");
    }

    function _deployERC721Factory() internal prank(protocolOwner.addr) {
        erc721Factory = new D4AERC721WithFilterFactory();
        vm.label(address(erc721Factory), "ERC721 Factory");
    }

    function _deployFeePoolFactory() internal prank(protocolOwner.addr) {
        feePoolFactory = new D4AFeePoolFactory();
        vm.label(address(feePoolFactory), "Fee Pool Factory");
    }

    function _deployUniswapV2Factory(address feeToSetter) internal prank(protocolOwner.addr) {
        uniswapV2Factory =
            IUniswapV2Factory(deployCode("contracts/build/UniswapV2Factory.json", abi.encode(feeToSetter)));
        vm.label(address(uniswapV2Factory), "Uniswap V2 Factory");

        assertEq(uniswapV2Factory.feeToSetter(), feeToSetter);
    }

    function _deployUniswapV2Router(address factory, address WETH) internal prank(protocolOwner.addr) {
        uniswapV2Router =
            IUniswapV2Router(deployCode("contracts/build/UniswapV2Router02.json", abi.encode(uniswapV2Factory, WETH)));
        vm.label(address(uniswapV2Router), "Uniswap V2 Router");

        assertEq(uniswapV2Router.factory(), factory);
        assertEq(uniswapV2Router.WETH(), WETH);
    }

    function _deployRoyaltySplitterFactory() internal prank(protocolOwner.addr) {
        royaltySplitterFactory =
            new D4ARoyaltySplitterFactory(address(weth), address(uniswapV2Router), address(feedRegistry));
        vm.label(address(royaltySplitterFactory), "Royalty Splitter Factory");
    }

    function _deployProtocol() internal prank(protocolOwner.addr) {
        protocol = IPDProtocolAggregate(payable(new D4ADiamond()));
        protocolImpl = new PDProtocol();

        _deployPDCreate();
        _deployPDBasicDao();
        _deployProtocolReadable();
        _deployProtocolSetter();
        _deploySettings();
        _deployGrant();
        _deployPDRound();
        _deployPDLock();
        _deployPDPlan();

        _cutFacetsPDCreate();
        _cutFacetsPDBasicDao();
        _cutFacetsProtocolReadable();
        _cutFacetsProtocolSetter();
        _cutFacetsSettings();
        _cutFacetsGrant();
        _cutFacetsPDRound();
        _cutFacetsPDLock();
        _cutFacetsPDPlan();

        // set diamond fallback address
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolImpl));
        protocol.initialize();

        vm.label(address(protocol), "Protocol");
        vm.label(address(protocolImpl), "Protocol Impl");
    }

    function _deployPDCreate() internal {
        pdCreate = new PDCreate(address(weth));
        vm.label(address(pdCreate), "Proto DAO Create");
    }

    function _deployPDBasicDao() internal {
        pdBasicDao = new PDBasicDao();
        vm.label(address(pdBasicDao), "Proto DAO Basic DAO");
    }

    function _deployProtocolReadable() internal {
        protocolReadable = new PDProtocolReadable();
        vm.label(address(protocolReadable), "Protocol Readable");
    }

    function _deployProtocolSetter() internal {
        protocolSetter = new PDProtocolSetter();
        vm.label(address(protocolSetter), "Protocol Setter");
    }

    function _deploySettings() internal {
        settings = new D4ASettings();
        vm.label(address(settings), "Settings");
    }

    function _deployGrant() internal {
        pdGrant = new PDGrant();
        vm.label(address(pdGrant), "Grant");
    }

    function _deployPDRound() internal {
        pdRound = new PDRound();
        vm.label(address(pdRound), "Protocol Round");
    }

    function _deployPDLock() internal {
        pdLock = new PDLock();
        vm.label(address(pdLock), "Protocol Lock");
    }

    function _deployPDPlan() internal {
        pdPlan = new PDPlan();
        vm.label(address(pdPlan), "Protocol Plan");
    }

    function _cutFacetsPDCreate() internal {
        //------------------------------------------------------------------------------------------------------
        // PDCreate facet cut
        bytes4[] memory selectors = getPDCreateSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(pdCreate),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _cutFacetsPDBasicDao() internal {
        //------------------------------------------------------------------------------------------------------
        // PDBasicDao facet cut
        bytes4[] memory selectors = getPDBasicDaoSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(pdBasicDao),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _cutFacetsProtocolReadable() internal {
        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getProtocolReadableSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(protocolReadable),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _cutFacetsProtocolSetter() internal {
        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getProtocolSetterSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(protocolSetter),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _cutFacetsSettings() internal {
        //------------------------------------------------------------------------------------------------------
        // settings facet cut
        bytes4[] memory selectors = getSettingsSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(settings),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(
            facetCuts, address(settings), abi.encodeWithSelector(D4ASettings.initializeD4ASettings.selector, 110)
        );
    }

    function _cutFacetsGrant() internal {
        bytes4[] memory selectors = getPDGrantSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(pdGrant),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _cutFacetsPDRound() internal {
        //------------------------------------------------------------------------------------------------------
        // PDCreate facet cut
        bytes4[] memory selectors = getPDRoundSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(pdRound),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _cutFacetsPDLock() internal {
        //------------------------------------------------------------------------------------------------------
        // PDCreate facet cut
        bytes4[] memory selectors = getPDLockSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(pdLock),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _cutFacetsPDPlan() internal {
        //------------------------------------------------------------------------------------------------------
        // PDCreate facet cut
        bytes4[] memory selectors = getPDPlanSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(pdPlan),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _deployPermissionControl() internal prank(protocolOwner.addr) {
        permissionControlImpl = new PermissionControl(address(protocol));
        permissionControl = PermissionControl(
            address(
                new TransparentUpgradeableProxy(
                    address(permissionControlImpl),
                    address(proxyAdmin),
                    abi.encodeWithSignature("initialize(address)", naiveOwner)
                )
            )
        );
        vm.label(address(permissionControl), "Permission Control");
        vm.label(address(permissionControlImpl), "Permission Control Impl");
    }

    function _deployUniversalClaimer() internal prank(protocolOwner.addr) {
        universalClaimer = new D4AUniversalClaimer();
        vm.label(address(universalClaimer), "Universal Claimer");
    }

    function _deployTestERC20() internal prank(protocolOwner.addr) {
        _testERC20 = new TestERC20();
        vm.label(address(_testERC20), "ERC20 Test");
    }

    function _deployTestERC721() internal prank(protocolOwner.addr) {
        _testERC721 = new TestERC721();
        vm.label(address(_testERC721), "ERC721 Test");
    }

    function _deployMintNftSigUtils() internal prank(protocolOwner.addr) {
        mintNftSigUtils = new MintNftSigUtils(address(protocol));
        vm.label(address(mintNftSigUtils), "Mint NFT SigUtils");
    }

    function _deployFeedRegistry() internal prank(protocolOwner.addr) {
        feedRegistry = new FeedRegistryMock(protocolOwner.addr);
        vm.label(address(feedRegistry), "Feed Registry");
    }

    function _deployAggregator() internal prank(protocolOwner.addr) {
        feedRegistry.setAggregator(
            address(_testERC20), Denominations.ETH, address(new AggregatorV3Mock(1e18 / 2000, 18))
        );
    }

    function _deployPriceTemplate() internal prank(protocolRoleMember.addr) {
        linearPriceVariation = new LinearPriceVariation();
        D4ASettings(address(protocol)).setTemplateAddress(
            TemplateChoice.PRICE, uint8(PriceTemplateType.LINEAR_PRICE_VARIATION), address(linearPriceVariation)
        );
        vm.label(address(linearPriceVariation), "Linear Price Variation");

        exponentialPriceVariation = new ExponentialPriceVariation();
        D4ASettings(address(protocol)).setTemplateAddress(
            TemplateChoice.PRICE,
            uint8(PriceTemplateType.EXPONENTIAL_PRICE_VARIATION),
            address(exponentialPriceVariation)
        );
        vm.label(address(exponentialPriceVariation), "Exponential Price Variation");
    }

    function _deployRewardTemplate() internal prank(protocolRoleMember.addr) {
        // linearRewardIssuance = new LinearRewardIssuance();
        // D4ASettings(address(protocol)).setTemplateAddress(
        //     TemplateChoice.REWARD, uint8(RewardTemplateType.LINEAR_REWARD_ISSUANCE), address(linearRewardIssuance)
        // );
        // vm.label(address(linearRewardIssuance), "Linear Reward Issuance");

        // exponentialRewardIssuance = new ExponentialRewardIssuance();
        // D4ASettings(address(protocol)).setTemplateAddress(
        //     TemplateChoice.REWARD,
        //     uint8(RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE),
        //     address(exponentialRewardIssuance)
        // );
        // vm.label(address(exponentialRewardIssuance), "Exponential Reward Issuance");

        uniformDistributionRewardIssuance = new UniformDistributionRewardIssuance();
        D4ASettings(address(protocol)).setTemplateAddress(
            TemplateChoice.REWARD,
            uint8(RewardTemplateType.UNIFORM_DISTRIBUTION_REWARD),
            address(uniformDistributionRewardIssuance)
        );
        vm.label(address(uniformDistributionRewardIssuance), "Uniform Distribution Reward Issuance");
    }

    function _deployPlanTemplate() internal prank(protocolRoleMember.addr) {
        dynamicPlan = new DynamicPlan();
        D4ASettings(address(protocol)).setTemplateAddress(
            TemplateChoice.PLAN, uint8(PlanTemplateType.DYNAMIC_PLAN), address(dynamicPlan)
        );
        vm.label(address(dynamicPlan), "Dynamic Plan");
    }

    function _initSettings() internal prank(protocolRoleMember.addr) {
        _changeAddress();
        _changeProtocolFeePool();
        _changeOutputTotalSupply();
        _changeAssetPoolOwner();
        _changeMaxNFTAmounts();
        _changeAddressInDaoProxy();
        _changeSettingsRatio();
        changePrank(operationRoleMember.addr);
        protocol.setSpecialTokenUriPrefix(tokenUriPrefix);
    }

    function _changeAddress() internal {
        ID4ASettings(address(protocol)).changeAddress(
            address(erc20Factory),
            address(erc721Factory),
            address(feePoolFactory),
            address(naiveOwner),
            address(permissionControl)
        );
    }

    function _changeProtocolFeePool() internal {
        ID4ASettings(address(protocol)).changeProtocolFeePool(protocolFeePool.addr);
    }

    function _changeOutputTotalSupply() internal {
        ID4ASettings(address(protocol)).changeOutputTotalSupply(1_000_000_000 ether);
    }

    function _changeAssetPoolOwner() internal {
        ID4ASettings(address(protocol)).changeAssetPoolOwner(assetPoolOwner.addr);
    }

    function _changeMaxNFTAmounts() internal {
        uint256[] memory nftMaxAmounts = new uint256[](5);
        nftMaxAmounts[0] = 1000;
        nftMaxAmounts[1] = 5000;
        nftMaxAmounts[2] = 10_000;
        nftMaxAmounts[3] = 50_000;
        nftMaxAmounts[4] = 100_000;
        ID4ASettings(address(protocol)).changeMaxNFTAmounts(nftMaxAmounts);
    }

    function _changeAddressInDaoProxy() internal {
        ID4ASettings(address(protocol)).setRoyaltySplitterAndSwapFactoryAddress(
            address(royaltySplitterFactory), royaltySplitterOwner.addr, address(uniswapV2Factory)
        );
    }

    function _changeSettingsRatio() internal {
        ID4ASettings(address(protocol)).changeProtocolMintFeeRatio(250);
        ID4ASettings(address(protocol)).changeProtocolInputRewardRatio(200);
        ID4ASettings(address(protocol)).changeProtocolOutputRewardRatio(200);
    }

    function _grantRole() internal prank(protocolOwner.addr) {
        IAccessControl(address(protocol)).grantRole(keccak256("PROTOCOL_ROLE"), protocolRoleMember.addr);
        IAccessControl(address(protocol)).grantRole(keccak256("OPERATION_ROLE"), operationRoleMember.addr);

        changePrank(operationRoleMember.addr);
        IAccessControl(address(protocol)).grantRole(keccak256("DAO_ROLE"), daoRoleMember.addr);
        IAccessControl(address(protocol)).grantRole(keccak256("SIGNER_ROLE"), signerRoleMember.addr);
    }

    function _generateTrivialWhitelist() internal returns (Whitelist memory) {
        Whitelist memory whitelist;
        {
            whitelist.minterMerkleRoot = keccak256("test");
            whitelist.canvasCreatorMerkleRoot = keccak256("test");
            whitelist.minterNFTHolderPasses = new address[](1);
            whitelist.minterNFTHolderPasses[0] = address(new TestERC721());
            whitelist.minterNFTIdHolderPasses = new NftIdentifier[](1);
            whitelist.minterNFTIdHolderPasses[0] = NftIdentifier(address(new TestERC721()), 1);
            whitelist.canvasCreatorNFTHolderPasses = new address[](1);
            whitelist.canvasCreatorNFTHolderPasses[0] = address(new TestERC721());
            whitelist.canvasCreatorNFTIdHolderPasses = new NftIdentifier[](1);
            whitelist.canvasCreatorNFTIdHolderPasses[0] = NftIdentifier(address(new TestERC721()), 1);
        }
        return whitelist;
    }

    function _generateTrivialBlacklist() internal pure returns (Blacklist memory) {
        Blacklist memory blacklist;
        {
            blacklist.minterAccounts = new address[](2);
            blacklist.minterAccounts[0] = vm.addr(0x3);
            blacklist.minterAccounts[1] = vm.addr(0x4);
            blacklist.canvasCreatorAccounts = new address[](2);
            blacklist.canvasCreatorAccounts[0] = vm.addr(0x5);
            blacklist.canvasCreatorAccounts[1] = vm.addr(0x6);
        }
        return blacklist;
    }

    function _generateTrivialPermission()
        internal
        returns (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist)
    {
        daoId = keccak256("test");
        whitelist = _generateTrivialWhitelist();
        blacklist = _generateTrivialBlacklist();
    }

    struct CreateDaoParam {
        uint256 startBlock;
        uint256 duration;
        uint256 mintableRound;
        uint256 floorPrice;
        uint256 maxNftRank;
        uint96 royaltyFee;
        string daoUri;
        uint256 projectIndex;
        bytes32 minterMerkleRoot;
        address[] minterNFTHolderPasses;
        NftIdentifier[] minterNFTIdHolderPasses;
        NftMinterCapInfo[] nftMinterCapInfo;
        NftMinterCapIdInfo[] nftMinterCapIdInfo;
        bytes32 canvasCreatorMerkleRoot;
        address[] canvasCreatorNFTHolderPasses;
        NftIdentifier[] canvasCreatorNFTIdHolderPasses;
        address[] minterAccounts;
        address[] canvasCreatorAccounts;
        uint256 mintCap;
        address[] minters;
        uint256[] userMintCaps;
        PriceTemplateType priceTemplateType;
        uint256 priceFactor;
        RewardTemplateType rewardTemplateType;
        uint256 rewardDecayFactor;
        bool isProgressiveJackpot;
        bytes32 canvasId;
        uint256 actionType;
        uint256 unifiedPrice;
        uint256 initTokenSupplyRatio;
        //1.3add---------------------------------------
        bytes32 existDaoId;
        bool needMintableWork;
        bool uniPriceModeOff;
        uint256 reserveNftNumber;
        bool isBasicDao;
        bool topUpMode;
        uint256 dailyMintCap;
        bytes32[] childrenDaoId;
        uint256[] childrenDaoOutputRatios;
        uint256[] childrenDaoInputRatios;
        uint256 redeemPoolInputRatio;
        uint256 treasuryOutputRatio;
        uint256 treasuryInputRatio;
        uint256 selfRewardOutputRatio;
        uint256 selfRewardInputRatio;
        bool noPermission;
        bool noDefaultRatio;
        address thirdPartyToken;
        uint256 canvasCreatorMintFeeRatio;
        uint256 assetPoolMintFeeRatio;
        uint256 redeemPoolMintFeeRatio;
        uint256 treasuryMintFeeRatio;
        // * 1.3 add
        // l.protocolMintFeeRatioInBps = 250
        // sum = 9750
        uint256 canvasCreatorMintFeeRatioFiatPrice;
        uint256 assetPoolMintFeeRatioFiatPrice;
        uint256 redeemPoolMintFeeRatioFiatPrice;
        uint256 treasuryMintFeeRatioFiatPrice;
        // l.protocolOutputRewardRatio = 200
        // sum = 9800
        uint256 minterOutputRewardRatio;
        uint256 canvasCreatorOutputRewardRatio;
        uint256 daoCreatorOutputRewardRatio;
        // sum = 9800
        uint256 minterInputRewardRatio;
        uint256 canvasCreatorInputRewardRatio;
        uint256 daoCreatorInputRewardRatio;
        bool infiniteMode;
        bool outputPaymentMode;
        //1.6 add-------------------------------------------
        string ownershipUri;
        //1.7 add-------------------------------------------
        address inputToken;
    }

    struct MintNftParamTest {
        bytes32 daoId;
        bytes32 canvasId;
        string canvasUri;
        address canvasCreator;
        string tokenUri;
        //bytes nftSignature;
        uint256 flatPrice;
        bytes32[] proof;
        bytes32[] canvasProof;
        address nftOwner;
        bytes erc20Signature;
        uint256 deadline;
        NftIdentifier nftIdentifier;
        uint256 canvasCreatorKey;
    }

    // ! here
    function _createDaoForFunding(
        CreateDaoParam memory createDaoParam,
        address creator
    )
        internal
        returns (bytes32 daoId)
    {
        startHoax(creator);

        DaoMintCapParam memory daoMintCapParam;
        CreateContinuousDaoParam memory vars;
        bytes32 minterMerkleRoot;
        if (!createDaoParam.noPermission) {
            uint256 length = createDaoParam.minters.length;
            daoMintCapParam.userMintCapParams = new UserMintCapParam[](length + 1);
            for (uint256 i; i < length;) {
                daoMintCapParam.userMintCapParams[i].minter = createDaoParam.minters[i];
                daoMintCapParam.userMintCapParams[i].mintCap = uint32(createDaoParam.userMintCaps[i]);
                unchecked {
                    ++i;
                }
            }
            daoMintCapParam.userMintCapParams[length].minter = daoCreator.addr;
            daoMintCapParam.userMintCapParams[length].mintCap = 5;
            daoMintCapParam.daoMintCap = uint32(createDaoParam.mintCap);
            address[] memory minters = new address[](1);
            minters[0] = daoCreator.addr;
            minterMerkleRoot =
                createDaoParam.minterMerkleRoot == bytes32(0) ? getMerkleRoot(minters) : createDaoParam.minterMerkleRoot;
            length = createDaoParam.nftMinterCapInfo.length;
            vars.nftMinterCapInfo = new NftMinterCapInfo[](length + 1);

            for (uint256 i; i < length;) {
                vars.nftMinterCapInfo[i] = createDaoParam.nftMinterCapInfo[i];
                unchecked {
                    ++i;
                }
            }
            vars.nftMinterCapInfo[length] = NftMinterCapInfo(address(0), 5);
        } else {
            vars.nftMinterCapInfo = createDaoParam.nftMinterCapInfo;
        }
        vars.nftMinterCapIdInfo = createDaoParam.nftMinterCapIdInfo;
        vars.existDaoId = createDaoParam.existDaoId;
        vars.daoMetadataParam = DaoMetadataParam({
            startBlock: createDaoParam.startBlock,
            mintableRounds: createDaoParam.mintableRound == 0 ? 60 : createDaoParam.mintableRound,
            duration: createDaoParam.duration == 0 ? 1e18 : createDaoParam.duration,
            floorPrice: (createDaoParam.floorPrice == 0 ? 0.01 ether : createDaoParam.floorPrice),
            maxNftRank: 2,
            royaltyFee: createDaoParam.royaltyFee == 0 ? 1000 : createDaoParam.royaltyFee,
            projectUri: bytes(createDaoParam.daoUri).length == 0 ? "test dao uri" : createDaoParam.daoUri,
            projectIndex: 0
        });
        vars.whitelist = Whitelist({
            minterMerkleRoot: minterMerkleRoot,
            minterNFTHolderPasses: createDaoParam.minterNFTHolderPasses,
            minterNFTIdHolderPasses: createDaoParam.minterNFTIdHolderPasses,
            canvasCreatorMerkleRoot: createDaoParam.canvasCreatorMerkleRoot,
            canvasCreatorNFTHolderPasses: createDaoParam.canvasCreatorNFTHolderPasses,
            canvasCreatorNFTIdHolderPasses: createDaoParam.canvasCreatorNFTIdHolderPasses
        });
        vars.blacklist = Blacklist({
            minterAccounts: createDaoParam.minterAccounts,
            canvasCreatorAccounts: createDaoParam.canvasCreatorAccounts
        });

        vars.templateParam = TemplateParam({
            priceTemplateType: createDaoParam.priceTemplateType, //0 for EXPONENTIAL_PRICE_VARIATION,
            priceFactor: createDaoParam.priceFactor == 0 ? 20_000 : createDaoParam.priceFactor,
            rewardTemplateType: RewardTemplateType.UNIFORM_DISTRIBUTION_REWARD,
            rewardDecayFactor: 0,
            isProgressiveJackpot: createDaoParam.isProgressiveJackpot
        });
        vars.basicDaoParam = BasicDaoParam({
            canvasId: createDaoParam.canvasId,
            canvasUri: "test dao creator canvas uri",
            daoName: "test dao"
        });
        vars.continuousDaoParam = ContinuousDaoParam({
            reserveNftNumber: createDaoParam.reserveNftNumber == 0 ? 1000 : createDaoParam.reserveNftNumber, // 传一个500进来，spetialTokenUri应该501会Revert
            unifiedPriceModeOff: createDaoParam.uniPriceModeOff, // 把这个模式关掉之后应该会和之前按照签名的方式一样铸造，即铸造价格为0.01
            unifiedPrice: createDaoParam.unifiedPrice == 0 ? 0.01 ether : createDaoParam.unifiedPrice,
            needMintableWork: createDaoParam.needMintableWork,
            dailyMintCap: createDaoParam.dailyMintCap == 0 ? 100 : createDaoParam.dailyMintCap,
            childrenDaoId: createDaoParam.childrenDaoId,
            childrenDaoOutputRatios: createDaoParam.childrenDaoOutputRatios,
            childrenDaoInputRatios: createDaoParam.childrenDaoInputRatios,
            redeemPoolInputRatio: createDaoParam.redeemPoolInputRatio,
            treasuryOutputRatio: createDaoParam.treasuryOutputRatio,
            treasuryInputRatio: createDaoParam.treasuryInputRatio,
            selfRewardOutputRatio: createDaoParam.selfRewardOutputRatio,
            selfRewardInputRatio: createDaoParam.selfRewardInputRatio,
            isAncestorDao: createDaoParam.isBasicDao ? true : false,
            daoToken: createDaoParam.thirdPartyToken,
            topUpMode: createDaoParam.topUpMode,
            infiniteMode: createDaoParam.infiniteMode,
            outputPaymentMode: createDaoParam.outputPaymentMode,
            ownershipUri: createDaoParam.ownershipUri.eq("") ? "test ownership uri" : createDaoParam.ownershipUri,
            inputToken: createDaoParam.inputToken
        });
        if (!createDaoParam.noDefaultRatio) {
            vars.allRatioParam = AllRatioParam({
                // l.protocolMintFeeRatioInBps = 250
                // sum = 9750
                canvasCreatorMintFeeRatio: 750,
                assetPoolMintFeeRatio: 2000,
                redeemPoolMintFeeRatio: 7000,
                treasuryMintFeeRatio: 0,
                // * 1.3 add
                // l.protocolMintFeeRatioInBps = 250
                // sum = 9750
                canvasCreatorMintFeeRatioFiatPrice: 250,
                assetPoolMintFeeRatioFiatPrice: 3500,
                redeemPoolMintFeeRatioFiatPrice: 6000,
                treasuryMintFeeRatioFiatPrice: 0,
                // l.protocolOutputRewardRatio = 200
                // sum = 9800
                minterOutputRewardRatio: 800,
                canvasCreatorOutputRewardRatio: 2000,
                daoCreatorOutputRewardRatio: 7000,
                // sum = 9800
                minterInputRewardRatio: 800,
                canvasCreatorInputRewardRatio: 2000,
                daoCreatorInputRewardRatio: 7000
            });
        } else {
            vars.allRatioParam = AllRatioParam({
                // l.protocolMintFeeRatioInBps = 250
                // sum = 9750
                canvasCreatorMintFeeRatio: createDaoParam.canvasCreatorMintFeeRatio,
                assetPoolMintFeeRatio: createDaoParam.assetPoolMintFeeRatio,
                redeemPoolMintFeeRatio: createDaoParam.redeemPoolMintFeeRatio,
                treasuryMintFeeRatio: createDaoParam.treasuryMintFeeRatio,
                // * 1.3 add
                // l.protocolMintFeeRatioInBps = 250
                // sum = 9750
                canvasCreatorMintFeeRatioFiatPrice: createDaoParam.canvasCreatorMintFeeRatioFiatPrice,
                assetPoolMintFeeRatioFiatPrice: createDaoParam.assetPoolMintFeeRatioFiatPrice,
                redeemPoolMintFeeRatioFiatPrice: createDaoParam.redeemPoolMintFeeRatioFiatPrice,
                treasuryMintFeeRatioFiatPrice: createDaoParam.treasuryMintFeeRatioFiatPrice,
                // l.protocolOutputRewardRatio = 200
                // sum = 9800
                minterOutputRewardRatio: createDaoParam.minterOutputRewardRatio,
                canvasCreatorOutputRewardRatio: createDaoParam.canvasCreatorOutputRewardRatio,
                daoCreatorOutputRewardRatio: createDaoParam.daoCreatorOutputRewardRatio,
                // sum = 9800
                minterInputRewardRatio: createDaoParam.minterInputRewardRatio,
                canvasCreatorInputRewardRatio: createDaoParam.canvasCreatorInputRewardRatio,
                daoCreatorInputRewardRatio: createDaoParam.daoCreatorInputRewardRatio
            });
        }
        daoId = protocol.createDao(
            CreateSemiDaoParam(
                vars.existDaoId,
                vars.daoMetadataParam,
                vars.whitelist,
                vars.blacklist,
                daoMintCapParam,
                vars.nftMinterCapInfo,
                vars.nftMinterCapIdInfo,
                vars.templateParam,
                vars.basicDaoParam,
                vars.continuousDaoParam,
                vars.allRatioParam,
                20
            )
        );
        if (createDaoParam.isBasicDao && createDaoParam.thirdPartyToken == address(0)) {
            uint256 ratio = createDaoParam.initTokenSupplyRatio == 0 ? 500 : createDaoParam.initTokenSupplyRatio;
            uint256 initTokenAmount = ratio * 1e5 * 1e18;
            protocol.grantDaoAssetPool(
                daoId, initTokenAmount, true, "test first grant nft", protocol.getDaoToken(daoId)
            );
        }
        vm.stopPrank();
    }

    function _mintNftWithParam(MintNftParamTest memory param, address minter) internal returns (uint256 tokenId) {
        startHoax(minter);
        CreateCanvasAndMintNFTParam memory vars;
        vars.daoId = param.daoId;
        vars.canvasId = param.canvasId;
        vars.canvasUri = param.canvasUri;
        vars.canvasCreator = param.canvasCreator;
        vars.tokenUri = param.tokenUri;
        vars.flatPrice = param.flatPrice;
        vars.proof = param.proof;
        vars.canvasProof = param.canvasProof;
        vars.nftOwner = param.nftOwner == address(0) ? minter : param.nftOwner;
        vars.erc20Signature = param.erc20Signature;
        vars.deadline = param.deadline;
        vars.nftIdentifier = param.nftIdentifier;

        bytes32 digest = mintNftSigUtils.getTypedDataHash(param.canvasId, param.tokenUri, param.flatPrice);
        bytes memory sig;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(param.canvasCreatorKey, digest);
            sig = abi.encodePacked(r, s, v);
        }
        vars.nftSignature = sig;
        uint256 value;
        if (protocol.getDaoOutputPaymentMode(param.daoId)) {
            value = 0;
        } else if (
            param.flatPrice == 0 && LibString.eq(protocol.getDaoTag(param.daoId), "BASIC DAO")
                && !protocol.getDaoUnifiedPriceModeOff(param.daoId)
        ) {
            value = 0;
        } else {
            value = param.flatPrice == 0 ? protocol.getCanvasNextPrice(param.daoId, param.canvasId) : param.flatPrice;
        }

        tokenId = protocol.mintNFT{ value: value }(vars);
        vm.stopPrank();
    }

    function _mintNftWithParamChangeBal(
        MintNftParamTest memory param,
        address minter
    )
        internal
        returns (uint256 tokenId)
    {
        vm.startPrank(minter);
        CreateCanvasAndMintNFTParam memory vars;
        vars.daoId = param.daoId;
        vars.canvasId = param.canvasId;
        vars.canvasUri = param.canvasUri;
        vars.canvasCreator = param.canvasCreator;
        vars.tokenUri = param.tokenUri;
        vars.flatPrice = param.flatPrice;
        vars.proof = param.proof;
        vars.canvasProof = param.canvasProof;
        vars.nftOwner = param.nftOwner == address(0) ? minter : param.nftOwner;
        vars.erc20Signature = param.erc20Signature;
        vars.deadline = param.deadline;
        vars.nftIdentifier = param.nftIdentifier;

        bytes32 digest = mintNftSigUtils.getTypedDataHash(param.canvasId, param.tokenUri, param.flatPrice);
        bytes memory sig;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(param.canvasCreatorKey, digest);
            sig = abi.encodePacked(r, s, v);
        }
        vars.nftSignature = sig;
        uint256 value;
        if (protocol.getDaoOutputPaymentMode(param.daoId)) {
            value = 0;
        } else if (
            param.flatPrice == 0 && LibString.eq(protocol.getDaoTag(param.daoId), "BASIC DAO")
                && !protocol.getDaoUnifiedPriceModeOff(param.daoId)
        ) {
            value = 0;
        } else {
            value = param.flatPrice == 0 ? protocol.getCanvasNextPrice(param.daoId, param.canvasId) : param.flatPrice;
        }

        //1.6 add, if dao topup == false && nftIdentifier != null, he wants to spent the money in topup,
        // so there is no need to send value
        if (protocol.getDaoTopUpMode(param.daoId) == false && param.nftIdentifier.erc721Address != address(0)) {
            value = 0;
        }
        tokenId = protocol.mintNFT{ value: value }(vars);
        vm.stopPrank();
    }

    function _mintNftRevert(
        MintNftParamTest memory param,
        address minter,
        bytes4 selector
    )
        internal
        returns (uint256 tokenId)
    {
        startHoax(minter);
        CreateCanvasAndMintNFTParam memory vars;
        vars.daoId = param.daoId;
        vars.canvasId = param.canvasId;
        vars.canvasUri = param.canvasUri;
        vars.canvasCreator = param.canvasCreator;
        vars.tokenUri = param.tokenUri;
        vars.flatPrice = param.flatPrice;
        vars.proof = param.proof;
        vars.canvasProof = param.canvasProof;
        vars.nftOwner = param.nftOwner == address(0) ? minter : param.nftOwner;
        vars.erc20Signature = param.erc20Signature;
        vars.deadline = param.deadline;
        vars.nftIdentifier = param.nftIdentifier;

        bytes32 digest = mintNftSigUtils.getTypedDataHash(param.canvasId, param.tokenUri, param.flatPrice);
        bytes memory sig;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(param.canvasCreatorKey, digest);
            sig = abi.encodePacked(r, s, v);
        }
        vars.nftSignature = sig;
        uint256 value;
        if (protocol.getDaoOutputPaymentMode(param.daoId)) {
            value = 0;
        } else if (
            param.flatPrice == 0 && LibString.eq(protocol.getDaoTag(param.daoId), "BASIC DAO")
                && !protocol.getDaoUnifiedPriceModeOff(param.daoId)
        ) {
            value = 0;
        } else {
            value = param.flatPrice == 0 ? protocol.getCanvasNextPrice(param.daoId, param.canvasId) : param.flatPrice;
        }

        vm.expectRevert(selector);
        tokenId = protocol.mintNFT{ value: value }(vars);
        vm.stopPrank();
    }

    function _mintNft(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice,
        uint256 canvasCreatorKey,
        address hoaxer
    )
        internal
        returns (uint256 tokenId)
    {
        uint256 bal = hoaxer.balance;
        startHoax(hoaxer);
        tokenId = _mint(daoId, canvasId, tokenUri, flatPrice, canvasCreatorKey, hoaxer);
        vm.stopPrank();
        deal(hoaxer, bal);
    }

    // * 1.3 add
    function _mintNftChangeBal(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice,
        uint256 canvasCreatorKey,
        address hoaxer
    )
        internal
        returns (uint256 tokenId)
    {
        vm.startPrank(hoaxer);
        tokenId = _mint(daoId, canvasId, tokenUri, flatPrice, canvasCreatorKey, hoaxer);
        vm.stopPrank();
    }

    function _mint(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice,
        uint256 canvasCreatorKey,
        address hoaxer
    )
        internal
        returns (uint256 tokenId)
    {
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        bytes memory sig;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreatorKey, digest);
            sig = abi.encodePacked(r, s, v);
        }
        uint256 value;
        if (protocol.getDaoOutputPaymentMode(daoId) || (protocol.getDaoInputToken(daoId) != address(0))) {
            value = 0;
        } else if (
            flatPrice == 0 && LibString.eq(protocol.getDaoTag(daoId), "BASIC DAO")
                && !protocol.getDaoUnifiedPriceModeOff(daoId)
        ) {
            value = 0;
        } else {
            value = flatPrice == 0 ? protocol.getCanvasNextPrice(daoId, canvasId) : flatPrice;
        }
        CreateCanvasAndMintNFTParam memory vars;
        vars.daoId = daoId;
        vars.canvasId = canvasId;
        vars.tokenUri = tokenUri;
        vars.nftOwner = hoaxer;
        vars.nftSignature = sig;
        vars.flatPrice = flatPrice;
        tokenId = protocol.mintNFT{ value: value }(vars);
    }

    function _createCanvasAndMintNft(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        string memory canvasUri,
        uint256 flatPrice,
        uint256 canvasCreatorKey,
        address canvasOwner,
        address hoaxer
    )
        internal
        returns (uint256 tokenId)
    {
        startHoax(hoaxer);
        CreateCanvasAndMintNFTParam memory vars;
        vars.daoId = daoId;
        vars.canvasId = canvasId;
        vars.canvasUri = canvasUri;
        vars.canvasCreator = canvasOwner;
        vars.tokenUri = tokenUri;
        {
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreatorKey, digest);
            vars.nftSignature = abi.encodePacked(r, s, v);
        }
        vars.flatPrice = flatPrice;
        vars.proof = new bytes32[](0);
        vars.canvasProof = new bytes32[](0);
        vars.nftOwner = hoaxer;
        uint256 value;
        if (protocol.getDaoOutputPaymentMode(daoId)) {
            value = 0;
        } else if (
            flatPrice == 0 && LibString.eq(protocol.getDaoTag(daoId), "BASIC DAO")
                && !protocol.getDaoUnifiedPriceModeOff(daoId)
        ) {
            //开启全局一口价，但是为0
            value = 0;
        } else {
            //未开启全局一口价，或开启全局一口价但不为0，value=flatPrice，或flatPrice=0时value为系统定价
            value = flatPrice == 0 ? protocol.getCanvasNextPrice(daoId, canvasId) : flatPrice;
        }
        tokenId = protocol.mintNFT{ value: value }(vars);
        vm.stopPrank();
    }

    function _grantPool(bytes32 daoId, address granter, uint256 amount) internal {
        address token = protocol.getDaoToken(daoId);
        vm.prank(granter);
        protocol.grantDaoAssetPool(daoId, amount, true, "test", token);
    }

    struct MintNftWithProofLocalVars {
        bytes32 daoId;
        bytes32 canvasId;
        string tokenUri;
        uint256 flatPrice;
        uint256 canvasCreatorKey;
        address hoaxer;
        bytes32[] proof;
    }
}
