// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam, CreateCanvasAndMintNFTParam } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";
import { MintNFTParam } from "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

import { PriceTemplateType, RewardTemplateType, TemplateChoice } from "contracts/interface/D4AEnums.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoPriceTest is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    // testcase 1.3-15
    function test_PDCreateFunding_1_3_85() public {
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
        param.dailyMintCap = 10_000;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        //address token = protocol.getDaoToken(daoId);
        vm.prank(daoCreator.addr);
        protocol.setRoundMintCap(daoId, 2);
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

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        string memory uri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        );
        vm.expectRevert(ExceedDailyMintCap.selector);

        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = canvasId1;
        mintNftTransferParam.tokenUri = uri;
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = "0x0";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        hoax(nftMinter.addr);
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);
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
