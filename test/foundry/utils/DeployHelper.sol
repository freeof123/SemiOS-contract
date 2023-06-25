// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// structs
import {
    DaoMetadataParam,
    DaoMintCapParam,
    UserMintCapParam,
    DaoETHAndERC20SplitRatioParam,
    TemplateParam
} from "contracts/interface/D4AStructs.sol";

// dependencies
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IAccessControl } from "@solidstate/contracts/access/access_control/IAccessControl.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 as IUniswapV2Router } from
    "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// interfaces
import { ID4ASettings } from "contracts/D4ASettings/ID4ASettings.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4AERC721 } from "contracts/interface/ID4AERC721.sol";
import { ID4AProtocol } from "contracts/interface/ID4AProtocol.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
import { IProtoDAOSettingsReadable, IProtoDAOSettingsWritable } from "contracts/ProtoDAOSettings/IProtoDAOSettings.sol";

// contracts
import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { D4AFeePoolFactory } from "contracts/feepool/D4AFeePool.sol";
import { D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { D4ACreateProjectProxy } from "contracts/proxy/D4ACreateProjectProxy.sol";
import { TestD4AProtocolWithPermission } from "contracts/test/TestD4AProtocolWithPermission.sol";
import { DummyPRB } from "contracts/test/DummyPRB.sol";
import { TestERC20 } from "contracts/test/TestERC20.sol";
import { TestERC721 } from "contracts/test/TestERC721.sol";
import { D4AClaimer } from "contracts/D4AClaimer.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import { D4AERC20Factory } from "contracts/D4AERC20.sol";
import { D4AERC721Factory } from "contracts/D4AERC721.sol";
import { NaiveOwner } from "contracts/NaiveOwner.sol";
import { ProtoDAOSettings } from "contracts/ProtoDAOSettings/ProtoDAOSettings.sol";
import { FeedRegistryMock } from "./mocks/FeedRegistryMock.sol";
import { AggregatorV3Mock } from "./mocks/AggregatorV3Mock.sol";
import { Denominations } from "@chainlink/contracts/src/v0.8/Denominations.sol";
import { LinearPriceVariation } from "contracts/templates/LinearPriceVariation.sol";
import { ExponentialPriceVariation } from "contracts/templates/ExponentialPriceVariation.sol";

contract DeployHelper is Test {
    ProxyAdmin public proxyAdmin = new ProxyAdmin();
    DummyPRB public drb;
    D4ASettings public settings;
    NaiveOwner public naiveOwner;
    NaiveOwner public naiveOwnerImpl;
    TestD4AProtocolWithPermission public protocol;
    D4ADiamond public diamond;
    TestD4AProtocolWithPermission public protocolImpl;
    D4ACreateProjectProxy public daoProxy;
    D4ACreateProjectProxy public daoProxyImpl;
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
    ProtoDAOSettings public protoDAOSettings;
    LinearPriceVariation public linearPriceVariation;
    ExponentialPriceVariation public exponentialPriceVariation;

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

    function setUpEnv() public {
        vm.startPrank(protocolOwner.addr);

        _deployeWETH();
        _deployFeedRegistry();
        _deployUniswapV2Factory(protocolOwner.addr);
        _deployUniswapV2Router(address(uniswapV2Factory), address(weth));
        _deployDrb();
        _deploySettings();
        _deployNaiveOwner();
        _deployERC20Factory();
        _deployERC721Factory();
        _deployFeePoolFactory();
        _deployRoyaltySplitterFactory();
        _deployProtocol();
        _deployDaoProxy();
        _deployPermissionControl();
        _deployClaimer();
        _deployTestERC20();
        _deployAggregator();
        _deployTestERC721();
        _deployPriceTemplate();
        _deployRewardTemplate();

        _grantRole();

        changePrank(protocolRoleMember.addr);

        _initSettings();

        changePrank(protocolOwner.addr);
        naiveOwner.grantRole(naiveOwner.INITIALIZER_ROLE(), address(protocol));

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

    function _deployeWETH() internal {
        weth = deployCode("contracts/build/WETH9.json");
        vm.label(address(weth), "WETH");
    }

    function _deployDrb() internal {
        drb = new DummyPRB();
        vm.label(address(drb), "DRB");
    }

    function _deploySettings() internal {
        settings = new D4ASettings();
        vm.label(address(settings), "Settings");
    }

    function _deployNaiveOwner() internal {
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
    }

    function _deployERC20Factory() internal {
        erc20Factory = new D4AERC20Factory();
        vm.label(address(erc20Factory), "ERC20 Factory");
    }

    function _deployERC721Factory() internal {
        erc721Factory = new D4AERC721Factory();
        vm.label(address(erc721Factory), "ERC721 Factory");
    }

    function _deployFeePoolFactory() internal {
        feePoolFactory = new D4AFeePoolFactory();
        vm.label(address(feePoolFactory), "Fee Pool Factory");
    }

    function _deployUniswapV2Factory(address feeToSetter) internal {
        uniswapV2Factory =
            IUniswapV2Factory(deployCode("contracts/build/UniswapV2Factory.json", abi.encode(feeToSetter)));
        vm.label(address(uniswapV2Factory), "Uniswap V2 Factory");

        assertEq(uniswapV2Factory.feeToSetter(), feeToSetter);
    }

    function _deployUniswapV2Router(address factory, address WETH) internal {
        uniswapV2Router =
            IUniswapV2Router(deployCode("contracts/build/UniswapV2Router02.json", abi.encode(uniswapV2Factory, WETH)));
        vm.label(address(uniswapV2Router), "Uniswap V2 Router");

        assertEq(uniswapV2Router.factory(), factory);
        assertEq(uniswapV2Router.WETH(), WETH);
    }

    function _deployRoyaltySplitterFactory() internal {
        royaltySplitterFactory =
            new D4ARoyaltySplitterFactory(address(weth), address(uniswapV2Router), address(feedRegistry));
        vm.label(address(royaltySplitterFactory), "Royalty Splitter Factory");
    }

    function _deployProtocol() internal {
        diamond = new D4ADiamond();
        protocolImpl = new TestD4AProtocolWithPermission();
        protocol = TestD4AProtocolWithPermission(
            address(
                new TransparentUpgradeableProxy(
                    address(diamond),
                    address(proxyAdmin),
                    abi.encodeWithSignature("initialize(address)", protocolOwner.addr)
                )
            )
        );
        _cutFacetsSettings();
        _cutFacetsProtoDAOSettings();

        vm.label(address(protocol), "Protocol");
        vm.label(address(diamond), "Diamond");
        vm.label(address(protocolImpl), "Protocol Impl");
    }

    function _cutFacetsSettings() internal {
        //------------------------------------------------------------------------------------------------------
        // settings facet cut
        bytes4[] memory selectors = new bytes4[](30);
        uint256 selectorIndex;
        // register AccessControl
        selectors[selectorIndex++] = IAccessControl.getRoleAdmin.selector;
        selectors[selectorIndex++] = IAccessControl.grantRole.selector;
        selectors[selectorIndex++] = IAccessControl.hasRole.selector;
        selectors[selectorIndex++] = IAccessControl.renounceRole.selector;
        selectors[selectorIndex++] = IAccessControl.revokeRole.selector;
        // register D4ASettingsReadable
        selectors[selectorIndex++] = ID4ASettingsReadable.permissionControl.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.ownerProxy.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.mintProtocolFeeRatio.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.protocolFeePool.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.tradeProtocolFeeRatio.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.mintProjectFeeRatio.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.mintProjectFeeRatioFlatPrice.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.ratioBase.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.createProjectFee.selector;
        selectors[selectorIndex++] = ID4ASettingsReadable.createCanvasFee.selector;
        // register D4ASettings
        selectors[selectorIndex++] = ID4ASettings.changeAddress.selector;
        selectors[selectorIndex++] = ID4ASettings.changeAssetPoolOwner.selector;
        selectors[selectorIndex++] = ID4ASettings.changeCreateFee.selector;
        selectors[selectorIndex++] = ID4ASettings.changeD4APause.selector;
        selectors[selectorIndex++] = ID4ASettings.changeERC20Ratio.selector;
        selectors[selectorIndex++] = ID4ASettings.changeERC20TotalSupply.selector;
        selectors[selectorIndex++] = ID4ASettings.changeFloorPrices.selector;
        selectors[selectorIndex++] = ID4ASettings.changeMaxMintableRounds.selector;
        selectors[selectorIndex++] = ID4ASettings.changeMaxNFTAmounts.selector;
        selectors[selectorIndex++] = ID4ASettings.changeMintFeeRatio.selector;
        selectors[selectorIndex++] = ID4ASettings.changeProtocolFeePool.selector;
        selectors[selectorIndex++] = ID4ASettings.changeTradeFeeRatio.selector;
        selectors[selectorIndex++] = ID4ASettings.setCanvasPause.selector;
        selectors[selectorIndex++] = ID4ASettings.setProjectPause.selector;
        selectors[selectorIndex++] = ID4ASettings.transferMembership.selector;

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(settings),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(
            facetCuts, address(settings), abi.encodeWithSelector(ID4ASettings.initializeD4ASettings.selector)
        );

        // set diamond fallback address
        D4ADiamond(payable(address(protocol))).setFallbackAddressAndCall(
            address(protocolImpl), address(protocolImpl), abi.encodeWithSignature("initialize()")
        );
    }

    function _cutFacetsProtoDAOSettings() internal {
        protoDAOSettings = new ProtoDAOSettings();

        // ProtoDAO Settings facet cut
        bytes4[] memory selectors = new bytes4[](5);
        uint256 selectorIndex;
        // register ProtoDAOSettingsReadable
        selectors[selectorIndex++] = IProtoDAOSettingsReadable.getCanvasCreatorERC20Ratio.selector;
        selectors[selectorIndex++] = IProtoDAOSettingsReadable.getNftMinterERC20Ratio.selector;
        selectors[selectorIndex++] = IProtoDAOSettingsReadable.getDaoFeePoolETHRatio.selector;
        selectors[selectorIndex++] = IProtoDAOSettingsReadable.getDaoFeePoolETHRatioFlatPrice.selector;
        // register ProtoDAOSettingsWritable
        selectors[selectorIndex++] = IProtoDAOSettingsWritable.setRatio.selector;

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(protoDAOSettings),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(facetCuts, address(0), "");
    }

    function _deployDaoProxy() internal {
        daoProxyImpl = new D4ACreateProjectProxy(address(weth));
        daoProxy = D4ACreateProjectProxy(
            payable(
                new TransparentUpgradeableProxy(
                    address(daoProxyImpl),
                    address(proxyAdmin),
                    abi.encodeWithSelector(
                        D4ACreateProjectProxy.initialize.selector,
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

    function _deployPermissionControl() internal {
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

    function _deployClaimer() internal {
        claimer = new D4AClaimer(address(protocol));
        vm.label(address(claimer), "Claimer");
    }

    function _deployTestERC20() internal {
        _testERC20 = new TestERC20();
        vm.label(address(_testERC20), "ERC20 Test");
    }

    function _deployTestERC721() internal {
        _testERC721 = new TestERC721();
        vm.label(address(_testERC721), "ERC721 Test");
    }

    function _deployFeedRegistry() internal {
        feedRegistry = new FeedRegistryMock(protocolOwner.addr);
        vm.label(address(feedRegistry), "Feed Registry");
    }

    function _deployAggregator() internal {
        feedRegistry.setAggregator(
            address(_testERC20), Denominations.ETH, address(new AggregatorV3Mock(1e18 / 2_000, 18))
        );
    }

    function _initSettings() internal {
        _changeAddress();
        _changeProtocolFeePool();
        _changeERC20TotalSupply();
        _changeAssetPoolOwner();
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

    function _changeFloorPrices() internal {
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

    function _grantRole() internal {
        IAccessControl(address(protocol)).grantRole(keccak256("PROTOCOL_ROLE"), protocolRoleMember.addr);
        IAccessControl(address(protocol)).grantRole(keccak256("OPERATION_ROLE"), operationRoleMember.addr);

        changePrank(operationRoleMember.addr);
        IAccessControl(address(protocol)).grantRole(keccak256("DAO_ROLE"), daoRoleMember.addr);
        IAccessControl(address(protocol)).grantRole(keccak256("SIGNER_ROLE"), signerRoleMember.addr);

        changePrank(protocolRoleMember.addr);
    }

    function _generateTrivialWhitelist() internal returns (PermissionControl.Whitelist memory) {
        PermissionControl.Whitelist memory whitelist;
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

    function _generateTrivialBlacklist() internal pure returns (PermissionControl.Blacklist memory) {
        PermissionControl.Blacklist memory blacklist;
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
        returns (
            bytes32 daoId,
            PermissionControl.Whitelist memory whitelist,
            PermissionControl.Blacklist memory blacklist
        )
    {
        daoId = keccak256("test");
        whitelist = _generateTrivialWhitelist();
        blacklist = _generateTrivialBlacklist();
    }

    struct CreateDaoParam {
        DaoMetadataParam daoMetadataParam;
        bytes32 minterMerkleRoot;
        address[] minterNFTHolderPasses;
        bytes32 canvasCreatorMerkleRoot;
        address[] canvasCreatorNFTHolderPasses;
        address[] minterAccounts;
        address[] canvasCreatorAccounts;
        uint256 mintCap;
        address[] minters;
        uint256[] userMintCaps;
        uint256 canvasCreatorERC20Ratio;
        uint256 nftMinterERC20Ratio;
        uint256 daoFeePoolETHRatio;
        uint256 daoFeePoolETHRatioFlatPrice;
        address priceTemplate;
        uint256 priceFactor;
        address rewardTemplate;
        uint256 rewardDecayFactor;
        uint256 actionType;
    }

    function _createDao(CreateDaoParam memory createDaoParam) internal returns (bytes32 daoId) {
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
            createDaoParam.daoMetadataParam,
            IPermissionControl.Whitelist({
                minterMerkleRoot: createDaoParam.minterMerkleRoot,
                minterNFTHolderPasses: createDaoParam.minterNFTHolderPasses,
                canvasCreatorMerkleRoot: createDaoParam.canvasCreatorMerkleRoot,
                canvasCreatorNFTHolderPasses: createDaoParam.canvasCreatorNFTHolderPasses
            }),
            IPermissionControl.Blacklist({
                minterAccounts: createDaoParam.minterAccounts,
                canvasCreatorAccounts: createDaoParam.canvasCreatorAccounts
            }),
            daoMintCapParam,
            DaoETHAndERC20SplitRatioParam({
                canvasCreatorERC20Ratio: createDaoParam.canvasCreatorERC20Ratio,
                nftMinterERC20Ratio: createDaoParam.nftMinterERC20Ratio,
                daoFeePoolETHRatio: createDaoParam.daoFeePoolETHRatio,
                daoFeePoolETHRatioFlatPrice: createDaoParam.daoFeePoolETHRatioFlatPrice
            }),
            TemplateParam({
                priceTemplate: createDaoParam.priceTemplate,
                priceFactor: createDaoParam.priceFactor,
                rewardTemplate: createDaoParam.rewardTemplate,
                rewardDecayFactor: createDaoParam.rewardDecayFactor
            }),
            createDaoParam.actionType
        );
    }

    function _createTrivialDao(
        uint256 startDrb,
        uint256 mintableRounds,
        uint256 floorPriceRank,
        uint256 maxNftRank,
        uint96 royaltyFee,
        string memory projectUri
    )
        internal
        returns (bytes32 daoId)
    {
        CreateDaoParam memory createDaoParam;
        createDaoParam.daoMetadataParam = DaoMetadataParam({
            startDrb: startDrb,
            mintableRounds: mintableRounds,
            floorPriceRank: floorPriceRank,
            maxNftRank: maxNftRank,
            royaltyFee: royaltyFee,
            projectUri: projectUri,
            projectIndex: 0
        });
        daoId = _createDao(createDaoParam);
    }

    function _createDaoWithPermission(
        uint256 startDrb,
        uint256 mintableRounds,
        uint256 floorPriceRank,
        uint256 maxNftRank,
        uint96 royaltyFee,
        string memory projectUri,
        bytes32 minterMerkleRoot,
        address[] memory minterNFTHolderPasses,
        bytes32 canvasCreatorMerkleRoot,
        address[] memory canvasCreatorNFTHolderPasses,
        address[] memory minterAccounts,
        address[] memory canvasCreatorAccounts
    )
        internal
        returns (bytes32 daoId)
    {
        CreateDaoParam memory createDaoParam;
        createDaoParam.daoMetadataParam = DaoMetadataParam({
            startDrb: startDrb,
            mintableRounds: mintableRounds,
            floorPriceRank: floorPriceRank,
            maxNftRank: maxNftRank,
            royaltyFee: royaltyFee,
            projectUri: projectUri,
            projectIndex: 0
        });
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.minterNFTHolderPasses = minterNFTHolderPasses;
        createDaoParam.canvasCreatorMerkleRoot = canvasCreatorMerkleRoot;
        createDaoParam.canvasCreatorNFTHolderPasses = canvasCreatorNFTHolderPasses;
        createDaoParam.minterAccounts = minterAccounts;
        createDaoParam.canvasCreatorAccounts = canvasCreatorAccounts;
        createDaoParam.actionType = 2;
        daoId = _createDao(createDaoParam);
    }

    function _deployPriceTemplate() internal {
        linearPriceVariation = new LinearPriceVariation();
        vm.label(address(linearPriceVariation), "Linear Price Variation");

        exponentialPriceVariation = new ExponentialPriceVariation();
        vm.label(address(exponentialPriceVariation), "Exponential Price Variation");
    }

    function _deployRewardTemplate() internal { }
}
