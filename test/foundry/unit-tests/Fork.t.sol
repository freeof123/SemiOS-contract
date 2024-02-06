// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { NftIdentifier } from "contracts/interface/D4AStructs.sol";
// import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
// import { TransparentUpgradeableProxy } from
// "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
// import { D4ADrb } from "contracts/D4ADrb.sol";
// import { D4AFeePool, D4AFeePoolFactory } from "contracts/feepool/D4AFeePool.sol";
// import { D4ARoyaltySplitter } from "contracts/royalty-splitter/D4ARoyaltySplitter.sol";
// import { D4ARoyaltySplitterFactory } from "contracts/royalty-splitter/D4ARoyaltySplitterFactory.sol";
// import { D4AERC20, D4AERC20Factory } from "contracts/D4AERC20.sol";
// import { D4AERC721WithFilter } from "contracts/D4AERC721WithFilter.sol";
// import { D4AERC721WithFilterFactory } from "contracts/D4AERC721WithFilterFactory.sol";
// import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
// import { NaiveOwner } from "contracts/NaiveOwner.sol";
// import { PermissionControl } from "contracts/permission-control/PermissionControl.sol";

contract Fork is Test {
    uint256 mainnetFork;

    // uint256 deployerPrivateKey = 0x0a871dfe3c714f1b605b6c0b56746298ea7f3ca8b41938ca69b3ba0126d00aac8;

    // D4ADrb prb = D4ADrb(vm.envAddress("D4APRB"));
    // D4AFeePoolFactory public d4aFeePoolFactory = D4AFeePoolFactory(vm.envAddress("D4AFeePoolFactory"));
    // D4ARoyaltySplitterFactory public d4aRoyaltySplitterFactory =
    //     D4ARoyaltySplitterFactory(vm.envAddress("D4ARoyaltySplitterFactory"));
    // D4AERC20Factory public d4aERC20Factory = D4AERC20Factory(vm.envAddress("D4AERC20Factory"));
    // D4AERC721WithFilterFactory public d4aERC721WithFilterFactory =
    //     D4AERC721WithFilterFactory(vm.envAddress("D4AERC721WithFilterFactory"));
    // D4ASettings public d4aSettings = D4ASettings(vm.envAddress("D4ASetting"));
    // ProxyAdmin public proxyAdmin = ProxyAdmin(vm.envAddress("ProxyAdmin"));
    // TransparentUpgradeableProxy public d4aProtocol_proxy =
    //     TransparentUpgradeableProxy(payable(vm.envAddress("D4AProtocol_proxy")));
    // TransparentUpgradeableProxy public permissionControl_proxy =
    //     TransparentUpgradeableProxy(payable(vm.envAddress("PermissionControl_proxy")));
    // PermissionControl public permissionControl_impl = PermissionControl(vm.envAddress("PermissionControl_impl"));
    // TransparentUpgradeableProxy public d4aCreateProjectProxy_proxy =
    //     TransparentUpgradeableProxy(payable(vm.envAddress("D4ACreateProjectProxy_proxy")));

    // address public deployer = vm.addr(deployerPrivateKey);
    // address public highRankOwner = 0x064D35db3f037149ed2c35c118a3bd79Fa4fE323;
    // address public lowRankOwner = 0x365088B0Fb00CAbaD7DacEB88211494E5D35F081;
    // address public signatureSigner = 0xB5A5a0dEec823323B25533cE8129c6c0eEfa8B3c;

    function setUp() public {
        // assertEq(vm.activeFork(), mainnetFork);
    }

    // function test_update_returnZero() public {
    //     uint256 startBlock = 0x4fc9ef;
    //     for (uint256 i = 0; i < 5; i++) {
    //         mainnetFork = vm.createFork(
    //             "",
    //             startBlock + i
    //         );
    //         vm.selectFork(mainnetFork);
    //         assertEq(vm.activeFork(), mainnetFork);
    //         //get block number
    //         address alice = address(0);
    //         address contract_address = 0x82b305a1F65418b337017e6B314aFad72EF2391A;
    //         vm.prank(alice);
    //         (bool success, bytes memory data) = contract_address.call(
    //             abi.encodeWithSignature(
    //                 "updateTopUpAccount(bytes32,(address,uint256))",
    //                 0x949a0d9226356525663d1527cb6439e8bd1e98fef539307036372725daf8833a,
    //                 NftIdentifier(0x3A50801807981D66D56A1287d98F4674a29f5258, 1)
    //             )
    //         );
    //         (uint256 erc20, uint256 eth) = abi.decode(data, (uint256, uint256));
    //         // console2.logBytes(
    //         //     abi.encodeWithSignature(
    //         //         "updateTopUpAccount(bytes32,(address,uint256))",
    //         //         0x85057a3a7556d0fac7ddc3c7625092d65fd213062cac9aa94b65e48d4ef3d114,
    //         //         NftIdentifier(0x736536fD105F2FCAC8E20d4E5D6C9eaD7744aE3D, 12_291)
    //         //     )
    //         // );
    //         console2.log(startBlock + i);
    //         console2.log("success", success);
    //         console2.logBytes(data);
    //         console2.log("ERC20", erc20, "ETH", eth);
    //         console2.log("\n");
    //     }
    // }

    // function test_update_returnZero() public {
    //     uint256 startBlock = 0x4fb756;
    //     for (uint256 i = 0; i < 1; i++) {
    //         mainnetFork = vm.createFork("", startBlock + i);
    //         vm.selectFork(mainnetFork);
    //         assertEq(vm.activeFork(), mainnetFork);
    //         //get block number
    //         bytes memory _data =
    //             hex"9d3e5aeb85057a3a7556d0fac7ddc3c7625092d65fd213062cac9aa94b65e48d4ef3d114000000000000000000000000736536fd105f2fcac8e20d4e5d6c9ead7744ae3d0000000000000000000000000000000000000000000000000000000000000bbb";
    //         address alice = address(0);
    //         address contract_address = 0x82b305a1F65418b337017e6B314aFad72EF2391A;
    //         vm.prank(alice);
    //         (bool success, bytes memory data) = contract_address.call(_data);
    //         (uint256 erc20, uint256 eth) = abi.decode(data, (uint256, uint256));
    //         console2.logBytes(
    //             abi.encodeWithSignature(
    //                 "updateTopUpAccount(bytes32,(address,uint256))",
    //                 0x85057a3a7556d0fac7ddc3c7625092d65fd213062cac9aa94b65e48d4ef3d114,
    //                 NftIdentifier(0x736536fD105F2FCAC8E20d4E5D6C9eaD7744aE3D, 12_291)
    //             )
    //         );
    //         console2.log(startBlock + i);
    //         console2.log("success", success);
    //         console2.logBytes(data);
    //         console2.log("ERC20", erc20, "ETH", eth);
    //         console2.log("\n");
    //     }
    // }

    // function test_Fork() public {
    //     startHoax(deployer);

    //     D4ACreateProjectProxy d4aCreateProjectProxy =
    //         D4ACreateProjectProxy(payable(address(d4aCreateProjectProxy_proxy)));
    //     D4AProtocol d4aProtocol =
    //         D4AProtocol(address(d4aProtocol_proxy));
    //     PermissionControl permissionControl = PermissionControl(address(permissionControl_proxy));

    //     uint256 startPrb = prb.currentRound();

    //     // create project, create canvas and mint NFT
    //     (bytes32 daoId,) =
    //         d4aCreateProjectProxy.createProject{value: 0.1 ether}(startPrb, 30, 0, 0, 750, "test createDao");
    //     bytes32 canvasId = d4aProtocol.createCanvas(daoId, "test canvas uri", new bytes32[](0));
    //     // uint256 tokenId =
    //     //     d4aProtocol.mintNFT(daoId, canvasId, "test nft uri", new bytes32[](0), 0, new
    // bytes(65));

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
