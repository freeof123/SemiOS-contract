// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

contract DaoNftRedeem is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    // mint NFT and redeem in same round
    function test_redeemInSameRound() public {
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
        // console2.log("basic dao flat price: ", basicDaoFlatPrice);

        drb.changeRound(1);
        // basic dao mint NFT
        super._mintNft(
            basicDaoId, createDaoParam.canvasId, "uri:round1-1", basicDaoFlatPrice, daoCreator.key, daoCreator.addr
        );

        // claim Basic DAO reward
        // uint256 baiscDaoCreatorReward = protocol.claimProjectERC20Reward(basicDaoId);
        // console2.log("basic dao creator ERC20 reward: ", baiscDaoCreatorReward);

        uint256 continuousDaoFlatPrice = protocol.getDaoUnifiedPrice(continuousDaoId);
        // console2.log("continuous dao flat price: ", continuousDaoFlatPrice);

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

        vm.prank(daoCreator.addr);
        uint256 tokenAmount = continuousDaoCreatorReward;
        address to = address(this);
        uint256 amount = protocol.exchangeERC20ToETH(continuousDaoId, tokenAmount, to);

        console2.log("receive ETH after redeem: ", amount);
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
