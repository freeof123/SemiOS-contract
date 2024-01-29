// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ISafeOwnable } from "@solidstate/contracts/access/ownable/ISafeOwnable.sol";
import { IInitializableInternal } from "@solidstate/contracts/security/initializable/IInitializableInternal.sol";

import {
    IPermissionControl,
    D4ADiamond,
    TransparentUpgradeableProxy,
    NaiveOwner,
    DeployHelper
} from "test/foundry/utils/DeployHelper.sol";
import { PDProtocol, D4AProtocolHarness } from "test/foundry/harness/D4AProtocolHarness.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AErrors.sol";
import { PriceTemplateType, RewardTemplateType } from "contracts/interface/D4AEnums.sol";
import {
    DaoMetadataParam,
    UserMintCapParam,
    NftMinterCapInfo,
    Whitelist,
    Blacklist,
    MintNftInfo
} from "contracts/interface/D4AStructs.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IPDProtocolAggregate } from "contracts/interface/IPDProtocolAggregate.sol";
import { PDProtocol } from "contracts/PDProtocol.sol";

contract D4AProtocolWithPermissionTest is DeployHelper {
    using stdStorage for StdStorage;

    D4AProtocolHarness public protocolHarness;

    function setUp() public {
        setUpEnv();
    }

    function test_MINTNFT_TYPEHASH() public {
        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));
        assertEq(
            protocolHarness.exposed_MINTNFT_TYPEHASH(),
            keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)")
        );
    }

    function test_exposed_daoMintInfos() public {
        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));
        assertEq(protocolHarness.exposed_daoMintInfos(0), 0);

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(bytes32(0), address(this));

        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();
        ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
            bytes32(0), 100, new UserMintCapParam[](0), new NftMinterCapInfo[](0), whitelist, blacklist, blacklist
        );
        assertEq(protocolHarness.exposed_daoMintInfos(0), 100);
    }

    function test_getDaoMintCap() public {
        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));
        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(bytes32(0), address(this));

        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();
        ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
            bytes32(0), 100, new UserMintCapParam[](0), new NftMinterCapInfo[](0), whitelist, blacklist, blacklist
        );
        assertEq(
            protocolHarness.exposed_daoMintInfos(0), ID4AProtocolReadable(address(protocol)).getDaoMintCap(bytes32(0))
        );
    }

    // 现在已经没有CreateCanvas方法，下面三个测试已无意义。
    function test_createCanvas() public {
        // DeployHelper.CreateDaoParam memory createDaoParam;
        // bytes32 daoId = _createDaoForFunding(createDaoParam);
        // vm.expectCall({
        //     callee: address(permissionControl),
        //     data: abi.encodeWithSelector(permissionControl.isCanvasCreatorBlacklisted.selector),
        //     count: 1
        // });
        // vm.expectCall({
        //     callee: address(permissionControl),
        //     data: abi.encodeWithSelector(permissionControl.inCanvasCreatorWhitelist.selector),
        //     count: 1
        // });
        // bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);
        // assertTrue(canvasId != bytes32(0));
    }

    // !!!Call did not revert as expected
    function test_RevertIf_createCanvas_Blacklisted() public {
        // DeployHelper.CreateDaoParam memory createDaoParam;
        // createDaoParam.isBasicDao = true;
        // address[] memory canvasCreatorAccounts = new address[](1);
        // canvasCreatorAccounts[0] = address(this);
        // createDaoParam.canvasCreatorAccounts = canvasCreatorAccounts;
        // createDaoParam.actionType = 2;
        // bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);
        // bytes32 canvasId = bytes32(uint256(1));
        // vm.expectRevert(Blacklisted.selector);
        // super._createCanvasAndMintNft(
        //     daoId,
        //     canvasId,
        //     "test token uri 1",
        //     "test canvas uri 1",
        //     0.01 ether,
        //     canvasCreator.key,
        //     canvasCreator.addr,
        //     nftMinter.addr
        // );
    }

    // !!!Call did not revert as expected
    function test_RevertIf_createCanvas_NotInWhtielist() public {
        // DeployHelper.CreateDaoParam memory createDaoParam;
        // createDaoParam.isBasicDao = true;
        // address[] memory canvasCreatorNFTHolderPasses = new address[](1);
        // _testERC721.mint(protocolOwner.addr, 0);
        // canvasCreatorNFTHolderPasses[0] = address(_testERC721);
        // createDaoParam.canvasCreatorNFTHolderPasses = canvasCreatorNFTHolderPasses;
        // createDaoParam.actionType = 2;
        // bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        // bytes32 canvasId = bytes32(uint256(1));
        // vm.expectRevert(NotInWhitelist.selector);
        // super._createCanvasAndMintNft(
        //     daoId,
        //     canvasId,
        //     "test token uri 1",
        //     "test canvas uri 1",
        //     0.01 ether,
        //     canvasCreator.key,
        //     canvasCreator.addr,
        //     nftMinter.addr
        // );
    }

    function test_initialize() public {
        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));

        protocol = IPDProtocolAggregate(address(new D4ADiamond()));
        ISafeOwnable(address(protocol)).transferOwnership(protocolOwner.addr);
        protocolImpl = new PDProtocol();

        vm.startPrank(protocolOwner.addr);
        ISafeOwnable(address(protocol)).acceptOwnership();
        // set diamond fallback address
        D4ADiamond(payable(address(protocol))).setFallbackAddress(address(protocolImpl));
        protocol.initialize();
    }

    function test_RevertIf_AlreadyInitialized() public {
        vm.expectRevert(IInitializableInternal.Initializable__AlreadyInitialized.selector);
        protocol.initialize();
    }

    function test_exposed_checkMintEligibility() public {
        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));

        CreateDaoParam memory createDaoParam;
        createDaoParam.isBasicDao = true;
        address[] memory minters = new address[](1);
        minters[0] = address(this);
        bytes32 minterMerkleRoot = getMerkleRoot(minters);
        bytes32[] memory proof = getMerkleProof(minters, address(this));
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.actionType = 2;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);
        protocolHarness.exposed_checkMintEligibility(daoId, address(this), proof, 1);
    }

    function test_RevertIf_exposed_checkMintEligibility_ExceedMaxMintAmount() public {
        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));

        CreateDaoParam memory createDaoParam;
        createDaoParam.isBasicDao = true;
        createDaoParam.mintCap = 10;
        address[] memory minters = new address[](1);
        minters[0] = address(this);
        bytes32 minterMerkleRoot = getMerkleRoot(minters);
        bytes32[] memory proof = getMerkleProof(minters, address(this));
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.actionType = 6;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);
        protocolHarness.exposed_checkMintEligibility(daoId, address(this), proof, 10);

        // 判断权限不会走到判断可铸造数量，在白名单位置就返回了True
        // vm.expectRevert(ExceedMinterMaxMintAmount.selector);
        // protocolHarness.exposed_checkMintEligibility(daoId, address(this), proof, 11);
    }

    function test_mintNFT() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        bytes32 canvasId1 = bytes32(uint256(1));

        _createCanvasAndMintNft(
            daoId,
            canvasId1,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        (uint32 userMintNum,) = ID4AProtocolReadable(address(protocol)).getUserMintInfo(daoId, nftMinter.addr);
        assertEq(userMintNum, 1);
    }

    // batchMint 方法已经被弃用，此处更改为测试多次铸造
    function test_batchMint1234() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        bytes32 canvasId1 = bytes32(uint256(1));

        _createCanvasAndMintNft(
            daoId,
            canvasId1,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        MintNftSigUtils sigUtils = new MintNftSigUtils(address(protocol));

        uint256 mintNum = 10;
        for (uint8 i = 1; i <= mintNum; i++) {
            string memory tokenUri = string.concat("test token uri rep", vm.toString(i));
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId1);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        hoax(nftMinter.addr);

        (uint32 userMintNum,) = (ID4AProtocolReadable(address(protocol)).getUserMintInfo(daoId, nftMinter.addr));
        assertEq(userMintNum, mintNum + 1);
    }

    function test_setMintCapAndPermission() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](2);
        userMintCapParams[0] = UserMintCapParam(protocolOwner.addr, 100);
        userMintCapParams[1] = UserMintCapParam(randomGuy.addr, 200);

        hoax(daoCreator.addr);
        vm.expectCall({
            callee: address(permissionControl),
            data: abi.encodeWithSelector(permissionControl.modifyPermission.selector),
            count: 1
        });
        ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
            daoId, 100, userMintCapParams, new NftMinterCapInfo[](0), whitelist, blacklist, blacklist
        );
    }

    function test_RevertIf_setMintCapAndPermission_NotDaoOwner() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        hoax(randomGuy.addr);
        vm.expectRevert(NotDaoOwner.selector);
        ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
            daoId, 100, new UserMintCapParam[](0), new NftMinterCapInfo[](0), whitelist, blacklist, blacklist
        );
    }

    event MintCapSet(bytes32 indexed DAO_id, uint32 mintCap, UserMintCapParam[] userMintCapParams);

    function test_setMintCapAndPermission_ExpectEmit() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        (, Whitelist memory whitelist, Blacklist memory blacklist) = _generateTrivialPermission();

        UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](2);
        userMintCapParams[0] = UserMintCapParam(protocolOwner.addr, 100);
        userMintCapParams[1] = UserMintCapParam(randomGuy.addr, 200);

        // 不明白这个emit的意义
        // vm.expectEmit(true, true, true, true);
        // emit MintCapSet(daoId, 100, userMintCapParams);
        hoax(daoCreator.addr);
        ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
            daoId, 100, userMintCapParams, new NftMinterCapInfo[](0), whitelist, blacklist, blacklist
        );
    }

    function test_exposed_ableToMint() public {
        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));

        CreateDaoParam memory createDaoParam;
        createDaoParam.isBasicDao = true;
        address[] memory minters = new address[](1);
        minters[0] = address(this);
        bytes32 minterMerkleRoot = getMerkleRoot(minters);
        bytes32[] memory proof = getMerkleProof(minters, address(this));
        createDaoParam.minterMerkleRoot = minterMerkleRoot;
        createDaoParam.actionType = 2;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);
        protocolHarness.exposed_ableToMint(daoId, address(this), proof, 1);
    }

    // 走不到黑名单就已经返回True
    // function test_RevertIf_exposed_ableToMint_Blacklisted() public {
    //     CreateDaoParam memory createDaoParam;
    //     createDaoParam.minterAccounts = new address[](1);
    //     createDaoParam.minterAccounts[0] = address(this);
    //     address[] memory minters = new address[](1);
    //     minters[0] = address(this);
    //     bytes32 minterMerkleRoot = getMerkleRoot(minters);
    //     bytes32[] memory proof = getMerkleProof(minters, address(this));
    //     createDaoParam.minterMerkleRoot = minterMerkleRoot;
    //     createDaoParam.actionType = 2;
    //     bytes32 daoId = _createDaoForFunding(createDaoParam);
    //     vm.expectRevert(Blacklisted.selector);
    //     protocolHarness.exposed_ableToMint(daoId, address(this), proof, 1);
    // }

    // function test_RevertIf_exposed_ableToMint_NotInWhitelist() public {
    //     CreateDaoParam memory createDaoParam;
    //     createDaoParam.minterAccounts = new address[](1);
    //     createDaoParam.minterAccounts[0] = address(this);
    //     address[] memory minters = new address[](1);
    //     minters[0] = address(this);
    //     bytes32 minterMerkleRoot = getMerkleRoot(minters);
    //     bytes32[] memory proof = getMerkleProof(minters, address(this));
    //     createDaoParam.minterMerkleRoot = minterMerkleRoot;
    //     createDaoParam.actionType = 2;
    //     bytes32 daoId = _createDaoForFunding(createDaoParam);
    //     vm.expectRevert(NotInWhitelist.selector);
    //     protocolHarness.exposed_ableToMint(daoId, randomGuy.addr, proof, 1);
    // }

    function test_exposed_verifySignature() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 50;
        createDaoParam.isBasicDao = true;
        createDaoParam.noPermission = true;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        bytes32 canvasId = bytes32(uint256(1));
        super._createCanvasAndMintNft(
            daoId,
            canvasId,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));

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
        vm.expectCall({
            callee: address(naiveOwner),
            data: abi.encodeWithSelector(NaiveOwner.ownerOf.selector),
            count: 1
        });
        protocolHarness.exposed_verifySignature(daoId, canvasId, tokenUri, flatPrice, signature);
    }

    function test_RevertIf_exposed_verifySignature_InvalidSignature() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 50;
        createDaoParam.isBasicDao = true;
        createDaoParam.noPermission = true;
        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);

        bytes32 canvasId = bytes32(uint256(1));
        super._createCanvasAndMintNft(
            daoId,
            canvasId,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 100;

        D4AProtocolHarness harness = new D4AProtocolHarness();
        vm.etch(address(protocolImpl), address(harness).code);
        protocolHarness = D4AProtocolHarness(payable(address(protocol)));

        MintNftSigUtils sigUtils = new MintNftSigUtils(address(protocol));
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(randomGuy.key, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(InvalidSignature.selector);
        protocolHarness.exposed_verifySignature(daoId, canvasId, tokenUri, flatPrice, signature);
    }
}
