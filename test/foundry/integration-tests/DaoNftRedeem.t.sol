// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DaoNftRedeem is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    // mint NFT and redeem in same round
    function test_redeemInSameRound() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 9999;
        createDaoParam.isProgressiveJackpot = true;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));

        bytes32[] memory daos = new bytes32[](2);
        bytes32[] memory canvases = new bytes32[](2);
        canvases[0] = createDaoParam.canvasId;

        drb.changeRound(1);

        // create Basic DAO
        bytes32 basicDaoId = super._createBasicDao(createDaoParam);
        //unlock Basic DAO
        super._unlocker(basicDaoId, 2 ether);

        daos[0] = basicDaoId;
        console2.log("basic DAO created successfully");

        uint256 basicDaoFlatPrice = protocol.getDaoUnifiedPrice(basicDaoId);

        super._mintNft(
            basicDaoId, createDaoParam.canvasId, "uri:round1-1", basicDaoFlatPrice, daoCreator.key, daoCreator.addr
        );

        console2.log("round reward: %s", protocol.getRoundReward(basicDaoId, 1));

        createDaoParam.daoUri = "continuous dao uri";
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        canvases[1] = createDaoParam.canvasId;
        createDaoParam.mintableRound = 360;
        createDaoParam.unifiedPrice = 0.0099 ether;

        bytes32 continuousDaoId = super._createContinuousDao(createDaoParam, basicDaoId, true, false, 1000);
        console2.log("created continuous dao successfully");

        daos[1] = continuousDaoId;

        super._mintNft(
            continuousDaoId, createDaoParam.canvasId, "uri:round1-2", 0.0099 ether, daoCreator.key, daoCreator.addr
        );

        // basic dao mint NFT
        drb.changeRound(2);

        address basicDaoERC20 = protocol.getDaoToken(basicDaoId);
        hoax(daoCreator.addr);
        uint256 amount = claimer.claimMultiReward(canvases, daos);
        console2.log("balance %s", IERC20(basicDaoERC20).balanceOf(daoCreator.addr));
        console2.log("amount %s", amount);

        address basicDaoFeePoolAddress = protocol.getDaoFeePool(basicDaoId);

        console2.log("fee pool bal before mint:", basicDaoFeePoolAddress.balance);

        console2.log("erc20 supply before mint:", IERC20(basicDaoERC20).totalSupply());

        // hoax(daoCreator.addr);
        // amount = protocol.exchangeERC20ToETH(continuousDaoId, 100 ether, daoCreator.addr);
        // console2.log("claimed eth amount before mint: %s", amount);

        super._mintNft(
            continuousDaoId, createDaoParam.canvasId, "uri:round1-3", 0.0099 ether, daoCreator.key, daoCreator.addr
        );

        console2.log("erc20 supply after mint:", IERC20(basicDaoERC20).totalSupply());

        console2.log("fee pool bal after mint:", basicDaoFeePoolAddress.balance);

        hoax(daoCreator.addr);
        amount = protocol.exchangeERC20ToETH(continuousDaoId, 100 ether, daoCreator.addr);
        console2.log("claimed eth amount after mint: %s", amount);
        assertEq(amount, 207_709_971_428_571);

        // claim Basic DAO reward
        // uint256 baiscDaoCreatorReward = protocol.claimProjectERC20Reward(basicDaoId);
        // console2.log("basic dao creator ERC20 reward: ", baiscDaoCreatorReward);
    }

    // mint NFT and redeem in different round
    function test_redeemDiffRound() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 9999;
        createDaoParam.mintableRound = 10;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));

        // create Baisc DAO
        bytes32 basicDaoId = super._createBasicDao(createDaoParam);
        console2.log("basic DAO created successfully");

        createDaoParam.daoUri = "continuous dao uri";
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));

        bytes32 continuousDaoId = super._createContinuousDao(createDaoParam, basicDaoId, true, true, 1000);
        console2.log("created continuous dao successfully");

        uint256 basicDaoFlatPrice = protocol.getDaoUnifiedPrice(basicDaoId);

        drb.changeRound(1);
        // basic dao mint NFT
        super._mintNft(
            basicDaoId, createDaoParam.canvasId, "uri:round1-1", basicDaoFlatPrice, daoCreator.key, daoCreator.addr
        );

        // claim Basic DAO reward
        // uint256 baiscDaoCreatorReward = protocol.claimProjectERC20Reward(basicDaoId);
        // console2.log("basic dao creator ERC20 reward: ", baiscDaoCreatorReward);

        uint256 continuousDaoFlatPrice = protocol.getDaoUnifiedPrice(continuousDaoId);

        // mint continuous dao NFT
        super._mintNft(
            continuousDaoId,
            createDaoParam.canvasId,
            "uri:round1-2",
            continuousDaoFlatPrice,
            daoCreator.key,
            daoCreator.addr
        );

        drb.changeRound(2);

        uint256 continuousDaoCreatorReward = protocol.claimProjectERC20Reward(continuousDaoId);
        console2.log("\n continuous dao creator ERC20 reward: ", continuousDaoCreatorReward);

        super._mintNft(
            continuousDaoId,
            createDaoParam.canvasId,
            "uri:round2",
            continuousDaoFlatPrice,
            daoCreator.key,
            daoCreator.addr
        );

        drb.changeRound(3);

        vm.prank(daoCreator.addr);
        uint256 tokenAmount = continuousDaoCreatorReward;
        address to = address(this);
        uint256 amount = protocol.exchangeERC20ToETH(continuousDaoId, tokenAmount, to);
        console2.log("receive continuous dao ETH after redeem: ", amount);
    }

    receive() external payable { }
}
