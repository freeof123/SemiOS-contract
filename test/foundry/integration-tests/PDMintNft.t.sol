// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { NotInWhitelist, ExceedMinterMaxMintAmount } from "contracts/interface/D4AErrors.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";

contract PDMintNftTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_RevertIf_NoNftAsPass() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        bytes32 canvasId = param.canvasId;
        string memory tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        );
        uint256 flatPrice = 0.01 ether;
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
        vm.expectRevert(ExceedMinterMaxMintAmount.selector);
        hoax(nftMinter.addr);
        protocol.mintNFT{ value: flatPrice }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_CanOnlyMintFiveNfts() public {
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

        // 在新的逻辑中，在以上参数传递的情况下，这个地方应该是可以铸造超过5个的，所以注释掉下面的selector (不是)
        // 目前逻辑，minter为dao creator，在白名单中，受有铸造上次白名单影响（deployhelper里会把creator以5上限加入有铸造上限白名单中（userMintCapParams））
        vm.expectRevert(ExceedMinterMaxMintAmount.selector);
        vm.prank(daoCreator.addr);
        protocol.mintNFT{ value: flatPrice }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_CanMintOnceHaveNft() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        {
            bytes32 canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            );
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            vm.expectRevert(ExceedMinterMaxMintAmount.selector);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: flatPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

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
        {
            address nft = protocol.getDaoNft(daoId);
            vm.prank(daoCreator.addr);
            D4AERC721(nft).safeTransferFrom(daoCreator.addr, nftMinter.addr, 1);
        }

        _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
    }

    function test_PreuploadedWorksShouldOccupy1to1000TokenIds() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 tokenId = _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr
        );
        assertEq(tokenId, 1);
        {
            address nft = protocol.getDaoNft(daoId);
            vm.prank(daoCreator.addr);
            D4AERC721(nft).safeTransferFrom(daoCreator.addr, nftMinter.addr, 1);
        }

        tokenId = _mintNft(daoId, param.canvasId, "test token uri 1", 0.01 ether, daoCreator.key, nftMinter.addr);
        assertEq(tokenId, 1001);
        tokenId = _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(tokenId, 2);
        tokenId = _mintNft(daoId, param.canvasId, "test token uri 2", 0.01 ether, daoCreator.key, nftMinter.addr);
        assertEq(tokenId, 1002);
        tokenId = _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(5)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(tokenId, 3);
        tokenId = _mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(6)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        assertEq(tokenId, 4);
    }
}
