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
import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";

import "contracts/interface/D4AEnums.sol";
import {
    getSettingsSelectors,
    getProtocolReadableSelectors,
    getProtocolSetterSelectors,
    getD4ACreateSelectors,
    getPDCreateSelectors,
    getPDBasicDaoSelectors
} from "contracts/utils/CutFacetFunctions.sol";
import "./utils/D4AAddress.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";

import "contracts/interface/D4AStructs.sol";

contract Deploy is Script, Test, D4AAddress {
    using stdJson for string;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address public owner = vm.addr(deployerPrivateKey);

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

    struct CreateContinuousDaoParam {
        bytes32 existDaoId;
        DaoMetadataParam daoMetadataParam;
        Whitelist whitelist;
        Blacklist blacklist;
        DaoETHAndERC20SplitRatioParam daoETHAndERC20SplitRatioParam;
        TemplateParam templateParam;
        BasicDaoParam basicDaoParam;
        ContinuousDaoParam continuousDaoParam;
        uint256 dailyMintCap;
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        //_eventEmiter();

        // _deployDrb();

        // _deployFeePoolFactory();

        // _deployRoyaltySplitterFactory();

        // _deployERC20Factory();

        // _deployERC721WithFilterFactory();

        // _deployProtocolProxy();
        //_deployProtocol();

        // _deployProtocolReadable();
        // _cutProtocolReadableFacet(DeployMethod.REMOVE_AND_ADD);

        // _deployProtocolSetter();
        // _cutFacetsProtocolSetter(DeployMethod.REPLACE);

        // _deployD4ACreate();
        // _cutFacetsD4ACreate();

        _deployPDCreate();
        _cutFacetsPDCreate(DeployMethod.REPLACE);

        // _deployPDBasicDao();
        // _cutFacetsPDBasicDao();

        // _deploySettings();
        // _cutSettingsFacet();

        // _deployClaimer();
        // _deployUniversalClaimer();

        //_deployCreateProjectProxy();
        //_deployCreateProjectProxyProxy();

        //_deployPermissionControl();
        // _deployPermissionControlProxy();

        //_initSettings();

        // _deployLinearPriceVariation();
        // _deployExponentialPriceVariation();
        // _deployLinearRewardIssuance();
        // _deployExponentialRewardIssuance();

        // pdProtocol_proxy.initialize();

        // PDBasicDao(address(pdProtocol_proxy)).setBasicDaoNftFlatPrice(0.01 ether);
        // PDBasicDao(address(pdProtocol_proxy)).setSpecialTokenUriPrefix(
        //     "https://test-protodao.s3.ap-southeast-1.amazonaws.com/meta/work/"

        // _deployUnlocker();
        // );

        vm.stopBroadcast();
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

    function _arrayToString(address[] memory accounts) internal pure returns (string memory) {
        uint256 length = accounts.length;
        string memory res;
        for (uint256 i = 0; i < length; i++) {
            res = string.concat(res, vm.toString(accounts[i]));
            if (i + 1 < length) res = string.concat(res, " ");
        }
        return res;
    }

    function _createContinuousDao(
        CreateDaoParam memory createDaoParam,
        bytes32 existDaoId,
        bool needMintableWork,
        bool unifiedPriceModeOff
    )
        internal
        returns (bytes32 daoId)
    {
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
            daoMintCapParam.userMintCapParams[length].minter = address(this);
            daoMintCapParam.userMintCapParams[length].mintCap = 5;
            daoMintCapParam.daoMintCap = uint32(createDaoParam.mintCap);
        }

        address[] memory minters = new address[](1);
        minters[0] = address(this);
        createDaoParam.minterMerkleRoot = getMerkleRoot(minters);

        CreateContinuousDaoParam memory vars;
        vars.existDaoId = existDaoId;
        vars.daoMetadataParam = DaoMetadataParam({
            startDrb: d4aDrb.currentRound(),
            mintableRounds: 60,
            floorPriceRank: 0,
            maxNftRank: 2,
            royaltyFee: 1250,
            projectUri: bytes(createDaoParam.daoUri).length == 0 ? "test dao uri1" : createDaoParam.daoUri,
            projectIndex: 0
        });
        vars.whitelist = Whitelist({
            minterMerkleRoot: createDaoParam.minterMerkleRoot,
            minterNFTHolderPasses: createDaoParam.minterNFTHolderPasses,
            canvasCreatorMerkleRoot: createDaoParam.canvasCreatorMerkleRoot,
            canvasCreatorNFTHolderPasses: createDaoParam.canvasCreatorNFTHolderPasses
        });
        vars.blacklist = Blacklist({
            minterAccounts: createDaoParam.minterAccounts,
            canvasCreatorAccounts: createDaoParam.canvasCreatorAccounts
        });
        vars.daoETHAndERC20SplitRatioParam = DaoETHAndERC20SplitRatioParam({
            daoCreatorERC20Ratio: 4800,
            canvasCreatorERC20Ratio: 2500,
            nftMinterERC20Ratio: 2500,
            daoFeePoolETHRatio: 9750,
            daoFeePoolETHRatioFlatPrice: 9750
        });
        vars.templateParam = TemplateParam({
            priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
            priceFactor: 20_000,
            rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
            rewardDecayFactor: 0,
            isProgressiveJackpot: true
        });
        vars.basicDaoParam = BasicDaoParam({
            initTokenSupplyRatio: 1000,
            canvasId: createDaoParam.canvasId,
            canvasUri: "test dao creator canvas uri",
            daoName: "test dao"
        });
        vars.continuousDaoParam = ContinuousDaoParam({
            reserveNftNumber: 1000,
            unifiedPriceModeOff: unifiedPriceModeOff,
            unifiedPrice: 0.01 ether,
            needMintableWork: needMintableWork,
            dailyMintCap: 100
        });

        daoId = pdCreateProjectProxy_proxy.createContinuousDao(
            vars.existDaoId,
            vars.daoMetadataParam,
            vars.whitelist,
            vars.blacklist,
            daoMintCapParam,
            vars.daoETHAndERC20SplitRatioParam,
            vars.templateParam,
            vars.basicDaoParam,
            vars.continuousDaoParam,
            20
        );
    }

    function _eventEmiter() internal {
        CreateDaoParam memory createDaoParam;
        bytes32 canvasId = keccak256(abi.encode(address(this), block.timestamp));
        createDaoParam.canvasId = canvasId;
        //bytes32 daoId = _createBasicDao(createDaoParam);
        bytes32 continuousDaoId = _createContinuousDao(
            createDaoParam, 0x6d6e29b989aebea8e1ee5dc00f93150c9baad666f2b199c2fbc083c6047f9853, true, false
        );
        console2.log("subdao:");
        console2.logBytes32(continuousDaoId);
        //bytes32 subdao = 0xeee88695213bbf892778cfc35e64f30a8988ca4580d71ddaf4b4e12fea19ad60;
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

        console2.log("set D4AERC721WithFilterFactory address in D4ASettings");
        D4ASettings(address(pdProtocol_proxy)).changeAddress(
            address(d4aDrb),
            address(d4aERC20Factory),
            address(d4aERC721WithFilterFactory),
            address(d4aFeePoolFactory),
            json.readAddress(".NaiveOwner.proxy"),
            address(pdCreateProjectProxy_proxy),
            address(permissionControl_proxy)
        );
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
                    0x382103Ca4E152a8880D426c56753BAb721deB080
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
                    0x0ad5552b1ee49f8B15dAA1e8A14CaA97c6BD4862
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

    function _deployD4ACreate() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy D4ACreate");

        d4aCreate = new D4ACreate();
        assertTrue(address(d4aCreate) != address(0));

        vm.toString(address(d4aCreate)).write(path, ".PDProtocol.D4ACreate");

        console2.log("D4ACreate address: ", address(d4aCreate));
        console2.log("================================================================================\n");
    }

    function _cutFacetsD4ACreate(DeployMethod deployMethod) internal {
        console2.log("\n================================================================================");
        console2.log("Start cut D4ACreate facet");

        //------------------------------------------------------------------------------------------------------
        // D4AProtoclReadable facet cut
        bytes4[] memory selectors = getD4ACreateSelectors();
        console2.log("D4ACreate facet cut selectors number: ", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        if (deployMethod == DeployMethod.REMOVE || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(d4aCreate),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(d4aCreate),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.REPLACE) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(d4aCreate),
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

        pdCreate = new PDCreate();
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
                    0x6027C2Ac203f12cf03e5FdeC098740FC393729BE
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
                target: address(d4aSettings),
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
        }
        if (deployMethod == DeployMethod.ADD || deployMethod == DeployMethod.REMOVE_AND_ADD) {
            facetCuts[0] = IDiamondWritableInternal.FacetCut({
                target: address(d4aSettings),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: selectors
            });
            D4ADiamond(payable(address(pdProtocol_proxy))).diamondCut(facetCuts, address(0), "");
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

    function _deployLinearRewardIssuance() internal {
        console2.log("\n================================================================================");
        console2.log("Start deploy LinearRewardIssuance");

        linearRewardIssuance = new LinearRewardIssuance();
        assertTrue(address(linearRewardIssuance) != address(0));

        vm.toString(address(linearRewardIssuance)).write(path, ".PDProtocol.LinearRewardIssuance");

        D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
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

        vm.toString(address(exponentialRewardIssuance)).write(path, ".PDProtocol.ExponentialRewardIssuance");

        D4ASettings(address(pdProtocol_proxy)).setTemplateAddress(
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

        // 下面这段在部署失败重新部署时需要被注释掉
        pdCreateProjectProxy_impl = new PDCreateProjectProxy(address(WETH));
        assertTrue(address(pdCreateProjectProxy_impl) != address(0));
        //pdCreateProjectProxy_impl = PDCreateProjectProxy(payable(0x23951139124dd1803BE081e781Ba563C554D0542));

        proxyAdmin.upgrade(
            ITransparentUpgradeableProxy(address(pdCreateProjectProxy_proxy)), address(pdCreateProjectProxy_impl)
        );

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
        {
            console2.log("Step 8: grant INITIALIZER ROLE");
            NaiveOwner naiveOwner_proxy = NaiveOwner(json.readAddress(".NaiveOwner.proxy"));
            naiveOwner_proxy.grantRole(naiveOwner_proxy.INITIALIZER_ROLE(), address(pdProtocol_proxy));
        }
        {
            console2.log("Step 9: grant role");
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("PROTOCOL_ROLE"), owner);
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("OPERATION_ROLE"), owner);
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("DAO_ROLE"), owner);
            IAccessControl(address(pdProtocol_proxy)).grantRole(keccak256("SIGNER_ROLE"), owner);
        }
        {
            console2.log("Step 10: change create DOA and Canvas Fee to 0");
            D4ASettings(address(pdProtocol_proxy)).changeCreateFee(0 ether, 0 ether);
        }
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
}
