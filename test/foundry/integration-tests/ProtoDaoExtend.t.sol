// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam } from "contracts/interface/D4AStructs.sol";
import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoTestExtend is DeployHelper {
  function setUp() public {
    super.setUpEnv();
  }

  function test_PDCreateFunding_createContinuousDAO_erc20_two_mint_with_same_price() public {
    DeployHelper.CreateDaoParam memory param;
    param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    bytes32 canvasId1 = param.canvasId;
    param.existDaoId = bytes32(0);
    param.isBasicDao = true;
    bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

    param.daoUri = "continuous dao uri";
    param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
    bytes32 canvasId2 = param.canvasId;

    param.isBasicDao = false;
    param.existDaoId = daoId;

    bytes32 subDaoId = super._createDaoForFunding(param, daoCreator2.addr);

    param.daoUri = "continuous dao uri2";
    param.canvasId = keccak256(abi.encode(daoCreator3.addr, block.timestamp));
    bytes32 canvasId3 = param.canvasId;

    param.isBasicDao = false;
    param.existDaoId = daoId;
    param.childrenDaoId = new bytes32[](2);
    param.childrenDaoId[0] = daoId;
    param.childrenDaoId[1] = subDaoId;
    param.childrenDaoRatiosERC20 = new uint256[](2);
    param.childrenDaoRatiosERC20[0] = 4000;
    param.childrenDaoRatiosERC20[1] = 3000;
    param.childrenDaoRatiosETH = new uint256[](2);
    param.childrenDaoRatiosETH[0] = 1000;
    param.childrenDaoRatiosETH[1] = 2000;
    param.redeemPoolRatioETH = 3000;
    param.selfRewardRatioERC20 = 2000;
    param.selfRewardRatioETH = 3500;

    param.noPermission = true;
    param.mintableRound = 10;

    bytes32 subDaoId2 = super._createDaoForFunding(param, daoCreator3.addr);
    hoax(daoCreator.addr);
    protocol.setInitialTokenSupplyForSubDao(subDaoId2, 10_000_000 ether);
    uint256 flatPrice = 0.01 ether;
    super._mintNftDaoFunding(
      subDaoId2,
      canvasId3,
      string.concat(
        tokenUriPrefix,
        vm.toString(protocol.getDaoIndex(subDaoId2)),
        "-",
        vm.toString(uint256(0)),
        ".json"
      ),
      flatPrice,
      daoCreator3.key,
      nftMinter.addr
    );
    super._mintNftDaoFunding(
      subDaoId2,
      canvasId3,
      string.concat(
        tokenUriPrefix,
        vm.toString(protocol.getDaoIndex(subDaoId2)),
        "-",
        vm.toString(uint256(1)),
        ".json"
      ),
      flatPrice,
      daoCreator3.key,
      nftMinter2.addr
    );

    //10_000_000 ether - 900_000 ether;
    address assetPool3 = protocol.getDaoAssetPool(subDaoId2);
    address assetPool1 = protocol.getDaoAssetPool(daoId);
    address assetPool2 = protocol.getDaoAssetPool(subDaoId);

    address token = protocol.getDaoToken(subDaoId2);
    assertEq(token, protocol.getDaoToken(daoId));
    assertEq(IERC20(token).balanceOf(assetPool3), 10_000_000 ether - 900_000 ether);
    assertEq(IERC20(token).balanceOf(assetPool1), 50_000_000 ether + 400_000 ether);
    assertEq(IERC20(token).balanceOf(assetPool2), 300_000 ether);
    assertEq(IERC20(token).balanceOf(address(protocol)), 200_000 ether);

    drb.changeRound(2);

    protocol.claimDaoCreatorRewardFunding(subDaoId2);
    //1000000 * 20% * 70%
    assertEq(IERC20(token).balanceOf(daoCreator3.addr), 140_000 ether);

    //add 1000000 * 20% * 20%
    protocol.claimCanvasRewardFunding(canvasId3);
    assertEq(IERC20(token).balanceOf(daoCreator3.addr), 180_000 ether);

    //1000000 * 20% * 8% * (0.01) / (0.01 + 0.01)
    protocol.claimNftMinterRewardFunding(subDaoId2, nftMinter.addr);
    assertEq(IERC20(token).balanceOf(nftMinter.addr), 8_000 ether);

    // 1000000 * 20% * 8% * (0.01) / (0.01 + 0.01)
    protocol.claimNftMinterRewardFunding(subDaoId2, nftMinter2.addr);
    assertEq(IERC20(token).balanceOf(nftMinter2.addr), 8_000 ether);

    assertEq(IERC20(token).balanceOf(protocol.protocolFeePool()), 4000 ether);
    assertEq(IERC20(token).balanceOf(address(protocol)), 0);
  }

  function test_PDCreateFunding_createContinuousDAO_erc20_two_mint_with_diff_price() public {
    DeployHelper.CreateDaoParam memory param;
    param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    bytes32 canvasId1 = param.canvasId;
    param.existDaoId = bytes32(0);
    param.isBasicDao = true;
    bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

    param.daoUri = "continuous dao uri";
    param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
    bytes32 canvasId2 = param.canvasId;

    param.isBasicDao = false;
    param.existDaoId = daoId;

    bytes32 subDaoId = super._createDaoForFunding(param, daoCreator2.addr);

    param.daoUri = "continuous dao uri2";
    param.canvasId = keccak256(abi.encode(daoCreator3.addr, block.timestamp));
    bytes32 canvasId3 = param.canvasId;

    param.isBasicDao = false;
    param.existDaoId = daoId;
    param.childrenDaoId = new bytes32[](2);
    param.childrenDaoId[0] = daoId;
    param.childrenDaoId[1] = subDaoId;
    param.childrenDaoRatiosERC20 = new uint256[](2);
    param.childrenDaoRatiosERC20[0] = 4000;
    param.childrenDaoRatiosERC20[1] = 3000;
    param.childrenDaoRatiosETH = new uint256[](2);
    param.childrenDaoRatiosETH[0] = 1000;
    param.childrenDaoRatiosETH[1] = 2000;
    param.redeemPoolRatioETH = 3000;
    param.selfRewardRatioERC20 = 2000;
    param.selfRewardRatioETH = 3500;

    param.noPermission = true;
    param.mintableRound = 10;

    bytes32 subDaoId2 = super._createDaoForFunding(param, daoCreator3.addr);
    hoax(daoCreator.addr);
    protocol.setInitialTokenSupplyForSubDao(subDaoId2, 10_000_000 ether);
    uint256 flatPrice = 0.01 ether;
    super._mintNftDaoFunding(
      subDaoId2,
      canvasId3,
      string.concat(
        tokenUriPrefix,
        vm.toString(protocol.getDaoIndex(subDaoId2)),
        "-",
        vm.toString(uint256(0)),
        ".json"
      ),
      flatPrice,
      daoCreator3.key,
      nftMinter.addr
    );
    hoax(daoCreator3.addr);
    protocol.setDaoUnifiedPrice(subDaoId2, 0.04 ether);
    super._mintNftDaoFunding(
      subDaoId2,
      canvasId3,
      string.concat(
        tokenUriPrefix,
        vm.toString(protocol.getDaoIndex(subDaoId2)),
        "-",
        vm.toString(uint256(1)),
        ".json"
      ),
      0.04 ether,
      daoCreator3.key,
      nftMinter2.addr
    );

    //10_000_000 ether - 900_000 ether;
    address assetPool3 = protocol.getDaoAssetPool(subDaoId2);
    address assetPool1 = protocol.getDaoAssetPool(daoId);
    address assetPool2 = protocol.getDaoAssetPool(subDaoId);

    address token = protocol.getDaoToken(subDaoId2);
    assertEq(token, protocol.getDaoToken(daoId));
    assertEq(IERC20(token).balanceOf(assetPool3), 10_000_000 ether - 900_000 ether);
    assertEq(IERC20(token).balanceOf(assetPool1), 50_000_000 ether + 400_000 ether);
    assertEq(IERC20(token).balanceOf(assetPool2), 300_000 ether);
    assertEq(IERC20(token).balanceOf(address(protocol)), 200_000 ether);

    drb.changeRound(2);

    //1000000 * 20% * 70%
    protocol.claimDaoCreatorRewardFunding(subDaoId2);
    assertEq(IERC20(token).balanceOf(daoCreator3.addr), 140_000 ether);

    //add 1000000 * 20% * 20%
    protocol.claimCanvasRewardFunding(canvasId3);
    assertEq(IERC20(token).balanceOf(daoCreator3.addr), 180_000 ether);

    //1000000 * 20% * 8% * (0.01) / (0.01 + 0.04)
    protocol.claimNftMinterRewardFunding(subDaoId2, nftMinter.addr);
    assertEq(IERC20(token).balanceOf(nftMinter.addr), 3_200 ether);

    // 1000000 * 20% * 8% * (0.04) / (0.01 + 0.04)
    protocol.claimNftMinterRewardFunding(subDaoId2, nftMinter2.addr);
    assertEq(IERC20(token).balanceOf(nftMinter2.addr), 12_800 ether);

    assertEq(IERC20(token).balanceOf(protocol.protocolFeePool()), 4000 ether);
    assertEq(IERC20(token).balanceOf(address(protocol)), 0);
  }

  function test_PDCreateFunding_createContinuousDAO_erc20_three_mint_with_diff_price() public {
    DeployHelper.CreateDaoParam memory param;
    param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    bytes32 canvasId1 = param.canvasId;
    param.existDaoId = bytes32(0);
    param.isBasicDao = true;
    bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

    param.daoUri = "continuous dao uri";
    param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
    bytes32 canvasId2 = param.canvasId;

    param.isBasicDao = false;
    param.existDaoId = daoId;

    bytes32 subDaoId = super._createDaoForFunding(param, daoCreator2.addr);

    param.daoUri = "continuous dao uri2";
    param.canvasId = keccak256(abi.encode(daoCreator3.addr, block.timestamp));
    bytes32 canvasId3 = param.canvasId;

    param.isBasicDao = false;
    param.existDaoId = daoId;
    param.childrenDaoId = new bytes32[](2);
    param.childrenDaoId[0] = daoId;
    param.childrenDaoId[1] = subDaoId;
    param.childrenDaoRatiosERC20 = new uint256[](2);
    param.childrenDaoRatiosERC20[0] = 4000;
    param.childrenDaoRatiosERC20[1] = 3000;
    param.childrenDaoRatiosETH = new uint256[](2);
    param.childrenDaoRatiosETH[0] = 1000;
    param.childrenDaoRatiosETH[1] = 2000;
    param.redeemPoolRatioETH = 3000;
    param.selfRewardRatioERC20 = 2000;
    param.selfRewardRatioETH = 3500;

    param.noPermission = true;
    param.mintableRound = 10;

    bytes32 subDaoId2 = super._createDaoForFunding(param, daoCreator3.addr);
    hoax(daoCreator.addr);
    protocol.setInitialTokenSupplyForSubDao(subDaoId2, 10_000_000 ether);
    uint256 flatPrice = 0.01 ether;
    super._mintNftDaoFunding(
      subDaoId2,
      canvasId3,
      string.concat(
        tokenUriPrefix,
        vm.toString(protocol.getDaoIndex(subDaoId2)),
        "-",
        vm.toString(uint256(0)),
        ".json"
      ),
      flatPrice,
      daoCreator3.key,
      nftMinter.addr
    );
    hoax(daoCreator3.addr);
    protocol.setDaoUnifiedPrice(subDaoId2, 0.04 ether);
    super._mintNftDaoFunding(
      subDaoId2,
      canvasId3,
      string.concat(
        tokenUriPrefix,
        vm.toString(protocol.getDaoIndex(subDaoId2)),
        "-",
        vm.toString(uint256(1)),
        ".json"
      ),
      0.04 ether,
      daoCreator3.key,
      nftMinter2.addr
    );
    hoax(daoCreator3.addr);
    protocol.setDaoUnifiedPrice(subDaoId2, 0.05 ether);
    super._mintNftDaoFunding(
      subDaoId2,
      canvasId3,
      string.concat(
        tokenUriPrefix,
        vm.toString(protocol.getDaoIndex(subDaoId2)),
        "-",
        vm.toString(uint256(2)),
        ".json"
      ),
      0.05 ether,
      daoCreator3.key,
      randomGuy.addr
    );

    //10_000_000 ether - 900_000 ether;
    address assetPool3 = protocol.getDaoAssetPool(subDaoId2);
    address assetPool1 = protocol.getDaoAssetPool(daoId);
    address assetPool2 = protocol.getDaoAssetPool(subDaoId);

    address token = protocol.getDaoToken(subDaoId2);
    assertEq(token, protocol.getDaoToken(daoId));
    assertEq(IERC20(token).balanceOf(assetPool3), 10_000_000 ether - 900_000 ether);
    assertEq(IERC20(token).balanceOf(assetPool1), 50_000_000 ether + 400_000 ether);
    assertEq(IERC20(token).balanceOf(assetPool2), 300_000 ether);
    assertEq(IERC20(token).balanceOf(address(protocol)), 200_000 ether);

    drb.changeRound(2);

    //1000000 * 20% * 70%
    protocol.claimDaoCreatorRewardFunding(subDaoId2);
    assertEq(IERC20(token).balanceOf(daoCreator3.addr), 140_000 ether);

    //add 1000000 * 20% * 20%
    protocol.claimCanvasRewardFunding(canvasId3);
    assertEq(IERC20(token).balanceOf(daoCreator3.addr), 180_000 ether);

    //1000000 * 20% * 8% * (0.01) / (0.01 + 0.04 + 0.05)
    protocol.claimNftMinterRewardFunding(subDaoId2, nftMinter.addr);
    assertEq(IERC20(token).balanceOf(nftMinter.addr), 1_600 ether);

    // 1000000 * 20% * 8% * (0.04) / (0.01 + 0.04 + 0.05)
    protocol.claimNftMinterRewardFunding(subDaoId2, nftMinter2.addr);
    assertEq(IERC20(token).balanceOf(nftMinter2.addr), 6_400 ether);

    // 1000000 * 20% * 8% * (0.05) / (0.01 + 0.04 + 0.05)
    protocol.claimNftMinterRewardFunding(subDaoId2, randomGuy.addr);
    assertEq(IERC20(token).balanceOf(randomGuy.addr), 8_000 ether);

    assertEq(IERC20(token).balanceOf(protocol.protocolFeePool()), 4000 ether);
    assertEq(IERC20(token).balanceOf(address(protocol)), 0);
  }

  function show_address_erc20_balance(address erc20_token, address assetPool1, address assetPool2, address assetPool3) private {
    uint256 assetPool1_erc20_balance = IERC20(erc20_token).balanceOf(assetPool1);
    uint256 assetPool1_eth_balance = assetPool1.balance;
    console2.log("assetPool1 erc20 balance:", assetPool1_erc20_balance, ", eth balance:", assetPool1_eth_balance);
    uint256 assetPool2_erc20_balance = IERC20(erc20_token).balanceOf(assetPool2);
    uint256 assetPool2_eth_balance = assetPool2.balance;
    console2.log("assetPool2 erc20 balance:", assetPool2_erc20_balance, ", eth balance:", assetPool2_eth_balance);
    uint256 assetPool3_erc20_balance = IERC20(erc20_token).balanceOf(assetPool3);
    uint256 assetPool3_eth_balance = assetPool3.balance;
    console2.log("assetPool3 erc20 balance:", assetPool3_erc20_balance, ", eth balance:", assetPool3_eth_balance);
  }

  function test_PDCreateFunding_createContinuousDAO_eth_two_mint_with_same_price() public {
    DeployHelper.CreateDaoParam memory param;
    param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    bytes32 canvasId1 = param.canvasId;
    param.isBasicDao = true;
    param.existDaoId = bytes32(0);
    bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

    param.daoUri = "continuous dao uri";
    param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
    bytes32 canvasId2 = param.canvasId;
    param.isBasicDao = false;
    param.existDaoId = daoId;
    bytes32 daoId1 = super._createDaoForFunding(param, daoCreator2.addr);

    param.daoUri = "continuous dao uri2";
    param.canvasId = keccak256(abi.encode(daoCreator3.addr, block.timestamp));
    bytes32 canvasId3 = param.canvasId;
    param.isBasicDao = false;
    param.existDaoId = daoId;
    param.childrenDaoId = new bytes32[](2);
    param.childrenDaoId[0] = daoId;
    param.childrenDaoId[1] = daoId1;
    param.childrenDaoRatiosERC20 = new uint256[](2);
    // erc20 ratio
    param.childrenDaoRatiosERC20[0] = 4000;
    param.childrenDaoRatiosERC20[1] = 3000;
    param.selfRewardRatioERC20 = 2000;
    param.childrenDaoRatiosETH = new uint256[](2);
    // eth ratio
    param.childrenDaoRatiosETH[0] = 1000;
    param.childrenDaoRatiosETH[1] = 2000;
    param.redeemPoolRatioETH = 3000;
    param.selfRewardRatioETH = 3500;
    param.noPermission = true;
    param.mintableRound = 10;
    bytes32 daoId2 = super._createDaoForFunding(param, daoCreator3.addr);

    address assetPool1 = protocol.getDaoAssetPool(daoId);
    address assetPool2 = protocol.getDaoAssetPool(daoId1);
    address assetPool3 = protocol.getDaoAssetPool(daoId2);
    hoax(daoCreator.addr);
    protocol.setInitialTokenSupplyForSubDao(daoId2, 10_000_000 ether);
    uint256 flatPrice = 0.01 ether;
    uint256 assetPool3_eth_balance = assetPool3.balance;
    console2.log(assetPool3_eth_balance);
    super._mintNftDaoFunding(
      daoId2,
      canvasId3,
      string.concat(
        tokenUriPrefix,
        vm.toString(protocol.getDaoIndex(daoId2)),
        "-",
        vm.toString(uint256(0)),
        ".json"
      ),
      flatPrice,
      daoCreator3.key,
      nftMinter.addr
    );



    address token = protocol.getDaoToken(daoId2);
    // show_address_erc20_balance(token, assetPool1, assetPool2, assetPool3);

    assertEq(token, protocol.getDaoToken(daoId));
    // 10_000_000 ether is setInitialTokenSupplyForSubDao
    // 900_000 ether = 10_000_000 ether * (1 DRB/10 DRB) * (param.childrenDaoRatiosERC20[0] + param.childrenDaoRatiosERC20[1] + param.selfRewardRatioERC20) / BASIS_POINT
    // 900_000 ether = 10_000_000 ether * (1 DRB/10 DRB) * (4000 + 3000 + 2000) / 10000
    assertEq(IERC20(token).balanceOf(assetPool3), 10_000_000 ether - 900_000 ether);
    // 50_000_000 ether = 1G ether * BasicDaoParam.initTokenSupplyRatio / BASIS_POINT
    // 50_000_000 ether = 1G ether * 500 / 10000
    // 400_000 ether = 10_000_000 ether * (1 DRB/10 DRB) * 4000 / 10000
    assertEq(IERC20(token).balanceOf(assetPool1), 50_000_000 ether + 400_000 ether);
    // 300_000 ether = 10_000_000 ether * (1 DRB/10 DRB) * 3000 / 10000
    assertEq(IERC20(token).balanceOf(assetPool2), 300_000 ether);
    // 200_000 ether = 10_000_000 ether * (1 DRB/10 DRB) * 2000 / 10000
    assertEq(IERC20(token).balanceOf(address(protocol)), 200_000 ether);

    assetPool3_eth_balance = assetPool3.balance;
    console2.log(assetPool3_eth_balance);

    drb.changeRound(2);

    // 10_000_000 ether * (1 DRB/10 DRB) * (param.selfRewardRatioERC20 / BASIS_POINT) * (AllRatioForFundingParam.daoCreatorERC20RewardRatio / BASIS_POINT)
    // 140_000 ether = 10_000_000 ether * (1 DRB/10 DRB) * 0.2 * 0.7
    protocol.claimDaoCreatorRewardFunding(daoId2);
    assertEq(IERC20(token).balanceOf(daoCreator3.addr), 140_000 ether);

    // canvasId3 is daoCreator3
    // add AllRatioForFundingParam.canvasCreatorERC20RewardRatio
    // 10_000_000 ether * (1 DRB/10 DRB) * (0.2 * 0.7 + 0.2 * 0.2)
    protocol.claimCanvasRewardFunding(canvasId3);
    assertEq(IERC20(token).balanceOf(daoCreator3.addr), 180_000 ether);

    // 10_000_000 ether * (1 DRB/10 DRB) * (0.2 * 0.08)
    protocol.claimNftMinterRewardFunding(daoId2, nftMinter.addr);
    assertEq(IERC20(token).balanceOf(nftMinter.addr), 16_000 ether);

    // 1000000 * 0.2 - 180_000 ether - 16_000 ether
    assertEq(IERC20(token).balanceOf(protocol.protocolFeePool()), 4000 ether);
    assertEq(IERC20(token).balanceOf(address(protocol)), 0);

    assetPool3_eth_balance = assetPool3.balance;
    console2.log(assetPool3_eth_balance);

    drb.changeRound(3);
    assetPool3_eth_balance = assetPool3.balance;
    // 0.01 ether * 
    // assertEq(assetPool3_eth_balance);
    console2.log(assetPool3_eth_balance);
  }
}
/*
vars.allRatioForFundingParam = AllRatioForFundingParam({
            // l.protocolMintFeeRatioInBps = 250
            // sum = 9750
            // !!! enable when param.uniPriceModeOff = true
            canvasCreatorMintFeeRatio: 750,
            assetPoolMintFeeRatio: 2000,
            redeemPoolMintFeeRatio: 7000,


            // * 1.3 add
            // l.protocolMintFeeRatioInBps = 250
            // sum = 9750
            // !!! enable when param.uniPriceModeOff = false, default is false
            canvasCreatorMintFeeRatioFiatPrice: 250,
            assetPoolMintFeeRatioFiatPrice: 3500,
            redeemPoolMintFeeRatioFiatPrice: 6000,


            // l.protocolERC20RatioInBps = 200
            // sum = 9800
            // !!! ratio for param.selfRewardRatioERC20
            minterERC20RewardRatio: 800,
            canvasCreatorERC20RewardRatio: 2000,
            daoCreatorERC20RewardRatio: 7000,


            // sum = 9800
            // !!! ratio for param.selfRewardRatioETH
            minterETHRewardRatio: 800,
            canvasCreatorETHRewardRatio: 2000,
            daoCreatorETHRewardRatio: 7000
        });
*/
