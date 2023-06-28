// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployHelper } from "../utils/DeployHelper.sol";
import { MintNftSigUtils } from "../utils/MintNftSigUtils.sol";

contract CreateDaoTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_createDao_WithZeroFloorPrice() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 9999, 0, 750, "test project uri");

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);
        string memory tokenUri = "test nft uri";
        MintNftSigUtils sigUtils = new MintNftSigUtils(address(protocol));
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, 0);

        bytes memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signature = bytes.concat(r, s, bytes1(v));
        }

        assertEq(protocol.getCanvasNextPrice(canvasId), 0);

        hoax(nftMinter.addr);
        protocol.mintNFT(daoId, canvasId, tokenUri, new bytes32[](0), 0, signature);

        assertEq(protocol.getCanvasNextPrice(canvasId), 0);
    }
}
