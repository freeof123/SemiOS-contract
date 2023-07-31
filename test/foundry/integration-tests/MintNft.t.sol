// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AConstants.sol";
import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { D4ASettingsReadable } from "contracts/D4ASettings/D4ASettingsReadable.sol";

contract MintNftTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_mintNFT_pay_lower_price_when_canvasRebateRatioInBps_is_set() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.nftMinterERC20RatioInBps = 300;
        createDaoParam.actionType = 16;
        daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
        hoax(nftMinter.addr);
        protocol.mintNFT{ value: price - price * 6750 * 3000 / BASIS_POINT ** 2 }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_RevertIf_mintNFT_with_too_low_price_when_canvasRebateRatioInBps_is_set() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
        vm.expectRevert(NotEnoughEther.selector);
        hoax(nftMinter.addr);
        protocol.mintNFT{ value: price - price * 6750 * 3000 / BASIS_POINT ** 2 - 1 }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_RevertIf_mintNft_when_reward_isProgressiveJackpot_and_exceed_mintable_round() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.isProgressiveJackpot = true;
        daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        drb.changeRound(11);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 10);

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
        vm.expectRevert(ExceedMaxMintableRound.selector);
        hoax(nftMinter.addr);
        protocol.mintNFT{ value: price }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_Mint_ETH_Split() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        daoId = _createDao(createDaoParam);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        (,,, address daoFeePool,,,,) = ID4AProtocolReadable(address(protocol)).getProjectInfo(daoId);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setRatio(daoId, 300, 9500, 0, 9750, 9750);

        deal(D4ASettingsReadable(address(protocol)).protocolFeePool(), 0);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0.01 ether;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        protocol.mintNFT{ value: flatPrice }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
        assertEq(D4ASettingsReadable(address(protocol)).protocolFeePool().balance, 0.01 ether * 250 / 10_000);
        assertEq(daoFeePool.balance, 0.01 ether * 9750 / 10_000);
        assertEq(canvasCreator.addr.balance, 0);
    }

    function test_Batch_mint_ETH_Split() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        daoId = _createDao(createDaoParam);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        (,,, address daoFeePool,,,,) = ID4AProtocolReadable(address(protocol)).getProjectInfo(daoId);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setRatio(daoId, 300, 9500, 0, 9750, 9750);

        deal(D4ASettingsReadable(address(protocol)).protocolFeePool(), 0);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);

        MintNftInfo[] memory mintNftInfos = new MintNftInfo[](10);
        bytes[] memory signatures = new bytes[](10);
        uint256 totalPrice;
        for (uint256 i; i < 10; i++) {
            string memory tokenUri = string.concat("test token uri ", vm.toString(i));
            uint256 flatPrice = 0.01 ether * (i + 1);
            totalPrice += flatPrice;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            mintNftInfos[i] = MintNftInfo(tokenUri, flatPrice);
            signatures[i] = abi.encodePacked(r, s, v);
        }

        hoax(nftMinter.addr);
        protocol.batchMint{ value: totalPrice }(daoId, canvasId, new bytes32[](0), mintNftInfos, signatures);
        assertEq(D4ASettingsReadable(address(protocol)).protocolFeePool().balance, totalPrice * 250 / 10_000);
        assertEq(daoFeePool.balance, totalPrice * 9750 / 10_000);
        assertEq(canvasCreator.addr.balance, 0);
    }
}
