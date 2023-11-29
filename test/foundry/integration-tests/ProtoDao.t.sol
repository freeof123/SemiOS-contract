// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam, CreateCanvasAndMintNFTParam } from "contracts/interface/D4AStructs.sol";
import { ExceedMinterMaxMintAmount } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

contract ProtoDaoTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_DaoCreatorMintDefaultGeneratedWork() public {
        vm.skip(true);
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        assertEq(protocol.getDaoMintableRound(daoId), 60);

        address[] memory accounts = new address[](1);
        accounts[0] = daoCreator.addr;
        _mintNftWithProof(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr,
            getMerkleProof(accounts, daoCreator.addr)
        );
        assertEq(protocol.protocolFeePool().balance, 0.00025 ether);
        assertEq(protocol.getDaoFeePool(daoId).balance, 0.00975 ether);
        assertEq(D4AFeePool(payable(protocol.getDaoFeePool(daoId))).turnover(), 0.00975 ether);

        drb.changeRound(2);
        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(param.canvasId);
        protocol.claimNftMinterReward(daoId, daoCreator.addr);

        IERC20 token = IERC20(protocol.getDaoToken(daoId));
        assertEq(token.totalSupply(), 833_333_333_333_333_333_333_333);
        assertEq(token.balanceOf(protocol.protocolFeePool()), 16_666_666_666_666_666_666_666);
        assertEq(token.balanceOf(daoCreator.addr), 816_666_666_666_666_666_666_665);
    }

    function test_NFTHolderNotAllowedToMintAfterFiveMints() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr
        );
        _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr
        );
        _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr
        );
        _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(4)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr
        );
        _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(5)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr
        );

        bytes32 canvasId = param.canvasId;
        string memory tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(6)), ".json"
        );
        uint256 flatPrice = 0.01 ether;
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);

        // 在新的逻辑中，在以上参数传递的情况下，这个地方应该是可以铸造超过5个的，所以注释掉下面的selector
        //同理，不需要注释，
        vm.expectRevert(ExceedMinterMaxMintAmount.selector);

        vm.prank(daoCreator.addr);
        protocol.mintNFT{ value: flatPrice }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_ERC20ShouldSplitCorrectlyWhenThreeWorksUploadedByTwoAddressesAreMintedInSameRound() public {
        vm.skip(true);

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        address[] memory accounts = new address[](1);
        accounts[0] = daoCreator.addr;
        _mintNftWithProof(
            daoId,
            param.canvasId,
            "test token uri 1",
            0.01 ether,
            daoCreator.key,
            daoCreator.addr,
            getMerkleProof(accounts, daoCreator.addr)
        );
        address nft = protocol.getDaoNft(daoId);
        vm.prank(daoCreator.addr);
        D4AERC721(nft).safeTransferFrom(daoCreator.addr, nftMinter.addr, 1001);

        drb.changeRound(2);

        bytes32 canvasId1 = keccak256(abi.encode(canvasCreator.addr, block.timestamp));
        bytes32 canvasId2 = keccak256(abi.encode(canvasCreator2.addr, block.timestamp));

        {
            string memory tokenUri = "test token uri 2";
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            CreateCanvasAndMintNFTParam memory vars;
            vars.daoId = daoId;
            vars.canvasId = canvasId1;
            vars.canvasUri = "test canvas uri 1";
            vars.to = canvasCreator.addr;
            vars.tokenUri = tokenUri;
            vars.signature = abi.encodePacked(r, s, v);
            vars.flatPrice = 0.01 ether;
            vars.proof = new bytes32[](0);
            vars.canvasProof = new bytes32[](0);
            vars.nftOwner = address(this);
            hoax(nftMinter.addr);
            protocol.createCanvasAndMintNFT{ value: flatPrice }(vars);
        }
        {
            string memory tokenUri = "test token uri 3";
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator2.key, digest);
            CreateCanvasAndMintNFTParam memory vars;
            vars.daoId = daoId;
            vars.canvasId = canvasId2;
            vars.canvasUri = "test canvas uri 2";
            vars.to = canvasCreator2.addr;
            vars.tokenUri = tokenUri;
            vars.signature = abi.encodePacked(r, s, v);
            vars.flatPrice = 0.01 ether;
            vars.proof = new bytes32[](0);
            vars.canvasProof = new bytes32[](0);
            vars.nftOwner = address(this);
            hoax(nftMinter.addr);
            protocol.createCanvasAndMintNFT{ value: flatPrice }(vars);
        }
        _mintNft(daoId, canvasId2, "test token uri 4", 0.01 ether, canvasCreator2.key, nftMinter.addr);

        drb.changeRound(3);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(param.canvasId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, daoCreator.addr);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);

        IERC20 token = IERC20(protocol.getDaoToken(daoId));
        assertEq(token.balanceOf(protocolFeePool.addr), 33_333_333_333_333_333_333_332);
        assertEq(token.balanceOf(daoCreator.addr), 1_216_666_666_666_666_666_666_664);
        assertEq(token.balanceOf(canvasCreator.addr), 69_444_444_444_444_444_444_444);
        assertEq(token.balanceOf(canvasCreator2.addr), 138_888_888_888_888_888_888_888);
        assertEq(token.balanceOf(nftMinter.addr), 208_333_333_333_333_333_333_333);
    }

    function test_ERC20ShouldSplitCorrectlyWhenFiveWorksUploadedByTwoAddressesAreMintedInSameRound() public {
        vm.skip(true);

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isProgressiveJackpot = true;
        bytes32 daoId = _createBasicDao(param);

        address[] memory accounts = new address[](1);
        accounts[0] = daoCreator.addr;
        _mintNftWithProof(
            daoId,
            param.canvasId,
            "test token uri 1",
            0.01 ether,
            daoCreator.key,
            daoCreator.addr,
            getMerkleProof(accounts, daoCreator.addr)
        );
        _mintNftWithProof(
            daoId,
            param.canvasId,
            "test token uri 2",
            0.01 ether,
            daoCreator.key,
            daoCreator.addr,
            getMerkleProof(accounts, daoCreator.addr)
        );
        address nft = protocol.getDaoNft(daoId);
        vm.prank(daoCreator.addr);
        D4AERC721(nft).safeTransferFrom(daoCreator.addr, nftMinter.addr, 1001);
        vm.prank(daoCreator.addr);
        D4AERC721(nft).safeTransferFrom(daoCreator.addr, nftMinter2.addr, 1002);

        drb.changeRound(3);

        bytes32 canvasId1 = keccak256(abi.encode(canvasCreator.addr, block.timestamp));
        bytes32 canvasId2 = keccak256(abi.encode(canvasCreator2.addr, block.timestamp));

        {
            string memory tokenUri = "test token uri 3";
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            CreateCanvasAndMintNFTParam memory vars;
            vars.daoId = daoId;
            vars.canvasId = canvasId1;
            vars.canvasUri = "test canvas uri 1";
            vars.to = canvasCreator.addr;
            vars.tokenUri = tokenUri;
            vars.signature = abi.encodePacked(r, s, v);
            vars.flatPrice = 0.01 ether;
            vars.proof = new bytes32[](0);
            vars.canvasProof = new bytes32[](0);
            vars.nftOwner = address(this);
            hoax(nftMinter.addr);

            protocol.createCanvasAndMintNFT{ value: flatPrice }(vars);
        }
        _mintNft(daoId, canvasId1, "test token uri 4", 0.01 ether, canvasCreator.key, nftMinter.addr);
        {
            string memory tokenUri = "test token uri 5";
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator2.key, digest);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory vars;
            vars.daoId = daoId;
            vars.canvasId = canvasId2;
            vars.canvasUri = "test canvas uri 2";
            vars.to = canvasCreator2.addr;
            vars.tokenUri = tokenUri;
            vars.signature = abi.encodePacked(r, s, v);
            vars.flatPrice = flatPrice;
            vars.proof = new bytes32[](0);
            vars.canvasProof = new bytes32[](0);
            vars.nftOwner = address(this);

            protocol.createCanvasAndMintNFT{ value: flatPrice }(vars);
        }
        _mintNft(daoId, canvasId1, "test token uri 6", 0.01 ether, canvasCreator.key, nftMinter2.addr);
        _mintNft(daoId, canvasId2, "test token uri 7", 0.01 ether, canvasCreator2.key, nftMinter2.addr);

        drb.changeRound(4);

        // claim问题
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(param.canvasId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, daoCreator.addr);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);

        IERC20 token = IERC20(protocol.getDaoToken(daoId));
        assertEq(token.balanceOf(protocolFeePool.addr), 49_999_999_999_999_999_999_999);
        assertEq(token.balanceOf(daoCreator.addr), 1_616_666_666_666_666_666_666_664);
        assertEq(token.balanceOf(canvasCreator.addr), 249_999_999_999_999_999_999_999);
        assertEq(token.balanceOf(canvasCreator2.addr), 166_666_666_666_666_666_666_666);
        assertEq(token.balanceOf(nftMinter.addr), 249_999_999_999_999_999_999_999);
        assertEq(token.balanceOf(nftMinter2.addr), 166_666_666_666_666_666_666_666);
    }

    function test_ShouldIncreaseDaoTurnoverAfterTransferETHIntoDaoFeePool() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        D4AFeePool daoFeePool = D4AFeePool(payable(protocol.getDaoFeePool(daoId)));
        assertEq(daoFeePool.turnover(), 0);
        assertEq(protocol.ableToUnlock(daoId), false);

        hoax(randomGuy.addr);
        (bool succ,) = address(daoFeePool).call{ value: 2 ether }("");
        require(succ);

        assertEq(daoFeePool.turnover(), 2 ether);
        assertEq(protocol.ableToUnlock(daoId), true);
    }

    function test_MintWithSameSpecialTokenUriAtTheSameTimeShouldProduceTwoNfts() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        address[] memory accounts = new address[](1);
        accounts[0] = daoCreator.addr;
        _mintNftWithProof(
            daoId,
            param.canvasId,
            string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1", ".json"),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr,
            getMerkleProof(accounts, daoCreator.addr)
        );
        _mintNftWithProof(
            daoId,
            param.canvasId,
            string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1", ".json"),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr,
            getMerkleProof(accounts, daoCreator.addr)
        );
        D4AERC721 nft = D4AERC721(protocol.getDaoNft(daoId));
        assertEq(nft.balanceOf(daoCreator.addr), 2);
        assertEq(
            nft.tokenURI(1), string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1", ".json")
        );
        assertEq(
            nft.tokenURI(2), string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "2", ".json")
        );
    }
}