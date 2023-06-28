// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { PriceTemplateType, RewardTemplateType } from "contracts/interface/D4AEnums.sol";
import {
    DaoMetadataParam,
    DaoMintCapParam,
    UserMintCapParam,
    DaoETHAndERC20SplitRatioParam,
    TemplateParam,
    MintNftInfo
} from "contracts/interface/D4AStructs.sol";

import "forge-std/Test.sol";
import { DeployHelper } from "./utils/DeployHelper.sol";
import { D4AProtocol } from "contracts/D4AProtocol.sol";
import { MintNftSigUtils } from "./utils/MintNftSigUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
import { D4ACreateProjectProxy } from "contracts/proxy/D4ACreateProjectProxy.sol";

contract Benchmark is DeployHelper {
    using Strings for uint256;

    bytes32 public daoId;
    bytes32 public canvasId;
    IERC721 public nft;
    address public daoFeePool;
    MintNftSigUtils public sigUtils;
    uint256 protocolFeePoolBalance;

    function setUp() public {
        setUpEnv();

        drb.changeRound(1);
        sigUtils = new MintNftSigUtils(
            address(protocol)
        );
        vm.deal(nftMinter.addr, 1e30 ether);

        hoax(daoCreator.addr, 0.1 ether);
        uint256 startDrb = drb.currentRound();
        daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: startDrb,
                mintableRounds: 30,
                floorPriceRank: 0,
                maxNftRank: 0,
                royaltyFee: 750,
                projectUri: "test dao uri",
                projectIndex: 0
            }),
            IPermissionControl.Whitelist(bytes32(0), new address[](0), bytes32(0), new address[](0)),
            IPermissionControl.Blacklist(new address[](0), new address[](0)),
            DaoMintCapParam(0, new UserMintCapParam[](0)),
            DaoETHAndERC20SplitRatioParam(0, 0, 0, 0),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                rewardDecayLife: 1,
                isProgressiveJackpot: false
            }),
            0
        );
        {
            (,,, daoFeePool,,,,) = protocol.getProjectInfo(daoId);
        }
        (, address erc721Token) = protocol.getProjectTokens(daoId);
        nft = IERC721(erc721Token);

        hoax(canvasCreator.addr, 0.01 ether);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas", new bytes32[](0), 0);
        protocolFeePoolBalance = protocolFeePool.addr.balance;
    }

    function _mintOne() internal noGasMetering {
        // mint one to set base line
        vm.startPrank(nftMinter.addr);
        bytes32[] memory proof = new bytes32[](0);
        string memory tokenUri = "test token premint";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);

        bytes memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signature = bytes.concat(r, s, bytes1(v));
        }
        uint256 value = 0.01 ether;
        protocol.mintNFT{ value: value }(daoId, canvasId, tokenUri, proof, flatPrice, signature);
        vm.stopPrank();
        protocolFeePoolBalance = protocolFeePool.addr.balance;
    }

    function test_Mint_One() public {
        _mintOne();

        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        bytes32[] memory proof = new bytes32[](0);
        string memory tokenUri = "test token 1";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);

        bytes memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signature = bytes.concat(r, s, bytes1(v));
        }
        uint256 value = 0.02 ether;
        protocol.mintNFT{ value: value }(daoId, canvasId, tokenUri, proof, flatPrice, signature);
        assertEq(nft.balanceOf(nftMinter.addr), 2);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = (value * 3000) / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.04 ether);
        vm.stopPrank();
    }

    function test_Mint_Five() public {
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](5);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](5);
        uint256[] memory flatPrices = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), 5);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = (value * 3000) / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 5));
        vm.stopPrank();
    }

    function _getTotalPrice(uint256[] memory flatPrices) internal pure returns (uint256 totalPrice) {
        uint256 initialPrice = 0.01 ether;
        uint256 counter = 0;
        for (uint256 i = 0; i < flatPrices.length; i++) {
            totalPrice += flatPrices[i] == 0 ? initialPrice * (2 ** counter++) : flatPrices[i];
        }
    }

    function _getDaoFeePoolShare(uint256[] memory flatPrices) internal pure returns (uint256 daoFeePoolShare) {
        uint256 initialPrice = 0.01 ether;
        uint256 counter = 0;
        for (uint256 i = 0; i < flatPrices.length; i++) {
            uint256 price = flatPrices[i] == 0 ? initialPrice * (2 ** counter++) : flatPrices[i];
            uint256 ratio = flatPrices[i] == 0 ? 3000 : 3500;
            daoFeePoolShare += price * ratio;
        }
    }

    function test_Mint_Five_With_One_FlatPrice() public {
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](5);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](5);
        uint256[] memory flatPrices = new uint256[](5);
        flatPrices[0] = 1 ether;
        for (uint256 i = 0; i < 5; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        uint256 daoFeePoolShare = _getDaoFeePoolShare(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), 5);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = daoFeePoolShare / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 4));
        vm.stopPrank();
    }

    function test_Mint_Five_With_Two_FlatPrice() public {
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](5);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](5);
        uint256[] memory flatPrices = new uint256[](5);
        flatPrices[0] = 1 ether;
        flatPrices[1] = 3 ether;
        for (uint256 i = 0; i < 5; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        uint256 daoFeePoolShare = _getDaoFeePoolShare(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), 5);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = daoFeePoolShare / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 3));

        vm.stopPrank();
    }

    function test_Mint_Five_With_Three_FlatPrice() public {
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](5);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](5);
        uint256[] memory flatPrices = new uint256[](5);
        flatPrices[0] = 1 ether;
        flatPrices[1] = 3 ether;
        flatPrices[2] = 7 ether;
        for (uint256 i = 0; i < 5; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        uint256 daoFeePoolShare = _getDaoFeePoolShare(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), 5);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = daoFeePoolShare / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 2));
        vm.stopPrank();
    }

    function test_Mint_Five_With_Four_FlatPrice() public {
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](5);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](5);
        uint256[] memory flatPrices = new uint256[](5);
        flatPrices[0] = 1 ether;
        flatPrices[1] = 3 ether;
        flatPrices[2] = 7 ether;
        flatPrices[3] = 101 ether;
        for (uint256 i = 0; i < 5; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        uint256 daoFeePoolShare = _getDaoFeePoolShare(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), 5);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = daoFeePoolShare / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 1));
        vm.stopPrank();
    }

    function test_Mint_Five_With_Five_FlatPrice() public {
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](5);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](5);
        uint256[] memory flatPrices = new uint256[](5);
        flatPrices[0] = 1 ether;
        flatPrices[1] = 3 ether;
        flatPrices[2] = 7 ether;
        flatPrices[3] = 101 ether;
        flatPrices[4] = 647 ether;
        for (uint256 i = 0; i < 5; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        uint256 daoFeePoolShare = _getDaoFeePoolShare(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), 5);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = daoFeePoolShare / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 0));
        vm.stopPrank();
    }

    function test_Mint_Ten() public {
        uint256 mintNum = 10;
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](mintNum);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](mintNum);
        uint256[] memory flatPrices = new uint256[](mintNum);
        for (uint256 i = 0; i < mintNum; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), mintNum);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = (value * 3000) / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 10));
        vm.stopPrank();
    }

    function test_Mint_Fifty() public {
        uint256 mintNum = 50;
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](mintNum);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](mintNum);
        uint256[] memory flatPrices = new uint256[](mintNum);
        for (uint256 i = 0; i < mintNum; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), mintNum);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = (value * 3000) / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 50));
        vm.stopPrank();
    }

    function test_Mint_One_Hundred() public {
        uint256 mintNum = 100;
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](mintNum);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](mintNum);
        uint256[] memory flatPrices = new uint256[](mintNum);
        for (uint256 i = 0; i < mintNum; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), mintNum);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = (value * 3000) / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** 100));
        vm.stopPrank();
    }

    function testFuzz_Mint(uint256 mintNum) public {
        vm.assume(mintNum <= 100);
        uint256 daoFeePoolBalance = daoFeePool.balance;
        uint256 canvasCreatorBalance = canvasCreator.addr.balance;
        vm.startPrank(nftMinter.addr);
        MintNftInfo[] memory nftInfos = new MintNftInfo[](mintNum);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory signatures = new bytes[](mintNum);
        uint256[] memory flatPrices = new uint256[](mintNum);
        for (uint256 i = 0; i < mintNum; i++) {
            string memory tokenUri = string.concat("test token ", i.toString());
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrices[i]);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signatures[i] = bytes.concat(r, s, bytes1(v));
            nftInfos[i] = MintNftInfo({ tokenUri: tokenUri, flatPrice: flatPrices[i] });
        }
        uint256 value = _getTotalPrice(flatPrices);
        protocol.batchMint{ value: value }(daoId, canvasId, proof, nftInfos, signatures);
        assertEq(nft.balanceOf(nftMinter.addr), mintNum);
        uint256 protocolFee = (value * 250) / 10_000;
        uint256 daoFee = (value * 3000) / 10_000;
        uint256 canvasFee = value - protocolFee - daoFee;
        assertEq(protocolFeePool.addr.balance, protocolFeePoolBalance + protocolFee);
        assertEq(daoFeePool.balance, daoFeePoolBalance + daoFee);
        assertEq(canvasCreator.addr.balance, canvasCreatorBalance + canvasFee);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether * (2 ** mintNum));
        vm.stopPrank();
    }

    receive() external payable { }
}
