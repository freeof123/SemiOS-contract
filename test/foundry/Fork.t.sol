// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {D4ADrb} from "contracts/D4ADrb.sol";
import {D4AFeePool, D4AFeePoolFactory} from "contracts/feepool/D4AFeePool.sol";
import {D4ARoyaltySplitter} from "contracts/royalty-splitter/D4ARoyaltySplitter.sol";
import {D4ARoyaltySplitterFactory} from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
import {D4AERC20, D4AERC20Factory} from "contracts/D4AERC20.sol";
import {D4AERC721WithFilter, D4AERC721WithFilterFactory} from "contracts/D4AERC721WithFilter.sol";
import {D4AProject} from "contracts/impl/D4AProject.sol";
import {D4ACanvas} from "contracts/impl/D4ACanvas.sol";
import {D4APrice} from "contracts/impl/D4APrice.sol";
import {D4AReward} from "contracts/impl/D4AReward.sol";
import {D4ASettings} from "contracts/D4ASettings/D4ASettings.sol";
import {NaiveOwner} from "contracts/NaiveOwner.sol";
import {D4AProtocolWithPermission} from "contracts/D4AProtocolWithPermission.sol";
import {PermissionControl} from "contracts/permission-control/PermissionControl.sol";
import {D4ACreateProjectProxy} from "contracts/proxy/D4ACreateProjectProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IPermissionControl} from "contracts/interface/IPermissionControl.sol";

contract Fork is Test {
    uint256 mainnetFork;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    D4ADrb prb = D4ADrb(vm.envAddress("D4APRB"));
    D4AFeePoolFactory public d4aFeePoolFactory = D4AFeePoolFactory(vm.envAddress("D4AFeePoolFactory"));
    D4ARoyaltySplitterFactory public d4aRoyaltySplitterFactory =
        D4ARoyaltySplitterFactory(vm.envAddress("D4ARoyaltySplitterFactory"));
    D4AERC20Factory public d4aERC20Factory = D4AERC20Factory(vm.envAddress("D4AERC20Factory"));
    D4AERC721WithFilterFactory public d4aERC721WithFilterFactory =
        D4AERC721WithFilterFactory(vm.envAddress("D4AERC721WithFilterFactory"));
    D4ASettings public d4aSettings = D4ASettings(vm.envAddress("D4ASetting"));
    ProxyAdmin public proxyAdmin = ProxyAdmin(vm.envAddress("ProxyAdmin"));
    TransparentUpgradeableProxy public d4aProtocolWithPermission_proxy =
        TransparentUpgradeableProxy(payable(vm.envAddress("D4AProtocolWithPermission_proxy")));
    D4AProtocolWithPermission public d4aProtocolWithPermission_impl =
        D4AProtocolWithPermission(vm.envAddress("D4AProtocolWithPermission_impl"));
    TransparentUpgradeableProxy public permissionControl_proxy =
        TransparentUpgradeableProxy(payable(vm.envAddress("PermissionControl_proxy")));
    PermissionControl public permissionControl_impl = PermissionControl(vm.envAddress("PermissionControl_impl"));
    TransparentUpgradeableProxy public d4aCreateProjectProxy_proxy =
        TransparentUpgradeableProxy(payable(vm.envAddress("D4ACreateProjectProxy_proxy")));
    D4ACreateProjectProxy public d4aCreateProjectProxy_impl =
        D4ACreateProjectProxy(payable(vm.envAddress("D4ACreateProjectProxy_impl")));
    address public deployer = vm.addr(deployerPrivateKey);
    address public highRankOwner = 0x064D35db3f037149ed2c35c118a3bd79Fa4fE323;
    address public lowRankOwner = 0x365088B0Fb00CAbaD7DacEB88211494E5D35F081;
    address public signatureSigner = 0xB5A5a0dEec823323B25533cE8129c6c0eEfa8B3c;

    function setUp() public {
        mainnetFork = vm.createFork("https://mainnet.infura.io/v3/a221e1d3d6984f6c8b7e12e5ce671c76");
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
    }

    // function test_Fork() public {
    //     startHoax(deployer);

    //     D4ACreateProjectProxy d4aCreateProjectProxy =
    //         D4ACreateProjectProxy(payable(address(d4aCreateProjectProxy_proxy)));
    //     D4AProtocolWithPermission d4aProtocolWithPermission =
    //         D4AProtocolWithPermission(address(d4aProtocolWithPermission_proxy));
    //     PermissionControl permissionControl = PermissionControl(address(permissionControl_proxy));

    //     uint256 startPrb = prb.currentRound();

    //     // create project, create canvas and mint NFT
    //     (bytes32 daoId,) =
    //         d4aCreateProjectProxy.createProject{value: 0.1 ether}(startPrb, 30, 0, 0, 750, "test createDao");
    //     bytes32 canvasId = d4aProtocolWithPermission.createCanvas(daoId, "test canvas uri", new bytes32[](0));
    //     // uint256 tokenId =
    //     //     d4aProtocolWithPermission.mintNFT(daoId, canvasId, "test nft uri", new bytes32[](0), 0, new bytes(65));

    //     // create project with permission
    //     IPermissionControl.Whitelist memory whitelist;
    //     {
    //         whitelist.minterMerkleRoot = keccak256(abi.encodePacked("test"));
    //         whitelist.canvasCreatorMerkleRoot = keccak256(abi.encodePacked("test"));
    //         whitelist.minterNFTHolderPasses[0] = vm.addr(0x1);
    //         whitelist.canvasCreatorNFTHolderPasses[0] = vm.addr(0x2);
    //     }

    //     IPermissionControl.Blacklist memory blacklist;
    //     {
    //         blacklist.minterAccounts = new address[](2);
    //         blacklist.minterAccounts[0] = vm.addr(0x3);
    //         blacklist.minterAccounts[1] = vm.addr(0x4);
    //         blacklist.canvasCreatorAccounts = new address[](2);
    //         blacklist.canvasCreatorAccounts[0] = vm.addr(0x5);
    //         blacklist.canvasCreatorAccounts[1] = vm.addr(0x6);
    //     }
    //     (bytes32 daoId1,) = d4aCreateProjectProxy.createProjectWithPermission{value: 0.1 ether}(
    //         startPrb + 1, 30, 0, 0, 750, "test createDaoWithPermission", whitelist, blacklist
    //     );
    //     assertEq(permissionControl.isCanvasCreatorBlacklisted(daoId1, vm.addr(0x5)), true);
    //     assertEq(permissionControl.isCanvasCreatorBlacklisted(daoId1, vm.addr(0x6)), true);
    //     assertEq(permissionControl.isCanvasCreatorBlacklisted(daoId1, vm.addr(0x7)), false);
    //     assertEq(permissionControl.isMinterBlacklisted(daoId1, vm.addr(0x3)), true);
    //     assertEq(permissionControl.isMinterBlacklisted(daoId1, vm.addr(0x4)), true);
    //     assertEq(permissionControl.isMinterBlacklisted(daoId1, vm.addr(0x7)), false);
    //     // protocol.createCanvas(daoId, "test canvas", new bytes32[](0));
    // }
}
