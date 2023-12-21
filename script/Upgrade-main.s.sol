// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IAccessControl } from "@solidstate/contracts/access/access_control/IAccessControl.sol";

import { getSettingsSelectors } from "contracts/utils/CutFacetFunctions.sol";
import { D4AProtocol } from "contracts/D4AProtocol.sol";
import { PDCreateProjectProxy } from "contracts/proxy/PDCreateProjectProxy.sol";
import { IPermissionControl, PermissionControl } from "contracts/permission-control/PermissionControl.sol";
import { D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import { ID4ASettings, D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { D4ADrb } from "contracts/D4ADrb.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

contract UpgradeTest is Test, Script {
    using stdJson for string;

    string public json = vm.readFile(string.concat(vm.projectRoot(), "/deployed-contracts-info/main-d4a.json"));

    uint256 forkId;

    address public deployer = 0x8476a427226394722eC8f81B928546eD74c0553f;
    address public admin = 0x064D35db3f037149ed2c35c118a3bd79Fa4fE323;
    address public lowRankAdmin = 0x365088B0Fb00CAbaD7DacEB88211494E5D35F081;
    address public signer = 0xB5A5a0dEec823323B25533cE8129c6c0eEfa8B3c;

    address public weth = json.readAddress(".WETH");
    D4AProtocol public protocol = D4AProtocol(json.readAddress(".D4AProtocol"));

    D4AProtocol public protocolImpl = D4AProtocol(json.readAddress(".D4AProtocol"));
    PDCreateProjectProxy public createProjectProxy =
        PDCreateProjectProxy(payable(json.readAddress(".D4ACreateProjectProxy_proxy")));
    PDCreateProjectProxy public createProjectProxyImpl =
        PDCreateProjectProxy(payable(json.readAddress(".D4ACreateProjectProxy_impl")));
    PermissionControl public permissionControl = PermissionControl(json.readAddress(".PermissionControl_proxy"));
    PermissionControl public permissionControlImpl = PermissionControl(json.readAddress(".PermissionControl_impl"));
    D4ARoyaltySplitterFactory public royaltySplitterFactory =
        D4ARoyaltySplitterFactory(json.readAddress(".D4ARoyaltySplitterFactory"));
    D4ADiamond public diamond = D4ADiamond(payable(0x2d14c3fBDc22AeDa7d074bd0B6Eab824bfBbFC97));
    D4ASettings public settings = D4ASettings(json.readAddress(".D4ASettings"));

    address public d4aswapFactory = 0x40082EEdca51A13E2910bBaDc1A0F87ce5730668;
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    ProxyAdmin public proxyAdmin = ProxyAdmin(json.readAddress(".ProxyAdmin"));
    D4ADrb public drb = D4ADrb(json.readAddress(".D4ADrb"));

    function run() public {
        address cachedDeployer = deployer;
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        assertEq(deployer, cachedDeployer);

        vm.startBroadcast(deployer);

        // _deploy();
        // _cutSettingsFacets();

        _grantRole();
        _initSettings();
        _renounceRole();

        vm.stopBroadcast();
    }

    function _deploy() internal {
        drb = new D4ADrb(16437115, 7158 * 1e18);
        assertEq(drb.currentRound(), D4ADrb(0xcD261f16720e9dcc42fEe0690bC7A5450b9686ba).currentRound());
        (uint256 startDrb, uint256 startBlock, uint256 periodBlockE18) = drb.checkpoints(0);
        (bool succ, bytes memory returnData) =
            0xcD261f16720e9dcc42fEe0690bC7A5450b9686ba.call(abi.encodeWithSignature("start_block()"));
        require(succ);
        uint256 oldStartBlock = abi.decode(returnData, (uint256));
        (succ, returnData) = 0xcD261f16720e9dcc42fEe0690bC7A5450b9686ba.call(abi.encodeWithSignature("period_block()"));
        require(succ);
        uint256 periodBlock = abi.decode(returnData, (uint256));
        assertEq(startDrb, 0);
        assertEq(startBlock, oldStartBlock);
        assertEq(periodBlockE18 / 1e18, periodBlock);

        protocolImpl = new D4AProtocol();
        createProjectProxyImpl = new PDCreateProjectProxy(weth);
        permissionControlImpl = new PermissionControl(address(protocol), address(createProjectProxy));
        royaltySplitterFactory =
            new D4ARoyaltySplitterFactory(weth, uniswapV2Router, json.readAddress(".OracleRegistry"));
        diamond = new D4ADiamond();
        settings = new D4ASettings();
    }

    function _cutSettingsFacets() internal {
        //------------------------------------------------------------------------------------------------------
        // settings facet cut
        bytes4[] memory selectors = getSettingsSelectors();
        console2.log("settings selectors length: %d", selectors.length);

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(settings),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });
        D4ADiamond(payable(address(protocol))).diamondCut(
            facetCuts, address(settings), abi.encodeWithSelector(D4ASettings.initializeD4ASettings.selector)
        );

        // set diamond fallback address
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolImpl));

        D4ADiamond(payable(address(protocol))).transferOwnership(admin);

        assertEq(D4ADiamond(payable(address(protocol))).owner(), deployer, "owner");
        assertEq(D4ADiamond(payable(address(protocol))).nomineeOwner(), admin, "nominee owner");
    }

    function _grantRole() internal {
        IAccessControl(address(protocol)).grantRole(bytes32(0), admin);

        IAccessControl(address(protocol)).grantRole(keccak256("PROTOCOL_ROLE"), deployer);
        IAccessControl(address(protocol)).grantRole(keccak256("PROTOCOL_ROLE"), admin);
        IAccessControl(address(protocol)).grantRole(keccak256("OPERATION_ROLE"), lowRankAdmin);

        IAccessControl(address(protocol)).grantRole(keccak256("OPERATION_ROLE"), deployer);
        IAccessControl(address(protocol)).grantRole(keccak256("SIGNER_ROLE"), signer);
    }

    function _renounceRole() internal {
        IAccessControl(address(protocol)).renounceRole(keccak256("OPERATION_ROLE"));
        IAccessControl(address(protocol)).renounceRole(keccak256("PROTOCOL_ROLE"));
        IAccessControl(address(protocol)).renounceRole(bytes32(0));
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
            json.readAddress(".D4AERC20Factory"),
            json.readAddress(".D4AERC721WithFilterFactory"),
            json.readAddress(".D4AFeePoolFactory"),
            json.readAddress(".NaiveOwner_proxy"),
            address(createProjectProxy),
            address(permissionControl)
        );
    }

    function _changeProtocolFeePool() internal {
        ID4ASettings(address(protocol)).changeProtocolFeePool(admin);
    }

    function _changeERC20TotalSupply() internal {
        ID4ASettings(address(protocol)).changeERC20TotalSupply(1_000_000_000 ether);
    }

    function _changeAssetPoolOwner() internal {
        ID4ASettings(address(protocol)).changeAssetPoolOwner(lowRankAdmin);
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
}
