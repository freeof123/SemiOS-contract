// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { PermissionControlSigUtils } from "test/foundry/utils/PermissionControlSigUtils.sol";
import { PermissionControlHarness } from "test/foundry/harness/PermissionControlHarness.sol";
import {
    DeployHelper,
    TestERC721,
    NaiveOwner,
    PermissionControl,
    TransparentUpgradeableProxy
} from "test/foundry/utils/DeployHelper.sol";

import { Whitelist, Blacklist } from "contracts/interface/D4AStructs.sol";
import { ID4AOwnerProxy } from "contracts/interface/ID4AOwnerProxy.sol";

contract PermissionControlTest is DeployHelper {
    PermissionControlSigUtils public sigUtils;
    TestERC721 public nft = new TestERC721();
    uint256 public counter;

    function _deployPermissionControlHarness() internal {
        PermissionControlHarness harness = new PermissionControlHarness(address(protocol), address(daoProxy));
        vm.etch(address(permissionControlImpl), address(harness).code);
    }

    function setUp() public {
        setUpEnv();

        vm.prank(protocolOwner.addr);
        _deployPermissionControlHarness();

        sigUtils = new PermissionControlSigUtils(address(permissionControl));
    }

    function test_OwnerProxy() public {
        assertEq(address(permissionControl.ownerProxy()), address(naiveOwner), "address should equal");
    }

    function test_RevertIf_TryToInitializeAgain() public {
        vm.expectRevert("Initializable: contract is already initialized");
        permissionControl.initialize(naiveOwner);
    }

    function _generateSignature(
        Account memory signer,
        bytes32 daoId,
        Whitelist memory whitelist,
        Blacklist memory blacklist
    )
        internal
        view
        returns (bytes memory signature)
    {
        bytes32 digest = sigUtils.getTypedDataHash(daoId, whitelist, blacklist);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer.key, digest);
        signature = bytes.concat(r, s, bytes1(v));
    }

    function test_AddPermissionWithSignature() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        bytes memory signature = _generateSignature(daoCreator, daoId, whitelist, blacklist);

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermissionWithSignature(daoId, whitelist, blacklist, signature);
    }

    function test_RevertIf_AddPermissionWithSignature_RecoverZeroAddress() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        bytes memory signature = bytes.concat(bytes1(0), bytes32(0), bytes32(0));

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.expectRevert("ECDSA: invalid signature");
        vm.prank(daoCreator.addr);
        permissionControl.addPermissionWithSignature(daoId, whitelist, blacklist, signature);
    }

    function test_RevertIf_AddPermissionWithSignature_InvalidSignature() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        bytes memory signature = bytes.concat(bytes1(uint8(1)), bytes32(uint256(2)), bytes32(uint256(3)));

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.expectRevert("ECDSA: invalid signature");
        vm.prank(daoCreator.addr);
        permissionControl.addPermissionWithSignature(daoId, whitelist, blacklist, signature);
    }

    function test_RevertIf_AddPermissionWithSignature_InvalidSignatureLength() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        bytes memory signature = bytes.concat(bytes1(0), bytes32(0), bytes32(0), bytes32("gibberish"));

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.expectRevert("ECDSA: invalid signature length");
        vm.prank(daoCreator.addr);
        permissionControl.addPermissionWithSignature(daoId, whitelist, blacklist, signature);
    }

    function test_RevertIf_AddPermissionWithSignature_InvalidSignatureS() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        bytes memory signature = bytes.concat(bytes1(0), bytes32(type(uint256).max), bytes32(0));

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.expectRevert("ECDSA: invalid signature 's' value");
        vm.prank(daoCreator.addr);
        permissionControl.addPermissionWithSignature(daoId, whitelist, blacklist, signature);

        signature = bytes.concat(
            bytes1(0),
            bytes32(uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 + 1)),
            bytes32(0)
        );
        vm.expectRevert("ECDSA: invalid signature 's' value");
        vm.prank(daoCreator.addr);
        permissionControl.addPermissionWithSignature(daoId, whitelist, blacklist, signature);
    }

    function test_RevertIf_AddPermisisonWithSignature_WrongSignature() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        bytes memory signature = _generateSignature(randomGuy, daoId, whitelist, blacklist);

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.expectRevert("PermissionControl: not DAO owner");
        vm.prank(daoCreator.addr);
        permissionControl.addPermissionWithSignature(daoId, whitelist, blacklist, signature);
    }

    function test_AddPermission() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);
    }

    function test_RevertIf_AddPermission_NotdaoCreator() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.expectRevert("PermissionControl: not DAO owner");
        vm.prank(randomGuy.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);
    }

    function test_AddPermission_Exposed() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        PermissionControlHarness(address(permissionControl)).exposed_addPermission(daoId, whitelist, blacklist);
    }

    event MinterBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorBlacklisted(bytes32 indexed daoId, address indexed account);

    event WhitelistModified(bytes32 indexed daoId, Whitelist whitelist);

    function test_AddPermission_ExpectEmit() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.expectEmit(true, true, true, true);
        emit WhitelistModified(daoId, whitelist);
        vm.expectEmit(true, true, true, true);
        emit MinterBlacklisted(daoId, blacklist.minterAccounts[0]);
        vm.expectEmit(true, true, true, true);
        emit MinterBlacklisted(daoId, blacklist.minterAccounts[1]);
        vm.expectEmit(true, true, true, true);
        emit CanvasCreatorBlacklisted(daoId, blacklist.canvasCreatorAccounts[0]);
        vm.expectEmit(true, true, true, true);
        emit CanvasCreatorBlacklisted(daoId, blacklist.canvasCreatorAccounts[1]);
        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);
    }

    function test_Blacklisted_Exposed() public {
        (bytes32 daoId, Whitelist memory whitelist,) = _generateTrivialPermission();

        Blacklist memory blacklist;
        // [0, 4) only minter, [4, 8) both, [8, 12) only canvas creator
        blacklist.minterAccounts = new address[](8);
        for (uint256 i = 0; i < 8; i++) {
            blacklist.minterAccounts[i] = vm.addr(i + 1);
        }
        blacklist.canvasCreatorAccounts = new address[](8);
        for (uint256 i = 4; i < 12; i++) {
            blacklist.canvasCreatorAccounts[i - 4] = vm.addr(i + 1);
        }

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        PermissionControlHarness(address(permissionControl)).exposed_addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 0; i < 4; i++) {
            assertEq(
                PermissionControlHarness(address(permissionControl)).exposed_blacklisted(daoId, vm.addr(i + 1)), 0x11
            );
        }
        for (uint256 i = 4; i < 8; i++) {
            assertEq(
                PermissionControlHarness(address(permissionControl)).exposed_blacklisted(daoId, vm.addr(i + 1)), 0x111
            );
        }
        for (uint256 i = 8; i < 12; i++) {
            assertEq(
                PermissionControlHarness(address(permissionControl)).exposed_blacklisted(daoId, vm.addr(i + 1)), 0x101
            );
        }

        blacklist.minterAccounts = new address[](8);
        blacklist.minterAccounts[0] = vm.addr(1);
        blacklist.minterAccounts[1] = vm.addr(2);
        blacklist.minterAccounts[2] = vm.addr(5);
        blacklist.minterAccounts[3] = vm.addr(6);
        blacklist.minterAccounts[4] = vm.addr(9);
        blacklist.minterAccounts[5] = vm.addr(10);
        blacklist.minterAccounts[6] = vm.addr(13);
        blacklist.minterAccounts[7] = vm.addr(14);
        blacklist.canvasCreatorAccounts = new address[](8);
        blacklist.canvasCreatorAccounts[0] = vm.addr(1);
        blacklist.canvasCreatorAccounts[1] = vm.addr(3);
        blacklist.canvasCreatorAccounts[2] = vm.addr(5);
        blacklist.canvasCreatorAccounts[3] = vm.addr(7);
        blacklist.canvasCreatorAccounts[4] = vm.addr(9);
        blacklist.canvasCreatorAccounts[5] = vm.addr(11);
        blacklist.canvasCreatorAccounts[6] = vm.addr(13);
        blacklist.canvasCreatorAccounts[7] = vm.addr(15);

        Blacklist memory unblacklist;
        unblacklist.minterAccounts = new address[](8);
        unblacklist.minterAccounts[0] = vm.addr(3);
        unblacklist.minterAccounts[1] = vm.addr(4);
        unblacklist.minterAccounts[2] = vm.addr(7);
        unblacklist.minterAccounts[3] = vm.addr(8);
        unblacklist.minterAccounts[4] = vm.addr(11);
        unblacklist.minterAccounts[5] = vm.addr(12);
        unblacklist.minterAccounts[6] = vm.addr(15);
        unblacklist.minterAccounts[7] = vm.addr(16);
        unblacklist.canvasCreatorAccounts = new address[](8);
        unblacklist.canvasCreatorAccounts[0] = vm.addr(2);
        unblacklist.canvasCreatorAccounts[1] = vm.addr(4);
        unblacklist.canvasCreatorAccounts[2] = vm.addr(6);
        unblacklist.canvasCreatorAccounts[3] = vm.addr(8);
        unblacklist.canvasCreatorAccounts[4] = vm.addr(10);
        unblacklist.canvasCreatorAccounts[5] = vm.addr(12);
        unblacklist.canvasCreatorAccounts[6] = vm.addr(14);
        unblacklist.canvasCreatorAccounts[7] = vm.addr(16);

        vm.prank(daoCreator.addr);
        permissionControl.modifyPermission(daoId, whitelist, blacklist, unblacklist);

        for (uint256 i = 0; i < 4; i++) {
            assertEq(
                PermissionControlHarness(address(permissionControl)).isMinterBlacklisted(daoId, vm.addr(4 * i + 1)),
                true
            );
            assertEq(
                PermissionControlHarness(address(permissionControl)).isMinterBlacklisted(daoId, vm.addr(4 * i + 2)),
                true
            );
            assertEq(
                PermissionControlHarness(address(permissionControl)).isMinterBlacklisted(daoId, vm.addr(4 * i + 3)),
                false
            );
            assertEq(
                PermissionControlHarness(address(permissionControl)).isMinterBlacklisted(daoId, vm.addr(4 * i + 4)),
                false
            );
            assertEq(
                PermissionControlHarness(address(permissionControl)).isCanvasCreatorBlacklisted(
                    daoId, vm.addr(4 * i + 1)
                ),
                true
            );
            assertEq(
                PermissionControlHarness(address(permissionControl)).isCanvasCreatorBlacklisted(
                    daoId, vm.addr(4 * i + 2)
                ),
                false
            );
            assertEq(
                PermissionControlHarness(address(permissionControl)).isCanvasCreatorBlacklisted(
                    daoId, vm.addr(4 * i + 3)
                ),
                true
            );
            assertEq(
                PermissionControlHarness(address(permissionControl)).isCanvasCreatorBlacklisted(
                    daoId, vm.addr(4 * i + 4)
                ),
                false
            );
        }
    }

    function test_GetWhitelist() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        Whitelist memory getWhitelist = permissionControl.getWhitelist(daoId);

        bytes32 minterMerkleRoot = getWhitelist.minterMerkleRoot;
        address[] memory minterNFTHolderPasses = getWhitelist.minterNFTHolderPasses;
        bytes32 canvasCreatorMerkleRoot = getWhitelist.canvasCreatorMerkleRoot;
        address[] memory canvasCreatorNFTHolderPasses = getWhitelist.canvasCreatorNFTHolderPasses;

        assertEq(minterMerkleRoot, whitelist.minterMerkleRoot);
        assertEq(minterNFTHolderPasses, whitelist.minterNFTHolderPasses);
        assertEq(canvasCreatorMerkleRoot, whitelist.canvasCreatorMerkleRoot);
        assertEq(canvasCreatorNFTHolderPasses, whitelist.canvasCreatorNFTHolderPasses);
    }

    function test_ModifyPermission() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        Blacklist memory unblacklist = blacklist;

        vm.prank(daoCreator.addr);
        permissionControl.modifyPermission(daoId, whitelist, blacklist, unblacklist);
    }

    function test_RevertIf_ModifyPermission_NotdaoCreator() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        Blacklist memory unblacklist = blacklist;

        vm.expectRevert("PermissionControl: not DAO owner");
        vm.prank(randomGuy.addr);
        permissionControl.modifyPermission(daoId, whitelist, blacklist, unblacklist);
    }

    event MinterUnBlacklisted(bytes32 indexed daoId, address indexed account);

    event CanvasCreatorUnBlacklisted(bytes32 indexed daoId, address indexed account);

    function test_ModifyPermission_ExpectEmit() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        Blacklist memory unblacklist = blacklist;

        vm.expectEmit(true, true, true, true);
        emit WhitelistModified(daoId, whitelist);
        vm.expectEmit(true, true, true, true);
        emit MinterBlacklisted(daoId, blacklist.minterAccounts[0]);
        vm.expectEmit(true, true, true, true);
        emit MinterBlacklisted(daoId, blacklist.minterAccounts[1]);
        vm.expectEmit(true, true, true, true);
        emit CanvasCreatorBlacklisted(daoId, blacklist.canvasCreatorAccounts[0]);
        vm.expectEmit(true, true, true, true);
        emit CanvasCreatorBlacklisted(daoId, blacklist.canvasCreatorAccounts[1]);
        vm.expectEmit(true, true, true, true);
        emit MinterUnBlacklisted(daoId, blacklist.minterAccounts[0]);
        vm.expectEmit(true, true, true, true);
        emit MinterUnBlacklisted(daoId, blacklist.minterAccounts[1]);
        vm.expectEmit(true, true, true, true);
        emit CanvasCreatorUnBlacklisted(daoId, blacklist.canvasCreatorAccounts[0]);
        vm.expectEmit(true, true, true, true);
        emit CanvasCreatorUnBlacklisted(daoId, blacklist.canvasCreatorAccounts[1]);

        vm.prank(daoCreator.addr);
        permissionControl.modifyPermission(daoId, whitelist, blacklist, unblacklist);
    }

    function test_VerifySignature_Exposed() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        bytes memory signature = _generateSignature(daoCreator, daoId, whitelist, blacklist);

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);
        PermissionControlHarness(address(permissionControl)).exposed_verifySignature(
            daoId, whitelist, blacklist, signature
        );
    }

    function test_RevertIf_VerifySignature_Exposed_RecoverZeroAddress() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        bytes memory signature = bytes.concat(bytes1(0), bytes32(0), bytes32(0));

        vm.expectRevert(bytes("ECDSA: invalid signature"));
        PermissionControlHarness(address(permissionControl)).exposed_verifySignature(
            daoId, whitelist, blacklist, signature
        );
    }

    function test_RevertIf_VerifySignature_Exposed_InvalidSignature() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        bytes memory signature = bytes.concat(bytes1(uint8(1)), bytes32(uint256(2)), bytes32(uint256(3)));

        vm.expectRevert(bytes("ECDSA: invalid signature"));
        PermissionControlHarness(address(permissionControl)).exposed_verifySignature(
            daoId, whitelist, blacklist, signature
        );
    }

    function test_RevertIf_VerifySignature_Exposed_InvalidSignatureLength() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        bytes memory signature = bytes.concat(bytes1(0), bytes32(0), bytes32(0), bytes32("gibberish"));

        vm.expectRevert(bytes("ECDSA: invalid signature length"));
        PermissionControlHarness(address(permissionControl)).exposed_verifySignature(
            daoId, whitelist, blacklist, signature
        );
    }

    function test_RevertIf_VerifySignature_Exposed_InvalidSignatureS() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        bytes memory signature = bytes.concat(bytes1(0), bytes32(type(uint256).max), bytes32(0));

        vm.expectRevert(bytes("ECDSA: invalid signature 's' value"));
        PermissionControlHarness(address(permissionControl)).exposed_verifySignature(
            daoId, whitelist, blacklist, signature
        );

        signature = bytes.concat(
            bytes1(0),
            bytes32(uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 + 1)),
            bytes32(0)
        );
        vm.expectRevert(bytes("ECDSA: invalid signature 's' value"));
        PermissionControlHarness(address(permissionControl)).exposed_verifySignature(
            daoId, whitelist, blacklist, signature
        );
    }

    function test_RevertIf_VerifySignature_Exposed_WrongSignature() public {
        (bytes32 daoId, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        bytes memory signature = _generateSignature(randomGuy, daoId, whitelist, blacklist);

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.expectRevert("PermissionControl: not DAO owner");
        PermissionControlHarness(address(permissionControl)).exposed_verifySignature(
            daoId, whitelist, blacklist, signature
        );
    }

    function test_IsMinterBlacklisted() public {
        bytes32 daoId = keccak256("test");

        Whitelist memory whitelist;

        Blacklist memory blacklist;
        {
            blacklist.minterAccounts = new address[](2);
            blacklist.minterAccounts[0] = vm.addr(0x3);
            blacklist.minterAccounts[1] = vm.addr(0x4);
        }

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 1; i < 0x10; i++) {
            if (i == 0x3 || i == 0x4) {
                assertEq(
                    permissionControl.isMinterBlacklisted(daoId, vm.addr(i)), true, "address should be blacklisted"
                );
            } else {
                assertEq(
                    permissionControl.isMinterBlacklisted(daoId, vm.addr(i)), false, "address should not be blacklisted"
                );
            }
        }
    }

    function test_IsCanvasCreatorBlacklisted() public {
        bytes32 daoId = keccak256("test");

        Whitelist memory whitelist;

        Blacklist memory blacklist;
        {
            blacklist.canvasCreatorAccounts = new address[](2);
            blacklist.canvasCreatorAccounts[0] = vm.addr(0x3);
            blacklist.canvasCreatorAccounts[1] = vm.addr(0x4);
        }

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 1; i < 0x10; i++) {
            if (i == 0x3 || i == 0x4) {
                assertEq(
                    permissionControl.isCanvasCreatorBlacklisted(daoId, vm.addr(i)),
                    true,
                    "address should be blacklisted"
                );
            } else {
                assertEq(
                    permissionControl.isCanvasCreatorBlacklisted(daoId, vm.addr(i)),
                    false,
                    "address should not be blacklisted"
                );
            }
        }
    }

    function _random(uint256 seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed)));
    }

    function test_InMinterWhitelist_MerkleTree() public {
        bytes32 daoId = keccak256("test");

        uint256 accountsNumber = 100;
        address[] memory accounts = new address[](accountsNumber);
        for (uint256 i = 0; i < accountsNumber; i++) {
            accounts[i] = vm.addr(i + 1);
        }

        Whitelist memory whitelist;
        {
            whitelist.minterMerkleRoot = getMerkleRoot(accounts);
        }

        Blacklist memory blacklist;

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 0; i < 10; i++) {
            uint256 index = _random(i) % accountsNumber;
            bytes32[] memory proof = getMerkleProof(accounts, accounts[index]);
            assertEq(
                permissionControl.inMinterWhitelist(daoId, accounts[index], proof),
                true,
                "address should be in whitelist"
            );
        }
    }

    function _generateAccounts(uint256 accountsNumber) internal pure returns (address[] memory) {
        address[] memory accounts = new address[](accountsNumber);
        for (uint256 i = 0; i < accountsNumber; i++) {
            accounts[i] = vm.addr(i + 1);
        }
        return accounts;
    }

    function _batchMint(address[] memory accounts) internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            nft.mint(accounts[i], counter++);
        }
    }

    function test_InMinterWhitelist_Nft() public {
        bytes32 daoId = keccak256("test");

        uint256 accountsNumber = 100;
        address[] memory accounts = _generateAccounts(accountsNumber);
        _batchMint(accounts);

        Whitelist memory whitelist;
        {
            whitelist.minterNFTHolderPasses = new address[](1);
            whitelist.minterNFTHolderPasses[0] = address(nft);
        }

        Blacklist memory blacklist;

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 0; i < 10; i++) {
            uint256 index = _random(i) % accountsNumber;
            bytes32[] memory proof = getMerkleProof(accounts, accounts[index]);
            assertEq(
                permissionControl.inMinterWhitelist(daoId, accounts[index], proof),
                //permission control的inMinterWhitelist如今只会判断是否在merkel root中，不涉及无铸造上限nft白名单的判断逻辑，故此时应改为false
                false,
                "address should be in whitelist"
            );
        }
    }

    function test_InMinterWhitelist_Both() public {
        bytes32 daoId = keccak256("test");

        uint256 accountsNumber = 100;
        address[] memory accounts = _generateAccounts(accountsNumber);
        _batchMint(accounts);

        Whitelist memory whitelist;
        {
            whitelist.minterNFTHolderPasses = new address[](1);
            whitelist.minterNFTHolderPasses[0] = address(nft);
            whitelist.minterMerkleRoot = getMerkleRoot(accounts);
        }

        Blacklist memory blacklist;

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 0; i < 10; i++) {
            uint256 index = _random(i) % accountsNumber;
            bytes32[] memory proof = getMerkleProof(accounts, accounts[index]);
            assertEq(
                permissionControl.inMinterWhitelist(daoId, accounts[index], proof),
                true,
                "address should be in whitelist"
            );
        }
    }

    function test_InMinterWhitelist_Neither() public {
        bytes32 daoId = keccak256("test");

        uint256 accountsNumber = 100;
        address[] memory accounts = _generateAccounts(accountsNumber);
        _batchMint(accounts);

        Whitelist memory whitelist;
        {
            whitelist.minterNFTHolderPasses = new address[](1);
            whitelist.minterNFTHolderPasses[0] = address(nft);
            whitelist.minterMerkleRoot = getMerkleRoot(accounts);
        }

        Blacklist memory blacklist;

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        assertEq(
            permissionControl.inMinterWhitelist(daoId, vm.addr(0x102), new bytes32[](0)),
            false,
            "address should not be in whitelist"
        );
    }

    function test_InCanvasCreatorWhitelist_MerkleTree() public {
        bytes32 daoId = keccak256("test");

        uint256 accountsNumber = 100;
        address[] memory accounts = _generateAccounts(accountsNumber);

        Whitelist memory whitelist;
        {
            whitelist.canvasCreatorMerkleRoot = getMerkleRoot(accounts);
        }

        Blacklist memory blacklist;

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 0; i < 10; i++) {
            uint256 index = _random(i) % accountsNumber;
            bytes32[] memory proof = getMerkleProof(accounts, accounts[index]);
            assertEq(
                permissionControl.inCanvasCreatorWhitelist(daoId, accounts[index], proof),
                true,
                "address should be in whitelist"
            );
        }
    }

    function test_InCanvasCreatorWhitelist_Nft() public {
        bytes32 daoId = keccak256("test");

        uint256 accountsNumber = 100;
        address[] memory accounts = _generateAccounts(accountsNumber);
        _batchMint(accounts);

        Whitelist memory whitelist;
        {
            whitelist.canvasCreatorNFTHolderPasses = new address[](1);
            whitelist.canvasCreatorNFTHolderPasses[0] = address(nft);
        }

        Blacklist memory blacklist;

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 0; i < 10; i++) {
            uint256 index = _random(i) % accountsNumber;
            bytes32[] memory proof = getMerkleProof(accounts, accounts[index]);
            assertEq(
                permissionControl.inCanvasCreatorWhitelist(daoId, accounts[index], proof),
                true,
                "address should be in whitelist"
            );
        }
    }

    function test_InCanvasCreatorWhitelist_Both() public {
        bytes32 daoId = keccak256("test");

        uint256 accountsNumber = 100;
        address[] memory accounts = _generateAccounts(accountsNumber);
        _batchMint(accounts);

        Whitelist memory whitelist;
        {
            whitelist.canvasCreatorNFTHolderPasses = new address[](1);
            whitelist.canvasCreatorNFTHolderPasses[0] = address(nft);
            whitelist.canvasCreatorMerkleRoot = getMerkleRoot(accounts);
        }

        Blacklist memory blacklist;

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        for (uint256 i = 0; i < 10; i++) {
            uint256 index = _random(i) % accountsNumber;
            bytes32[] memory proof = getMerkleProof(accounts, accounts[index]);
            assertEq(
                permissionControl.inCanvasCreatorWhitelist(daoId, accounts[index], proof),
                true,
                "address should be in whitelist"
            );
        }
    }

    function test_InCanvasCreatorWhitelist_Neither() public {
        bytes32 daoId = keccak256("test");

        uint256 accountsNumber = 100;
        address[] memory accounts = _generateAccounts(accountsNumber);
        _batchMint(accounts);

        Whitelist memory whitelist;
        {
            whitelist.canvasCreatorNFTHolderPasses = new address[](1);
            whitelist.canvasCreatorNFTHolderPasses[0] = address(nft);
            whitelist.canvasCreatorMerkleRoot = getMerkleRoot(accounts);
        }

        Blacklist memory blacklist;

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(daoId, daoCreator.addr);

        vm.prank(daoCreator.addr);
        permissionControl.addPermission(daoId, whitelist, blacklist);

        assertEq(
            permissionControl.inCanvasCreatorWhitelist(daoId, vm.addr(0x102), new bytes32[](0)),
            false,
            "address should not be in whitelist"
        );
    }

    function test_SetOwnerProxy() public {
        vm.startPrank(protocolOwner.addr);
        NaiveOwner newOwnerProxy = new NaiveOwner();
        permissionControl.setOwnerProxy(ID4AOwnerProxy(address(newOwnerProxy)));
        assertEq(address(permissionControl.ownerProxy()), address(newOwnerProxy), "owner proxy should be set");
    }

    function test_RevertIf_SetOwnerProxy_NotDefaultAdminRole() public {
        NaiveOwner newOwnerProxy = new NaiveOwner();
        vm.expectRevert("Not owner");
        vm.prank(daoCreator.addr);
        permissionControl.setOwnerProxy(ID4AOwnerProxy(address(newOwnerProxy)));
    }
}
