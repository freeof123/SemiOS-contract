// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DaoMetadataParam, UserMintCapParam} from "contracts/interface/D4AStructs.sol";

import "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {
    IPermissionControl,
    D4ADiamond,
    TestD4AProtocolWithPermission,
    TransparentUpgradeableProxy,
    NaiveOwner,
    DeployHelper
} from "./utils/DeployHelper.sol";
import {
    D4AProtocolWithPermission, D4AProtocolWithPermissionHarness
} from "./harness/D4AProtocolWithPermissionHarness.sol";
import {MintNftSigUtils} from "./utils/MintNftSigUtils.sol";
import {NotDaoOwner} from "contracts/interface/D4AErrors.sol";

contract D4AProtocolWithPermissionTest is DeployHelper {
    using stdStorage for StdStorage;

    D4AProtocolWithPermissionHarness public protocolHarness;

    function setUp() public {
        setUpEnv();
        D4AProtocolWithPermissionHarness harness = new D4AProtocolWithPermissionHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolWithPermissionHarness(payable(address(protocol)));
    }

    function test_MINTNFT_TYPEHASH() public {
        assertEq(
            protocolHarness.exposed_MINTNFT_TYPEHASH(),
            keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)")
        );
    }

    function test_exposed_daoMintInfos() public {
        assertEq(protocolHarness.exposed_daoMintInfos(0), 0);

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(bytes32(0), address(this));

        (, IPermissionControl.Whitelist memory whitelist, IPermissionControl.Blacklist memory blacklist) =
            _generateTrivialPermission();
        protocol.setMintCapAndPermission(bytes32(0), 100, new UserMintCapParam[](0), whitelist, blacklist, blacklist);
        assertEq(protocolHarness.exposed_daoMintInfos(0), 100);
    }

    function test_getDaoMintCap() public {
        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(bytes32(0), address(this));

        (, IPermissionControl.Whitelist memory whitelist, IPermissionControl.Blacklist memory blacklist) =
            _generateTrivialPermission();
        protocol.setMintCapAndPermission(bytes32(0), 100, new UserMintCapParam[](0), whitelist, blacklist, blacklist);
        assertEq(protocolHarness.exposed_daoMintInfos(0), protocol.getDaoMintCap(bytes32(0)));
    }

    function test_createCanvas() public {
        bytes32 daoId = _createTrivialDao(0, 30, 0, 0, 750, "test project uri");
        vm.expectCall({
            callee: address(permissionControl),
            data: abi.encodeWithSelector(permissionControl.isCanvasCreatorBlacklisted.selector),
            count: 1
        });
        vm.expectCall({
            callee: address(permissionControl),
            data: abi.encodeWithSelector(permissionControl.inCanvasCreatorWhitelist.selector),
            count: 1
        });
        bytes32 canvasId = protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri", new bytes32[](0));
        assertTrue(canvasId != bytes32(0));
    }

    function test_RevertIf_createCanvas_Blacklisted() public {
        address[] memory canvasCreatorAccounts = new address[](1);
        canvasCreatorAccounts[0] = address(this);
        bytes32 daoId = _createDaoWithPermission(
            0,
            30,
            0,
            0,
            750,
            "test project uri",
            bytes32(0),
            new address[](0),
            bytes32(0),
            new address[](0),
            new address[](0),
            canvasCreatorAccounts
        );
        vm.expectRevert(D4AProtocolWithPermission.Blacklisted.selector);
        protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri", new bytes32[](0));
    }

    function test_RevertIf_createCanvas_NotInWhtielist() public {
        address[] memory canvasCreatorNFTHolderPasses = new address[](1);
        _testERC721.mint(protocolOwner.addr, 0);
        canvasCreatorNFTHolderPasses[0] = address(_testERC721);
        bytes32 daoId = _createDaoWithPermission(
            0,
            30,
            0,
            0,
            750,
            "test project uri",
            bytes32(0),
            new address[](0),
            bytes32(0),
            canvasCreatorNFTHolderPasses,
            new address[](0),
            new address[](0)
        );
        vm.expectRevert(D4AProtocolWithPermission.NotInWhitelist.selector);
        protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri", new bytes32[](0));
    }

    function test_initialize() public {
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
        vm.prank(protocolOwner.addr);
        // set diamond fallback address
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolImpl));
        protocol.initialize();
    }

    function test_RevertIf_AlreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        protocol.initialize();
    }

    function test_exposed_checkMintEligibility() public {
        CreateDaoParam memory createDaoParam;
        createDaoParam.daoMetadataParam = DaoMetadataParam({
            startDrb: 0,
            mintableRounds: 30,
            floorPriceRank: 0,
            maxNftRank: 0,
            royaltyFee: 750,
            projectUri: "test project uri",
            projectIndex: 0
        });
        address[] memory minters = new address[](1);
        minters[0] = address(this);
        bytes32 minterMerkleRoot = getMerkleRoot(minters);
        bytes32[] memory proof = getMerkleProof(minters, address(this));
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.actionType = 2;
        bytes32 daoId = _createDao(createDaoParam);
        protocolHarness.exposed_checkMintEligibility(daoId, address(this), proof, 1);
    }

    function test_RevertIf_exposed_checkMintEligibility_ExceedMaxMintAmount() public {
        CreateDaoParam memory createDaoParam;
        createDaoParam.daoMetadataParam = DaoMetadataParam({
            startDrb: 0,
            mintableRounds: 30,
            floorPriceRank: 0,
            maxNftRank: 0,
            royaltyFee: 750,
            projectUri: "test project uri",
            projectIndex: 0
        });
        createDaoParam.mintCap = 10;
        address[] memory minters = new address[](1);
        minters[0] = address(this);
        bytes32 minterMerkleRoot = getMerkleRoot(minters);
        bytes32[] memory proof = getMerkleProof(minters, address(this));
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.actionType = 6;
        bytes32 daoId = _createDao(createDaoParam);
        protocolHarness.exposed_checkMintEligibility(daoId, address(this), proof, 10);
        vm.expectRevert(D4AProtocolWithPermission.ExceedMaxMintAmount.selector);
        protocolHarness.exposed_checkMintEligibility(daoId, address(this), proof, 11);
    }

    function test_mintNFT() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 0, 0, 750, "test project uri");

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri", new bytes32[](0));
        string memory tokenUri = "test nft uri";
        MintNftSigUtils sigUtils = new MintNftSigUtils(address(protocol));
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, 0);

        bytes memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signature = bytes.concat(r, s, bytes1(v));
        }

        hoax(nftMinter.addr);
        protocol.mintNFT{value: 0.1 ether}(daoId, canvasId, tokenUri, new bytes32[](0), 0, signature);

        (uint32 userMintNum,) = protocol.getUserMintInfo(daoId, nftMinter.addr);
        assertEq(userMintNum, 1);
    }

    function test_batchMint() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 0, 0, 750, "test project uri");

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri", new bytes32[](0));

        MintNftSigUtils sigUtils = new MintNftSigUtils(address(protocol));

        uint256 mintNum = 10;
        D4AProtocolWithPermission.MintNftInfo[] memory mintNftInfos =
            new D4AProtocolWithPermission.MintNftInfo[](mintNum);
        bytes[] memory signatures = new bytes[](mintNum);
        for (uint256 i; i < mintNum; ++i) {
            mintNftInfos[i].tokenUri = string.concat("test nft uri", vm.toString(i));
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, mintNftInfos[i].tokenUri, 0);
            bytes memory signature;
            {
                (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
                signature = bytes.concat(r, s, bytes1(v));
            }
            signatures[i] = signature;
        }

        hoax(nftMinter.addr);
        protocol.batchMint{value: 0.1 ether * (2 ** 10 - 1)}(
            daoId, canvasId, new bytes32[](0), mintNftInfos, signatures
        );

        (uint32 userMintNum,) = (protocol.getUserMintInfo(daoId, nftMinter.addr));
        assertEq(userMintNum, mintNum);
    }

    function test_setMintCapAndPermission() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 0, 0, 750, "test project uri");

        (, IPermissionControl.Whitelist memory whitelist, IPermissionControl.Blacklist memory blacklist) =
            _generateTrivialPermission();

        UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](2);
        userMintCapParams[0] = UserMintCapParam(protocolOwner.addr, 100);
        userMintCapParams[1] = UserMintCapParam(randomGuy.addr, 200);

        hoax(daoCreator.addr);
        vm.expectCall({
            callee: address(permissionControl),
            data: abi.encodeWithSelector(permissionControl.modifyPermission.selector),
            count: 1
        });
        protocol.setMintCapAndPermission(daoId, 100, userMintCapParams, whitelist, blacklist, blacklist);
    }

    function test_RevertIf_setMintCapAndPermission_NotDaoOwner() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 0, 0, 750, "test project uri");

        (, IPermissionControl.Whitelist memory whitelist, IPermissionControl.Blacklist memory blacklist) =
            _generateTrivialPermission();

        hoax(randomGuy.addr);
        vm.expectRevert(NotDaoOwner.selector);
        protocol.setMintCapAndPermission(daoId, 100, new UserMintCapParam[](0), whitelist, blacklist, blacklist);
    }

    event MintCapSet(bytes32 indexed DAO_id, uint32 mintCap, UserMintCapParam[] userMintCapParams);

    function test_setMintCapAndPermission_ExpectEmit() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 0, 0, 750, "test project uri");

        (, IPermissionControl.Whitelist memory whitelist, IPermissionControl.Blacklist memory blacklist) =
            _generateTrivialPermission();

        UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](2);
        userMintCapParams[0] = UserMintCapParam(protocolOwner.addr, 100);
        userMintCapParams[1] = UserMintCapParam(randomGuy.addr, 200);

        vm.expectEmit(true, true, true, true);
        emit MintCapSet(daoId, 100, userMintCapParams);
        hoax(daoCreator.addr);
        protocol.setMintCapAndPermission(daoId, 100, userMintCapParams, whitelist, blacklist, blacklist);
    }

    function test_exposed_ableToMint() public {
        CreateDaoParam memory createDaoParam;
        createDaoParam.daoMetadataParam = DaoMetadataParam({
            startDrb: 0,
            mintableRounds: 30,
            floorPriceRank: 0,
            maxNftRank: 0,
            royaltyFee: 750,
            projectUri: "test project uri",
            projectIndex: 0
        });
        address[] memory minters = new address[](1);
        minters[0] = address(this);
        bytes32 minterMerkleRoot = getMerkleRoot(minters);
        bytes32[] memory proof = getMerkleProof(minters, address(this));
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.actionType = 2;
        bytes32 daoId = _createDao(createDaoParam);
        protocolHarness.exposed_ableToMint(daoId, address(this), proof, 1);
    }

    function test_RevertIf_exposed_ableToMint_Blacklisted() public {
        CreateDaoParam memory createDaoParam;
        createDaoParam.daoMetadataParam = DaoMetadataParam({
            startDrb: 0,
            mintableRounds: 30,
            floorPriceRank: 0,
            maxNftRank: 0,
            royaltyFee: 750,
            projectUri: "test project uri",
            projectIndex: 0
        });
        createDaoParam.minterAccounts = new address[](1);
        createDaoParam.minterAccounts[0] = address(this);
        address[] memory minters = new address[](1);
        minters[0] = address(this);
        bytes32 minterMerkleRoot = getMerkleRoot(minters);
        bytes32[] memory proof = getMerkleProof(minters, address(this));
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.actionType = 2;
        bytes32 daoId = _createDao(createDaoParam);
        vm.expectRevert(D4AProtocolWithPermission.Blacklisted.selector);
        protocolHarness.exposed_ableToMint(daoId, address(this), proof, 1);
    }

    function test_RevertIf_exposed_ableToMint_NotInWhitelist() public {
        CreateDaoParam memory createDaoParam;
        createDaoParam.daoMetadataParam = DaoMetadataParam({
            startDrb: 0,
            mintableRounds: 30,
            floorPriceRank: 0,
            maxNftRank: 0,
            royaltyFee: 750,
            projectUri: "test project uri",
            projectIndex: 0
        });
        createDaoParam.minterAccounts = new address[](1);
        createDaoParam.minterAccounts[0] = address(this);
        address[] memory minters = new address[](1);
        minters[0] = address(this);
        bytes32 minterMerkleRoot = getMerkleRoot(minters);
        bytes32[] memory proof = getMerkleProof(minters, address(this));
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.actionType = 2;
        bytes32 daoId = _createDao(createDaoParam);
        vm.expectRevert(D4AProtocolWithPermission.NotInWhitelist.selector);
        protocolHarness.exposed_ableToMint(daoId, randomGuy.addr, proof, 1);
    }

    function test_exposed_verifySignature() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 0, 0, 750, "test project uri");

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri", new bytes32[](0));

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 100;

        MintNftSigUtils sigUtils = new MintNftSigUtils(address(protocol));
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectCall({
            callee: address(protocol),
            data: abi.encodeWithSelector(IAccessControl.hasRole.selector),
            count: 1
        });
        vm.expectCall({callee: address(naiveOwner), data: abi.encodeWithSelector(NaiveOwner.ownerOf.selector), count: 1});
        protocolHarness.exposed_verifySignature(canvasId, tokenUri, flatPrice, signature);
    }

    function test_RevertIf_exposed_verifySignature_InvalidSignature() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 0, 0, 750, "test project uri");

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri", new bytes32[](0));

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 100;

        MintNftSigUtils sigUtils = new MintNftSigUtils(address(protocol));
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(randomGuy.key, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(D4AProtocolWithPermission.InvalidSignature.selector);
        protocolHarness.exposed_verifySignature(canvasId, tokenUri, flatPrice, signature);
    }
}
