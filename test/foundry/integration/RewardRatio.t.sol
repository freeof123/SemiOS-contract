// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console2} from "forge-std/Console2.sol";
import {DeployHelper} from "../utils/DeployHelper.sol";
import {MintNftSigUtils} from "../utils/MintNftSigUtils.sol";
import {D4ASettingsReadable} from "contracts/D4ASettings/D4ASettingsReadable.sol";
import {ProtoDAOSettings} from "contracts/ProtoDAOSettings/ProtoDAOSettings.sol";

contract RewardRatioTest is DeployHelper {
    MintNftSigUtils public sigUtils;
    bytes32 public daoId;
    bytes32 public canvasId1;
    bytes32 public canvasId2;
    IERC20 public token;
    address public daoFeePool;

    uint256 public protocolFeePoolETHRatio;
    uint256 public daoFeePoolETHRatio;
    uint256 public daoFeePoolETHRatioFlatPrice;
    uint256 public ratioBase;

    uint256 public protocolFeePoolERC20Ratio = 200;
    uint256 public daoFeePoolERC20Ratio = 300;
    uint256 public canvasCreatorERC20Ratio;
    uint256 public nftMinterERC20Ratio;

    function setUp() public {
        setUpEnv();

        protocolFeePoolETHRatio = D4ASettingsReadable(address(protocol)).mintProtocolFeeRatio();
        ratioBase = D4ASettingsReadable(address(protocol)).ratioBase();
        daoFeePoolETHRatio = ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatio(daoId);
        daoFeePoolETHRatioFlatPrice = ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatioFlatPrice(daoId);

        sigUtils = new MintNftSigUtils(address(protocol));

        startHoax(daoCreator.addr);
        daoId = _createTrivialDao(0, 50, 0, 0, 750, "test dao uri");
        (address temp,) = protocol.getProjectTokens(daoId);
        token = IERC20(temp);
        (,,,, daoFeePool,,,,) = protocol.getProjectInfo(daoId);

        startHoax(canvasCreator.addr);
        canvasId1 = protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri 1", new bytes32[](0));

        startHoax(canvasCreator2.addr);
        canvasId2 = protocol.createCanvas{value: 0.01 ether}(daoId, "test canvas uri 2", new bytes32[](0));
    }

    function test_ETH_Ratio() public {
        string memory tokenUri = "test token uri 1";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        _clearETHBalance();

        startHoax(nftMinter.addr);
        uint256 mintPrice = protocol.getCanvasNextPrice(canvasId1);
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        uint256 protocolFee = protocolFeePoolETHRatio * mintPrice / ratioBase;
        uint256 daoFee = daoFeePoolETHRatio * mintPrice / ratioBase;
        assertEq(protocolFeePool.addr.balance, protocolFee);
        assertEq(daoFeePool.balance, daoFee);
        assertEq(canvasCreator.addr.balance, mintPrice - protocolFee - daoFee);

        tokenUri = "test token uri 1 flat price";
        flatPrice = 1 ether;
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        _clearETHBalance();

        startHoax(nftMinter2.addr);
        mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        protocolFee = protocolFeePoolETHRatio * mintPrice / ratioBase;
        daoFee = daoFeePoolETHRatioFlatPrice * mintPrice / ratioBase;
        assertEq(protocolFeePool.addr.balance, protocolFee);
        assertEq(daoFeePool.balance, daoFee);
        assertEq(canvasCreator.addr.balance, mintPrice - protocolFee - daoFee);

        // change ETH ratio
        startHoax(daoCreator.addr);
        daoFeePoolETHRatio = 4_000;
        daoFeePoolETHRatioFlatPrice = 6_000;
        ProtoDAOSettings(address(protocol)).setRatio(daoId, 10_000, 0, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice);

        tokenUri = "test token uri 2";
        flatPrice = 0;
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        _clearETHBalance();

        startHoax(nftMinter.addr);
        mintPrice = protocol.getCanvasNextPrice(canvasId1);
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        protocolFee = protocolFeePoolETHRatio * mintPrice / ratioBase;
        daoFee = daoFeePoolETHRatio * mintPrice / ratioBase;
        assertEq(protocolFeePool.addr.balance, protocolFee);
        assertEq(daoFeePool.balance, daoFee);
        assertEq(canvasCreator.addr.balance, mintPrice - protocolFee - daoFee);

        tokenUri = "test token uri 2 flat price";
        flatPrice = 1 ether;
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        _clearETHBalance();

        startHoax(nftMinter2.addr);
        mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        protocolFee = protocolFeePoolETHRatio * mintPrice / ratioBase;
        daoFee = daoFeePoolETHRatioFlatPrice * mintPrice / ratioBase;
        assertEq(protocolFeePool.addr.balance, protocolFee);
        assertEq(daoFeePool.balance, daoFee);
        assertEq(canvasCreator.addr.balance, mintPrice - protocolFee - daoFee);
    }

    function test_DaoToken_Ratio() public {
        // canvas 1, minter 1: 75%, 25%
        // mint price: 1 ETH
        // canvas 1, minter 2: 60%, 40%
        // mint price: 2 ETH
        // canvas 2, minter 1: 50%, 50%
        // mint price: 4 ETH
        // canvas 2, minter 2: 35%, 65%
        // mint price: 8 ETH

        // set ERC20 ratio to 75% and 20%
        startHoax(daoCreator.addr);
        canvasCreatorERC20Ratio = 7_500;
        nftMinterERC20Ratio = 2_500;
        ProtoDAOSettings(address(protocol)).setRatio(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );

        string memory tokenUri = "test token uri 1";
        uint256 flatPrice = 1 ether;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        startHoax(nftMinter.addr);
        uint256 mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        // set ERC20 ratio to 60% and 35%
        startHoax(daoCreator.addr);
        canvasCreatorERC20Ratio = 6_000;
        nftMinterERC20Ratio = 4_000;
        ProtoDAOSettings(address(protocol)).setRatio(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );

        tokenUri = "test token uri 2";
        flatPrice = 2 ether;
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        startHoax(nftMinter2.addr);
        mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        // set ERC20 ratio to 50% and 45%
        startHoax(daoCreator.addr);
        canvasCreatorERC20Ratio = 5_000;
        nftMinterERC20Ratio = 5_000;
        ProtoDAOSettings(address(protocol)).setRatio(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );

        tokenUri = "test token uri 3";
        flatPrice = 4 ether;
        digest = sigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator2.key, digest);

        startHoax(nftMinter.addr);
        mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId2, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        // set ERC20 ratio to 35% and 60%
        startHoax(daoCreator.addr);
        canvasCreatorERC20Ratio = 3_500;
        nftMinterERC20Ratio = 6_500;
        ProtoDAOSettings(address(protocol)).setRatio(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );

        tokenUri = "test token uri 4";
        flatPrice = 8 ether;
        digest = sigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator2.key, digest);

        startHoax(nftMinter2.addr);
        mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId2, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        drb.changeRound(1);
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        startHoax(nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        startHoax(nftMinter2.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);

        uint256 rewardPerRound = 1e9 * 1e18 / 50;
        uint256 totalWeight = 15 ether;
        uint256 canvasCreator1Weight = (1 ether * 7_500 + 2 ether * 6_000) * 9500 / ratioBase ** 2;
        uint256 canvasCreator2Weight = (4 ether * 5_000 + 8 ether * 3_500) * 9500 / ratioBase ** 2;
        uint256 nftMinter1Weight = (1 ether * 2_500 + 4 ether * 5_000) * 9500 / ratioBase ** 2;
        uint256 nftMinter2Weight = (2 ether * 4_000 + 8 ether * 6_500) * 9500 / ratioBase ** 2;
        assertEq(
            token.balanceOf(protocolFeePool.addr), rewardPerRound * protocolFeePoolERC20Ratio / ratioBase, "protocol"
        );
        assertEq(token.balanceOf(daoCreator.addr), rewardPerRound * daoFeePoolERC20Ratio / ratioBase, "dao");
        assertEq(
            token.balanceOf(canvasCreator.addr), rewardPerRound * canvasCreator1Weight / totalWeight, "canvas creator 1"
        );
        assertEq(
            token.balanceOf(canvasCreator2.addr),
            rewardPerRound * canvasCreator2Weight / totalWeight,
            "canvas creator 2"
        );
        assertEq(token.balanceOf(nftMinter.addr), rewardPerRound * nftMinter1Weight / totalWeight, "minter 1");
        assertEq(token.balanceOf(nftMinter2.addr), rewardPerRound * nftMinter2Weight / totalWeight, "minter 2");
    }

    function test_DAO_Token_To_ETH_Ratio() public {
        // canvas 1, minter 1: 75%, 25%
        // mint price: 1 ETH
        // canvas 1, minter 2: 60%, 40%
        // mint price: 2 ETH
        // canvas 2, minter 1: 50%, 50%
        // mint price: 4 ETH
        // canvas 2, minter 2: 35%, 65%
        // mint price: 8 ETH

        // set ERC20 ratio to 75% and 20%
        startHoax(daoCreator.addr);
        canvasCreatorERC20Ratio = 7_500;
        nftMinterERC20Ratio = 2_500;
        ProtoDAOSettings(address(protocol)).setRatio(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );

        string memory tokenUri = "test token uri 1";
        uint256 flatPrice = 1 ether;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        startHoax(nftMinter.addr);
        uint256 mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        // set ERC20 ratio to 60% and 35%
        startHoax(daoCreator.addr);
        canvasCreatorERC20Ratio = 6_000;
        nftMinterERC20Ratio = 4_000;
        ProtoDAOSettings(address(protocol)).setRatio(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );

        tokenUri = "test token uri 2";
        flatPrice = 2 ether;
        digest = sigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator.key, digest);

        startHoax(nftMinter2.addr);
        mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId1, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        // set ERC20 ratio to 50% and 45%
        startHoax(daoCreator.addr);
        canvasCreatorERC20Ratio = 5_000;
        nftMinterERC20Ratio = 5_000;
        ProtoDAOSettings(address(protocol)).setRatio(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );

        tokenUri = "test token uri 3";
        flatPrice = 4 ether;
        digest = sigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator2.key, digest);

        startHoax(nftMinter.addr);
        mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId2, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        // set ERC20 ratio to 35% and 60%
        startHoax(daoCreator.addr);
        canvasCreatorERC20Ratio = 3_500;
        nftMinterERC20Ratio = 6_500;
        ProtoDAOSettings(address(protocol)).setRatio(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );

        tokenUri = "test token uri 4";
        flatPrice = 8 ether;
        digest = sigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
        (v, r, s) = vm.sign(canvasCreator2.key, digest);

        startHoax(nftMinter2.addr);
        mintPrice = flatPrice;
        protocol.mintNFT{value: mintPrice}(
            daoId, canvasId2, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );

        _clearETHBalance();
        uint256 daoFeePoolETH = 10 ether;
        deal(daoFeePool, daoFeePoolETH);

        drb.changeRound(1);
        hoax(daoCreator.addr, 0);
        protocol.claimProjectERC20RewardWithETH(daoId);
        hoax(canvasCreator.addr, 0);
        protocol.claimCanvasRewardWithETH(canvasId1);
        hoax(canvasCreator2.addr, 0);
        protocol.claimCanvasRewardWithETH(canvasId2);
        startHoax(nftMinter.addr, 0);
        protocol.claimNftMinterRewardWithETH(daoId, nftMinter.addr);
        startHoax(nftMinter2.addr, 0);
        protocol.claimNftMinterRewardWithETH(daoId, nftMinter2.addr);

        uint256 totalWeight = 15 ether;
        uint256 canvasCreator1Weight = (1 ether * 7_500 + 2 ether * 6_000) * 9500 / ratioBase ** 2;
        uint256 canvasCreator2Weight = (4 ether * 5_000 + 8 ether * 3_500) * 9500 / ratioBase ** 2;
        uint256 nftMinter1Weight = (1 ether * 2_500 + 4 ether * 5_000) * 9500 / ratioBase ** 2;
        uint256 nftMinter2Weight = (2 ether * 4_000 + 8 ether * 6_500) * 9500 / ratioBase ** 2;
        assertEq(daoCreator.addr.balance, daoFeePoolETH * daoFeePoolERC20Ratio / ratioBase, "dao");
        assertEq(canvasCreator.addr.balance, daoFeePoolETH * canvasCreator1Weight / totalWeight, "canvas creator 1");
        assertEq(canvasCreator2.addr.balance, daoFeePoolETH * canvasCreator2Weight / totalWeight, "canvas creator 2");
        assertEq(nftMinter.addr.balance, daoFeePoolETH * nftMinter1Weight / totalWeight, "minter 1");
        assertEq(nftMinter2.addr.balance, daoFeePoolETH * nftMinter2Weight / totalWeight, "minter 2");
    }

    function _clearETHBalance() internal {
        deal(protocolFeePool.addr, 0);
        deal(daoFeePool, 0);
        deal(daoCreator.addr, 0);
        deal(canvasCreator.addr, 0);
        deal(canvasCreator2.addr, 0);
        deal(nftMinter.addr, 0);
        deal(nftMinter2.addr, 0);
    }
}
