// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

contract DaoRedeem is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    /**
     * test_redeem_sameRound 与 test_redeem_diffRound 中 claimProjectERC20Reward 数量应相同
     * 即在 mint 的本轮中 claim 与 mint 的下一轮 claim 获得的 token 数量相同
     */

    // mint NFT and redeem in same round
    function test_redeem_sameRound() public {
        vm.skip(true);
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
        assertEq(basicDaoFlatPrice, 0.01 ether);
        // console2.log("basic dao flat price: ", basicDaoFlatPrice);

        drb.changeRound(1);
        // basic dao mint NFT
        super._mintNft(
            basicDaoId, createDaoParam.canvasId, "uri:round1-1", basicDaoFlatPrice, daoCreator.key, daoCreator.addr
        );

        // mint continuous dao NFT
        super._mintNft(
            continuousDaoId, createDaoParam.canvasId, "uri:round1-2", 0.01 ether, daoCreator.key, daoCreator.addr
        );

        drb.changeRound(2);

        // claim问题
        uint256 continuousDaoCreatorReward = protocol.claimProjectERC20Reward(continuousDaoId);

        /**
         * 每个 DAO 默认发 5 千万个 token，mintableRound 设置为 10，所以每次发 5 百万，
         * 上面创建了 2 个 DAO，过了一轮，dao creator 分的比例为 48%，上面只提取 continuous dao 的奖励
         * 5e7 / 10 * 1e18 * 2 * 1 * 0.48 / 2 = 24e23
         */
        assertEq(continuousDaoCreatorReward, 24e23);

        super._mintNft(
            continuousDaoId, createDaoParam.canvasId, "uri:round2", 0.01 ether, daoCreator.key, daoCreator.addr
        );

        vm.prank(daoCreator.addr);
        uint256 tokenAmount = continuousDaoCreatorReward;
        address to = address(this);
        uint256 amount = protocol.exchangeERC20ToETH(continuousDaoId, tokenAmount, to);

        console2.log("receive ETH after redeem: ", amount);
    }

    // mint NFT and redeem in different round
    function test_redeem_diffRound() public {
        vm.skip(true);
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

        // claim问题
        uint256 continuousDaoCreatorReward = protocol.claimProjectERC20Reward(continuousDaoId);
        assertEq(continuousDaoCreatorReward, 24e23);

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