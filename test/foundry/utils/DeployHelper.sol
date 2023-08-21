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

import { FeedRegistryMock } from "test/foundry/utils/mocks/FeedRegistryMock.sol";
import { AggregatorV3Mock } from "test/foundry/utils/mocks/AggregatorV3Mock.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AConstants.sol";
import { PriceTemplateType, RewardTemplateType, TemplateChoice } from "contracts/interface/D4AEnums.sol";
import "contracts/interface/D4AStructs.sol";
import {
    getD4ACreateSelectors,
    getPDCreateSelectors,
    getPDBasicDaoSelectors,
    getSettingsSelectors,
    getProtocolReadableSelectors,
    getProtocolSetterSelectors,
    getGrantSelectors
} from "contracts/utils/CutFacetFunctions.sol";
import { ID4ASettings } from "contracts/D4ASettings/ID4ASettings.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4AERC721 } from "contracts/interface/ID4AERC721.sol";
import { ID4AProtocol } from "contracts/interface/ID4AProtocol.sol";
import { IPDProtocolAggregate } from "contracts/interface/IPDProtocolAggregate.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { D4AFeePoolFactory } from "contracts/feepool/D4AFeePool.sol";
import { D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { PDCreateProjectProxy } from "contracts/proxy/PDCreateProjectProxy.sol";
// import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";
// import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { PDProtocolReadable } from "contracts/PDProtocolReadable.sol";
import { PDProtocolSetter } from "contracts/PDProtocolSetter.sol";
// import { D4AProtocol } from "contracts/D4AProtocol.sol";
import { PDProtocol } from "contracts/PDProtocol.sol";
import { PDCreate } from "contracts/PDCreate.sol";
import { D4ACreate } from "contracts/D4ACreate.sol";
import { PDBasicDao } from "contracts/PDBasicDao.sol";
import { DummyPRB } from "contracts/test/DummyPRB.sol";
import { TestERC20 } from "contracts/test/TestERC20.sol";
import { TestERC721 } from "contracts/test/TestERC721.sol";
import { D4AClaimer } from "contracts/D4AClaimer.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import { D4AERC20Factory } from "contracts/D4AERC20.sol";
import { D4AERC721Factory } from "contracts/D4AERC721.sol";
import { NaiveOwner } from "contracts/NaiveOwner.sol";
import { LinearPriceVariation } from "contracts/templates/LinearPriceVariation.sol";
import { ExponentialPriceVariation } from "contracts/templates/ExponentialPriceVariation.sol";
import { LinearRewardIssuance } from "contracts/templates/LinearRewardIssuance.sol";
import { ExponentialRewardIssuance } from "contracts/templates/ExponentialRewardIssuance.sol";
import { PDGrant } from "contracts/PDGrant.sol";

contract DeployHelper is Test {
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
    D4ACreate public d4aCreate;
    PDBasicDao public pdBasicDao;
    PDCreateProjectProxy public daoProxy;
    PDCreateProjectProxy public daoProxyImpl;
    PermissionControl public permissionControl;
    PermissionControl public permissionControlImpl;
    D4AERC20Factory public erc20Factory;
    D4AERC721Factory public erc721Factory;
    D4AFeePoolFactory public feePoolFactory;
    D4ARoyaltySplitterFactory public royaltySplitterFactory;
    address public weth;
    TestERC20 internal _testERC20;
    TestERC721 internal _testERC721;
    D4AClaimer public claimer;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router public uniswapV2Router;
    FeedRegistryMock public feedRegistry;
    LinearPriceVariation public linearPriceVariation;
    ExponentialPriceVariation public exponentialPriceVariation;
    LinearRewardIssuance public linearRewardIssuance;
    ExponentialRewardIssuance public exponentialRewardIssuance;
    MintNftSigUtils public mintNftSigUtils;
    PDGrant public grant;

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
    Account public canvasCreator = makeAccount("Canvas Creator 1");
    Account public canvasCreator2 = makeAccount("Canvas Creator 2");
    Account public canvasCreator3 = makeAccount("Canvas Creator 3");
    Account public nftMinter = makeAccount("NFT Minter 1");
    Account public nftMinter2 = makeAccount("NFT Minter 2");
    Account public randomGuy = makeAccount("Random Guy");

    string public tokenUriPrefix = "https://dao4art.s3.ap-southeast-1.amazonaws.com/meta/work/";

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
        _deployDaoProxy();
        _deployPermissionControl();
        _deployClaimer();
        _deployTestERC20();
        _deployAggregator();
        _deployTestERC721();
        _deployMintNftSigUtils();

        _grantRole();

        _deployPriceTemplate();
        _deployRewardTemplate();

        _initSettings();

        vm.startPrank(operationRoleMember.addr);
        protocol.setSpecialTokenUriPrefix(tokenUriPrefix);
        protocol.setBasicDaoNftFlatPrice(0.01 ether);
        vm.stopPrank();

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
                    address(naiveOwnerImpl),
                    address(proxyAdmin),
                    abi.encodeWithSignature("initialize()")
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
        erc721Factory = new D4AERC721Factory();
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

        _deployD4ACreate();
        _deployPDCreate();
        _deployPDBasicDao();
        _deployProtocolReadable();
        _deployProtocolSetter();
        _deploySettings();
        _deployGrant();

        _cutFacetsD4ACreate();
        _cutFacetsPDCreate();
        _cutFacetsPDBasicDao();
        _cutFacetsProtocolReadable();
        _cutFacetsProtocolSetter();
        _cutFacetsSettings();
        _cutFacetsGrant();

        // set diamond fallback address
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolImpl));
        protocol.initialize();

        vm.label(address(protocol), "Protocol");
        vm.label(address(protocolImpl), "Protocol Impl");
    }

    function _deployD4ACreate() internal {
        d4aCreate = new D4ACreate();
        vm.label(address(d4aCreate), "D4A Create");
    }

    function _deployPDCreate() internal {
        pdCreate = new PDCreate();
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
        grant = new PDGrant();
        vm.label(address(grant), "Grant");
    }

    function _cutFacetsD4ACreate() internal {
        //------------------------------------------------------------------------------------------------------
        // D4ACreate facet cut
        bytes4[] memory selectors = getD4ACreateSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(d4aCreate),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
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
        bytes4[] memory selectors = getGrantSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(grant),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _deployDaoProxy() internal prank(protocolOwner.addr) {
        daoProxyImpl = new PDCreateProjectProxy(address(weth));
        daoProxy = PDCreateProjectProxy(
            payable(
                new TransparentUpgradeableProxy(
                    address(daoProxyImpl),
                    address(proxyAdmin),
                    abi.encodeWithSelector(
                        PDCreateProjectProxy.initialize.selector,
                        address(uniswapV2Factory),
                        address(protocol),
                        address(royaltySplitterFactory),
                        royaltySplitterOwner
                    )
                )
            )
        );
        vm.label(address(daoProxy), "DAO Proxy");
        vm.label(address(daoProxyImpl), "DAO Proxy Impl");
    }

    function _deployPDDaoProxy() internal prank(protocolOwner.addr) {
        daoProxyImpl = new PDCreateProjectProxy(address(weth));
        daoProxy = PDCreateProjectProxy(
            payable(
                new TransparentUpgradeableProxy(
                    address(daoProxyImpl),
                    address(proxyAdmin),
                    abi.encodeWithSelector(
                        PDCreateProjectProxy.initialize.selector,
                        address(uniswapV2Factory),
                        address(protocol),
                        address(royaltySplitterFactory),
                        royaltySplitterOwner
                    )
                )
            )
        );
        vm.label(address(daoProxy), "PD DAO Proxy");
        vm.label(address(daoProxyImpl), "PD DAO Proxy Impl");
    }

    function _deployPermissionControl() internal prank(protocolOwner.addr) {
        permissionControlImpl = new PermissionControl(address(protocol), address(daoProxy));
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

    function _deployClaimer() internal prank(protocolOwner.addr) {
        claimer = new D4AClaimer(address(protocol));
        vm.label(address(claimer), "Claimer");
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
            address(_testERC20), Denominations.ETH, address(new AggregatorV3Mock(1e18 / 2_000, 18))
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
        linearRewardIssuance = new LinearRewardIssuance();
        D4ASettings(address(protocol)).setTemplateAddress(
            TemplateChoice.REWARD, uint8(RewardTemplateType.LINEAR_REWARD_ISSUANCE), address(linearRewardIssuance)
        );
        vm.label(address(linearRewardIssuance), "Linear Reward Issuance");

        exponentialRewardIssuance = new ExponentialRewardIssuance();
        D4ASettings(address(protocol)).setTemplateAddress(
            TemplateChoice.REWARD,
            uint8(RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE),
            address(exponentialRewardIssuance)
        );
        vm.label(address(exponentialRewardIssuance), "Exponential Reward Issuance");
    }

    function _initSettings() internal prank(protocolRoleMember.addr) {
        _changeAddress();
        _changeProtocolFeePool();
        _changeERC20TotalSupply();
        _changeAssetPoolOwner();
        _changeMintableRounds();
        _changeFloorPrices();
        _changeMaxNFTAmounts();
    }

    function _changeAddress() internal {
        ID4ASettings(address(protocol)).changeAddress(
            address(drb),
            address(erc20Factory),
            address(erc721Factory),
            address(feePoolFactory),
            address(naiveOwner),
            address(daoProxy),
            address(permissionControl)
        );
    }

    function _changeProtocolFeePool() internal {
        ID4ASettings(address(protocol)).changeProtocolFeePool(protocolFeePool.addr);
    }

    function _changeERC20TotalSupply() internal {
        ID4ASettings(address(protocol)).changeERC20TotalSupply(1_000_000_000 ether);
    }

    function _changeAssetPoolOwner() internal {
        ID4ASettings(address(protocol)).changeAssetPoolOwner(assetPoolOwner.addr);
    }

    function _changeMintableRounds() internal {
        uint256[] memory mintableRounds = new uint256[](7);
        mintableRounds[0] = 30;
        mintableRounds[1] = 60;
        mintableRounds[2] = 90;
        mintableRounds[3] = 120;
        mintableRounds[4] = 180;
        mintableRounds[5] = 270;
        mintableRounds[6] = 360;
        ID4ASettings(address(protocol)).setMintableRounds(mintableRounds);
    }

    function _changeFloorPrices() internal {
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
        ID4ASettings(address(protocol)).changeFloorPrices(floorPrices);
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
            whitelist.canvasCreatorNFTHolderPasses = new address[](1);
            whitelist.canvasCreatorNFTHolderPasses[0] = address(new TestERC721());
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
        uint256 startDrb;
        uint256 mintableRound;
        uint256 floorPriceRank;
        uint256 maxNftRank;
        uint96 royaltyFee;
        string daoUri;
        uint256 projectIndex;
        bytes32 minterMerkleRoot;
        address[] minterNFTHolderPasses;
        bytes32 canvasCreatorMerkleRoot;
        address[] canvasCreatorNFTHolderPasses;
        address[] minterAccounts;
        address[] canvasCreatorAccounts;
        uint256 mintCap;
        address[] minters;
        uint256[] userMintCaps;
        uint256 daoCreatorERC20RatioInBps;
        uint256 canvasCreatorERC20RatioInBps;
        uint256 nftMinterERC20RatioInBps;
        uint256 daoFeePoolETHRatioInBps;
        uint256 daoFeePoolETHRatioInBpsFlatPrice;
        PriceTemplateType priceTemplateType;
        uint256 priceFactor;
        RewardTemplateType rewardTemplateType;
        uint256 rewardDecayFactor;
        bool isProgressiveJackpot;
        bytes32 canvasId;
        uint256 actionType;
    }

    function _createDao(CreateDaoParam memory createDaoParam) internal returns (bytes32 daoId) {
        startHoax(daoCreator.addr);

        DaoMintCapParam memory daoMintCapParam;
        {
            uint256 length = createDaoParam.minters.length;
            daoMintCapParam.userMintCapParams = new UserMintCapParam[](length);
            for (uint256 i; i < length;) {
                daoMintCapParam.userMintCapParams[i].minter = createDaoParam.minters[i];
                daoMintCapParam.userMintCapParams[i].mintCap = uint32(createDaoParam.userMintCaps[i]);
                unchecked {
                    ++i;
                }
            }
            daoMintCapParam.daoMintCap = uint32(createDaoParam.mintCap);
        }

        daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: createDaoParam.startDrb == 0 ? drb.currentRound() : createDaoParam.startDrb,
                mintableRounds: createDaoParam.mintableRound == 0 ? 30 : createDaoParam.mintableRound,
                floorPriceRank: createDaoParam.floorPriceRank,
                maxNftRank: createDaoParam.maxNftRank,
                royaltyFee: createDaoParam.royaltyFee == 0 ? 750 : createDaoParam.royaltyFee,
                projectUri: bytes(createDaoParam.daoUri).length == 0 ? "test dao uri" : createDaoParam.daoUri,
                projectIndex: createDaoParam.projectIndex
            }),
            Whitelist({
                minterMerkleRoot: createDaoParam.minterMerkleRoot,
                minterNFTHolderPasses: createDaoParam.minterNFTHolderPasses,
                canvasCreatorMerkleRoot: createDaoParam.canvasCreatorMerkleRoot,
                canvasCreatorNFTHolderPasses: createDaoParam.canvasCreatorNFTHolderPasses
            }),
            Blacklist({
                minterAccounts: createDaoParam.minterAccounts,
                canvasCreatorAccounts: createDaoParam.canvasCreatorAccounts
            }),
            daoMintCapParam,
            DaoETHAndERC20SplitRatioParam({
                daoCreatorERC20Ratio: createDaoParam.daoCreatorERC20RatioInBps == 0
                    ? 300
                    : createDaoParam.daoCreatorERC20RatioInBps,
                canvasCreatorERC20Ratio: createDaoParam.canvasCreatorERC20RatioInBps == 0
                    ? 9500
                    : createDaoParam.canvasCreatorERC20RatioInBps,
                nftMinterERC20Ratio: createDaoParam.nftMinterERC20RatioInBps == 0
                    ? 0
                    : createDaoParam.nftMinterERC20RatioInBps,
                daoFeePoolETHRatio: createDaoParam.daoFeePoolETHRatioInBps == 0
                    ? 3000
                    : createDaoParam.daoFeePoolETHRatioInBps,
                daoFeePoolETHRatioFlatPrice: createDaoParam.daoFeePoolETHRatioInBpsFlatPrice == 0
                    ? 3500
                    : createDaoParam.daoFeePoolETHRatioInBpsFlatPrice
            }),
            TemplateParam({
                priceTemplateType: createDaoParam.priceTemplateType,
                priceFactor: createDaoParam.priceFactor == 0 ? 20_000 : createDaoParam.priceFactor,
                rewardTemplateType: createDaoParam.rewardTemplateType,
                rewardDecayFactor: createDaoParam.rewardDecayFactor,
                isProgressiveJackpot: createDaoParam.isProgressiveJackpot
            }),
            createDaoParam.actionType
        );

        vm.stopPrank();
    }

    function _createBasicDao(CreateDaoParam memory createDaoParam) internal returns (bytes32 daoId) {
        startHoax(daoCreator.addr);

        DaoMintCapParam memory daoMintCapParam;
        {
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
        }

        address[] memory minters = new address[](1);
        minters[0] = daoCreator.addr;
        createDaoParam.minterMerkleRoot = getMerkleRoot(minters);
        daoId = daoProxy.createBasicDao{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: drb.currentRound(),
                mintableRounds: 60,
                floorPriceRank: 0,
                maxNftRank: 2,
                royaltyFee: 1250,
                projectUri: bytes(createDaoParam.daoUri).length == 0 ? "test dao uri" : createDaoParam.daoUri,
                projectIndex: 0
            }),
            Whitelist({
                minterMerkleRoot: createDaoParam.minterMerkleRoot,
                minterNFTHolderPasses: createDaoParam.minterNFTHolderPasses,
                canvasCreatorMerkleRoot: createDaoParam.canvasCreatorMerkleRoot,
                canvasCreatorNFTHolderPasses: createDaoParam.canvasCreatorNFTHolderPasses
            }),
            Blacklist({
                minterAccounts: createDaoParam.minterAccounts,
                canvasCreatorAccounts: createDaoParam.canvasCreatorAccounts
            }),
            daoMintCapParam,
            DaoETHAndERC20SplitRatioParam({
                daoCreatorERC20Ratio: 4800,
                canvasCreatorERC20Ratio: 2500,
                nftMinterERC20Ratio: 2500,
                daoFeePoolETHRatio: 9750,
                daoFeePoolETHRatioFlatPrice: 9750
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                isProgressiveJackpot: true
            }),
            BasicDaoParam({
                initTokenSupplyRatio: 500,
                canvasId: createDaoParam.canvasId,
                canvasUri: "test dao creator canvas uri",
                daoName: "test dao"
            }),
            16
        );

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

        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreatorKey, digest);
        tokenId = protocol.mintNFT{ value: flatPrice == 0 ? protocol.getCanvasNextPrice(canvasId) : flatPrice }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        vm.stopPrank();
        deal(hoaxer, bal);
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

    function _mintNftWithProof(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice,
        uint256 canvasCreatorKey,
        address hoaxer,
        bytes32[] memory proof
    )
        internal
        returns (uint256 tokenId)
    {
        uint256 bal = hoaxer.balance;
        startHoax(hoaxer);

        MintNftWithProofLocalVars memory vars =
            MintNftWithProofLocalVars(daoId, canvasId, tokenUri, flatPrice, canvasCreatorKey, hoaxer, proof);

        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreatorKey, digest);
        tokenId = protocol.mintNFT{
            value: vars.flatPrice == 0 ? protocol.getCanvasNextPrice(vars.canvasId) : vars.flatPrice
        }(vars.daoId, vars.canvasId, vars.tokenUri, vars.proof, vars.flatPrice, abi.encodePacked(r, s, v));

        vm.stopPrank();
        deal(hoaxer, bal);
    }

    function _batchMint(
        bytes32 daoId,
        bytes32 canvasId,
        string[] memory tokenUris,
        uint256[] memory flatPrices,
        uint256 canvasCreatorKey,
        address hoaxer
    )
        internal
        returns (uint256[] memory tokenIds)
    {
        startHoax(hoaxer);

        bytes[] memory signatures = new bytes[](tokenUris.length);
        for (uint256 i; i < tokenUris.length; i++) {
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUris[i], flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreatorKey, digest);
            signatures[i] = abi.encodePacked(r, s, v);
        }
        uint256 totalPrice;
        uint256 mintPrice = protocol.getCanvasNextPrice(canvasId);
        uint256 counter;
        uint256 priceFactor = protocol.getDaoPriceFactor(daoId);
        for (uint256 i; i < tokenUris.length; i++) {
            if (flatPrices[i] == 0) {
                if (protocol.getDaoPriceTemplate(daoId) == address(exponentialPriceVariation)) {
                    totalPrice += mintPrice * priceFactor ** counter / BASIS_POINT ** counter;
                } else {
                    totalPrice += mintPrice + priceFactor * counter;
                }
                ++counter;
            } else {
                totalPrice += flatPrices[i];
            }
        }
        MintNftInfo[] memory mintNftINfos = new MintNftInfo[](tokenUris.length);
        for (uint256 i; i < tokenUris.length; i++) {
            mintNftINfos[i] = MintNftInfo({ tokenUri: tokenUris[i], flatPrice: flatPrices[i] });
        }
        tokenIds = protocol.batchMint{ value: totalPrice }(daoId, canvasId, new bytes32[](0), mintNftINfos, signatures);

        vm.stopPrank();
    }

    struct BatchMintWithProofLocalVars {
        bytes32 daoId;
        bytes32 canvasId;
        string[] tokenUris;
        uint256[] flatPrices;
        uint256 canvasCreatorKey;
        address hoaxer;
        bytes32[] proof;
    }

    function _batchMintWithProof(
        bytes32 daoId,
        bytes32 canvasId,
        string[] memory tokenUris,
        uint256[] memory flatPrices,
        uint256 canvasCreatorKey,
        address hoaxer,
        bytes32[] memory proof
    )
        internal
        returns (uint256[] memory tokenIds)
    {
        startHoax(hoaxer);

        BatchMintWithProofLocalVars memory vars =
            BatchMintWithProofLocalVars(daoId, canvasId, tokenUris, flatPrices, canvasCreatorKey, hoaxer, proof);

        bytes[] memory signatures = new bytes[](tokenUris.length);
        for (uint256 i; i < tokenUris.length; i++) {
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUris[i], flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreatorKey, digest);
            signatures[i] = abi.encodePacked(r, s, v);
        }
        uint256 totalPrice;
        uint256 mintPrice = protocol.getCanvasNextPrice(canvasId);
        uint256 counter;
        uint256 priceFactor = protocol.getDaoPriceFactor(daoId);
        for (uint256 i; i < tokenUris.length; i++) {
            if (flatPrices[i] == 0) {
                if (protocol.getDaoPriceTemplate(vars.daoId) == address(exponentialPriceVariation)) {
                    totalPrice += mintPrice * priceFactor ** counter / BASIS_POINT ** counter;
                } else {
                    totalPrice += mintPrice + priceFactor * counter;
                }
                ++counter;
            } else {
                totalPrice += flatPrices[i];
            }
        }
        MintNftInfo[] memory mintNftINfos = new MintNftInfo[](tokenUris.length);
        for (uint256 i; i < tokenUris.length; i++) {
            mintNftINfos[i] = MintNftInfo({ tokenUri: tokenUris[i], flatPrice: flatPrices[i] });
        }
        tokenIds = protocol.batchMint{ value: totalPrice }(vars.daoId, vars.canvasId, proof, mintNftINfos, signatures);

        vm.stopPrank();
    }
}
