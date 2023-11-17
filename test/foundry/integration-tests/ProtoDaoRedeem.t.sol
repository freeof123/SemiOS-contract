// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoRedeemTest is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    // testcase 1.3-15
    function test_PDCreateFunding_1_3_15() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.redeemPoolRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        address token = protocol.getDaoToken(daoId);
        //total
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        drb.changeRound(2);
        //trigger reward distribution, fee pool bal = 0.01 * 0.35 = 0.0035 ether, distribute 0.0035 ether / 9 to redeem
        // pool
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter2.addr
        );

        drb.changeRound(3);

        protocol.claimNftMinterRewardFunding(daoId, nftMinter.addr);
        protocol.claimNftMinterRewardFunding(daoId, nftMinter2.addr);
        //5000000 * minterratio(800) / 10000
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 400_000 ether);
        assertEq(IERC20(token).balanceOf(nftMinter2.addr), 400_000 ether);
        //circulate erc20 = 10000000 ether, available eth = 0.02 ether * 0.6 = 0.012 ether + 0.0035 ether / 9
        vm.prank(nftMinter.addr);
        uint256 a = protocol.exchangeERC20ToETH(daoId, 1 ether, nftMinter.addr);
        assertEq(a, (0.012 ether + 0.0035 ether / uint256(9)) / 10_000_000);

        vm.prank(nftMinter.addr);
        a = protocol.exchangeERC20ToETH(daoId, 1 ether, nftMinter.addr);
        assertEq(a, (0.012 ether + 0.0035 ether / uint256(9)) / 10_000_000);
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
