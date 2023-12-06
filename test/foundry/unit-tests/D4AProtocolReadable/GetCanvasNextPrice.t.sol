// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { FixedPointMathLib as Math } from "solmate/utils/FixedPointMathLib.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";

contract GetCanvasNextPriceTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }
}
//     function test_linear_price_variation() public {
//         DeployHelper.CreateDaoParam memory createDaoParam;
//         createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
//         createDaoParam.priceFactor = 0.0069 ether;
//         daoId = _createDao(createDaoParam);

//         drb.changeRound(1);
//         hoax(canvasCreator.addr);
//         canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

//         drb.changeRound(3);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.005 ether);

//         {
//             string memory tokenUri = "test token uri";
//             uint256 flatPrice = 0;
//             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
//             uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
//             hoax(nftMinter.addr);
//             protocol.mintNFT{ value: price }(
//                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
//             );
//         }

//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.01 ether);

//         {
//             string memory tokenUri = "test token uri 2";
//             uint256 flatPrice = 0;
//             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
//             uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
//             hoax(nftMinter.addr);
//             protocol.mintNFT{ value: price }(
//                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
//             );
//         }

//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0169 ether);

//         {
//             string memory tokenUri = "test token uri 3";
//             uint256 flatPrice = 0;
//             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
//             uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
//             hoax(nftMinter.addr);
//             protocol.mintNFT{ value: price }(
//                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
//             );
//         }

//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0238 ether);

//         drb.changeRound(4);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0169 ether);
//         drb.changeRound(5);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.01 ether);
//     }

//     function test_linear_price_variation_three_canvases() public {
//         DeployHelper.CreateDaoParam memory createDaoParam;
//         createDaoParam.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
//         createDaoParam.priceFactor = 0.0399 ether;
//         daoId = _createDao(createDaoParam);

//         drb.changeRound(1);
//         hoax(canvasCreator.addr);
//         canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0), 3000);
//         hoax(canvasCreator2.addr);
//         bytes32 canvasId2 =
//             protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 3000);
//         hoax(canvasCreator3.addr);
//         bytes32 canvasId3 =
//             protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 3000);

//         drb.changeRound(3);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.005 ether);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.005 ether);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId3), 0.005 ether);

//         {
//             string memory tokenUri = "test token uri";
//             uint256 flatPrice = 0;
//             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
//             uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
//             hoax(nftMinter.addr);
//             protocol.mintNFT{ value: price }(
//                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
//             );
//         }

//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.01 ether);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.01 ether);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId3), 0.01 ether);

//         {
//             string memory tokenUri = "test token uri 2";
//             uint256 flatPrice = 0;
//             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
//             uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
//             hoax(nftMinter.addr);
//             protocol.mintNFT{ value: price }(
//                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
//             );
//         }

//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0499 ether);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.01 ether);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId3), 0.01 ether);

//         hoax(daoCreator.addr);
//         D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.02 ether);

//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.0499 ether);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId2), 0.02 ether);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId3), 0.02 ether);
//     }

//     function test_exponential_price_variation() public {
//         DeployHelper.CreateDaoParam memory createDaoParam;
//         createDaoParam.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
//         createDaoParam.priceFactor = 12_345;
//         daoId = _createDao(createDaoParam);

//         drb.changeRound(1);
//         hoax(canvasCreator.addr);
//         canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

//         drb.changeRound(3);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.005 ether);

//         {
//             string memory tokenUri = "test token uri";
//             uint256 flatPrice = 0;
//             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
//             uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
//             hoax(nftMinter.addr);
//             protocol.mintNFT{ value: price }(
//                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
//             );
//         }

//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.01 ether);

//         {
//             string memory tokenUri = "test token uri 2";
//             uint256 flatPrice = 0;
//             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
//             uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
//             hoax(nftMinter.addr);
//             protocol.mintNFT{ value: price }(
//                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
//             );
//         }

//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.012345 ether);

//         {
//             string memory tokenUri = "test token uri 3";
//             uint256 flatPrice = 0;
//             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
//             uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
//             hoax(nftMinter.addr);
//             protocol.mintNFT{ value: price }(
//                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
//             );
//         }

//         drb.changeRound(4);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.012345 ether);
//         drb.changeRound(5);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.01 ether);
//         drb.changeRound(6);
//         assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.005 ether);
//     }
// }
