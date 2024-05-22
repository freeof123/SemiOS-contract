// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";
import "contracts/interface/D4AErrors.sol";

import { console2 } from "forge-std/Test.sol";

// 关于第三方ERC20的测试为P1，暂时先不考虑
contract ProtoDaoPermissionTest is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    // 测试同时设置有限无限白名单，铸造上限应该按照有铸造上限
    function test_createDaoFunding_canvasPermission() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.redeemPoolInputRatio = 10_000;
        param.selfRewardOutputRatio = 10_000;
        param.noPermission = true;
        param.mintableRound = 10;
        param.dailyMintCap = 10_000;

        address[] memory canvasCreators = new address[](3);
        canvasCreators[0] = canvasCreator.addr;
        canvasCreators[1] = canvasCreator2.addr;
        canvasCreators[2] = canvasCreator3.addr;
        bytes32 canvasRoot = getMerkleRoot(canvasCreators);
        address[] memory nftHolders = new address[](1);
        nftHolders[0] = address(_testERC721);
        param.canvasCreatorNFTHolderPasses = nftHolders;
        param.canvasCreatorMerkleRoot = canvasRoot;

        param.canvasCreatorAccounts = new address[](2);
        param.canvasCreatorAccounts[0] = vm.addr(0x5);
        param.canvasCreatorAccounts[1] = vm.addr(0x6);

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr); // 创建Dao

        {
            string memory tokenUri = "test token uri 3";
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            CreateCanvasAndMintNFTParam memory vars;
            vars.daoId = daoId;
            vars.canvasId = "0x1234";
            vars.canvasUri = "test canvas uri 1";
            vars.canvasCreator = canvasCreator.addr;
            vars.tokenUri = tokenUri;
            vars.nftSignature = abi.encodePacked(r, s, v);
            vars.flatPrice = 0.01 ether;
            vars.proof = new bytes32[](0);
            vars.canvasProof = new bytes32[](0);
            vars.nftOwner = address(this);
            vm.expectRevert(NotInWhitelist.selector);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: flatPrice }(vars);
            vars.canvasProof = getMerkleProof(canvasCreators, canvasCreator.addr);
            protocol.mintNFT{ value: flatPrice }(vars);

            _testERC721.mint(vm.addr(0x4), 1);
            vars.canvasProof = new bytes32[](0);
            vars.canvasId = "0x2345";
            vars.canvasUri = "test canvas uri 2";
            vars.tokenUri = "test token uri 4";
            vars.canvasCreator = vm.addr(0x4);
            protocol.mintNFT{ value: flatPrice }(vars);

            _testERC721.mint(vm.addr(0x5), 2);
            vars.canvasId = "0x3456";
            vars.canvasUri = "test canvas uri 3";
            vars.tokenUri = "test token uri 5";
            vars.canvasCreator = vm.addr(0x5);
            vm.expectRevert(Blacklisted.selector);
            protocol.mintNFT{ value: flatPrice }(vars);
        }

        // 设置有限及无限白名单白名单
        // UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](0);
        // NftMinterCapInfo[] memory nftMinterCapInfo = new NftMinterCapInfo[](1);
        // address[] memory unlimited721List = new address[](1);
        // nftMinterCapInfo[0] = NftMinterCapInfo({ nftAddress: nftAddr, nftMintCap: 1 }); // 这个里面加上
        // Whitelist memory whitelist = Whitelist(bytes32(0), unlimited721List); // 这个里面加上
        // Blacklist memory blacklist;
        // Blacklist memory unblacklist;
    }

    function test_nftIdHolder_Permission() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.redeemPoolInputRatio = 10_000;
        param.selfRewardOutputRatio = 10_000;
        param.noPermission = true;
        param.mintableRound = 10;
        param.dailyMintCap = 10_000;

        _testERC721.mint(nftMinter.addr, 1);
        NftMinterCapIdInfo[] memory nftMinterCapIdInfo = new NftMinterCapIdInfo[](1);
        nftMinterCapIdInfo[0] = NftMinterCapIdInfo({ nftAddress: address(_testERC721), tokenId: 1, nftMintCap: 2 });
        // add No.1 token to nft-id whitelist with cap 2
        param.nftMinterCapIdInfo = nftMinterCapIdInfo;

        address[] memory nftHolders = new address[](1);
        nftHolders[0] = address(_testERC721);
        //param.canvasCreatorNFTHolderPasses = nftHolders;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr); // 创建Dao

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "test nft 1";
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;

        super._mintNftRevert(nftParam, randomGuy.addr, ExceedMinterMaxMintAmount.selector);
        super._mintNftWithParam(nftParam, nftMinter.addr);
        nftParam.tokenUri = "test nft 2";
        super._mintNftWithParam(nftParam, nftMinter.addr);
        nftParam.tokenUri = "test nft 3";
        super._mintNftRevert(nftParam, nftMinter.addr, ExceedMinterMaxMintAmount.selector);
        NftIdentifier[] memory nfts = new NftIdentifier[](2);
        // add No.1, No.2 token to minter nft-id whitelist without cap
        // add No.1, No.2 token to canvas nft-id whitelist

        nfts[0] = NftIdentifier({ erc721Address: address(_testERC721), tokenId: 1 });
        nfts[1] = NftIdentifier({ erc721Address: address(_testERC721), tokenId: 2 });
        Whitelist memory whitelist = Whitelist({
            minterMerkleRoot: bytes32(0),
            minterNFTHolderPasses: new address[](0),
            minterNFTIdHolderPasses: nfts,
            canvasCreatorMerkleRoot: bytes32(0),
            canvasCreatorNFTHolderPasses: new address[](0),
            canvasCreatorNFTIdHolderPasses: nfts
        });
        vm.prank(daoCreator.addr);
        protocol.setMintCapAndPermission(
            daoId,
            0,
            new UserMintCapParam[](0),
            new NftMinterCapInfo[](0),
            nftMinterCapIdInfo,
            whitelist,
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) })
        );
        nftParam.tokenUri = "test nft 4";
        super._mintNftRevert(nftParam, nftMinter.addr, ExceedMinterMaxMintAmount.selector);
        _testERC721.mint(nftMinter2.addr, 2);
        super._mintNftWithParam(nftParam, nftMinter2.addr);
        assembly {
            mstore(nftMinterCapIdInfo, 2)
        }
        // add No.3 token to nft-id whitelist with cap 5
        nftMinterCapIdInfo[1] = NftMinterCapIdInfo({ nftAddress: address(_testERC721), tokenId: 3, nftMintCap: 5 });

        vm.prank(daoCreator.addr);
        protocol.setMintCapAndPermission(
            daoId,
            0,
            new UserMintCapParam[](0),
            new NftMinterCapInfo[](0),
            nftMinterCapIdInfo,
            whitelist,
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) })
        );
        _testERC721.mint(nftMinter.addr, 3);
        nftParam.tokenUri = "test nft 5";
        super._mintNftRevert(nftParam, nftMinter.addr, ExceedMinterMaxMintAmount.selector);
        vm.prank(nftMinter.addr);
        _testERC721.transferFrom(nftMinter.addr, randomGuy.addr, 1);
        super._mintNftWithParam(nftParam, nftMinter.addr);
        nftParam.tokenUri = "test nft 6";
        super._mintNftWithParam(nftParam, randomGuy.addr);

        //test canvas creator
        nftParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        nftParam.tokenUri = "test nft 7";
        nftParam.canvasCreator = randomGuy2.addr;
        super._mintNftRevert(nftParam, randomGuy2.addr, NotInWhitelist.selector);
        nftParam.canvasCreator = nftMinter.addr;
        super._mintNftRevert(nftParam, nftMinter.addr, NotInWhitelist.selector);
        nftParam.canvasCreator = nftMinter2.addr;

        super._mintNftWithParam(nftParam, nftMinter2.addr);

        assembly {
            mstore(nfts, 3)
        }
        nfts[2] = NftIdentifier({ erc721Address: address(_testERC721), tokenId: 3 });
        whitelist = Whitelist({
            minterMerkleRoot: bytes32(0),
            minterNFTHolderPasses: new address[](0),
            minterNFTIdHolderPasses: nfts,
            canvasCreatorMerkleRoot: bytes32(0),
            canvasCreatorNFTHolderPasses: new address[](0),
            canvasCreatorNFTIdHolderPasses: nfts
        });
        vm.prank(daoCreator.addr);
        protocol.setMintCapAndPermission(
            daoId,
            0,
            new UserMintCapParam[](0),
            new NftMinterCapInfo[](0),
            nftMinterCapIdInfo,
            whitelist,
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) })
        );
        nftParam.tokenUri = "test nft 8";
        nftParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 2));
        nftParam.canvasCreator = nftMinter.addr;

        super._mintNftWithParam(nftParam, nftMinter.addr);
    }
}
// 0xb8a4d5863e3efce8a356708ceb1ac95651976e5e53b3ae7e197328af00298a15
// 0
// []
// [(0x67C77AB57Eb8646EcE4cbf5245a0e19117FDd307, 1)]
// (0x0000000000000000000000000000000000000000000000000000000000000000, [0x546C2EC200A2aEE1a4a14A1ED7037F48BD07336a],
// 0x0000000000000000000000000000000000000000000000000000000000000000, [])
// ([], [])
// ([], [])

// [(0x67C77AB57Eb8646EcE4cbf5245a0e19117FDd307, 1)]
// (0x0000000000000000000000000000000000000000000000000000000000000000, [0x546C2EC200A2aEE1a4a14A1ED7037F48BD07336a],
// 0x0000000000000000000000000000000000000000000000000000000000000000, [])
