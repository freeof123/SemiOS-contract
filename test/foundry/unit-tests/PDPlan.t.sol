// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { PDProtocolHarness } from "test/foundry/harness/PDProtocolHarness.sol";
import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { PDCreate } from "contracts/PDCreate.sol";
import "contracts/interface/D4AStructs.sol";

import { D4AERC721 } from "contracts/D4AERC721.sol";
import { console2 } from "forge-std/console2.sol";
import "contracts/interface/D4AErrors.sol";
import {
    PriceTemplateType, RewardTemplateType, TemplateChoice, PlanTemplateType
} from "contracts/interface/D4AEnums.sol";

contract PDPlanTest is DeployHelper {
    bytes32 daoId;
    bytes32 daoId2;
    bytes32 canvasId1;
    bytes32 canvasId2;
    NftIdentifier[] nfts;

    function setUp() public {
        setUpEnv();
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.unifiedPrice = 0.1 ether;
        param.topUpMode = true;
        daoId = _createDaoForFunding(param, daoCreator.addr);
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.topUpMode = false;
        param.daoUri = "normal dao";
        canvasId2 = param.canvasId;
        daoId2 = _createDaoForFunding(param, daoCreator.addr);
        //initial topup account
        _testERC721.mint(nftMinter.addr, 0);
        _testERC721.mint(nftMinter1.addr, 1);
        _testERC721.mint(nftMinter2.addr, 2);
        _testERC721.mint(nftMinter3.addr, 3);
        _testERC20.mint(address(this), 100 ether);
        _testERC20.approve(address(protocol), 100 ether);

        nfts.push(NftIdentifier(address(_testERC721), 0));
        nfts.push(NftIdentifier(address(_testERC721), 1));
        nfts.push(NftIdentifier(address(_testERC721), 2));
        nfts.push(NftIdentifier(address(_testERC721), 3));
    }

    function test_planBasic() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);

        //plan begin in round 2
        protocol.createPlan(
            CreatePlanParam(daoId, 2, 1, 10, 4_200_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        nftParam.tokenUri = "nft 1";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        //current contribuction: 0,0,0,0
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 0);
        vm.roll(3);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        nftParam.tokenUri = "nft 2";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 2);
        super._mintNftWithParam(nftParam, nftMinter2.addr);
        //in round 2 claim reward for round 1
        //current contribuction: 1,0,0,0
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 0);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 0);
        vm.roll(4);
        nftParam.tokenUri = "nft 3";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 3);
        super._mintNftWithParam(nftParam, nftMinter3.addr);
        protocol.updateMultiTopUpAccount(daoId, nfts); //挂账和mint的先后顺序不影响，因为本回合的挂账都不会成功
        //current contribuction: 1,1,0,0
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 0);
        vm.roll(5);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        //current contribuction: 1,1,1,0
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000);
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 0);
        vm.roll(6);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        //current contribuction: 1,1,1,1
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000 + 105_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000 + 105_000);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000 + 105_000);
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 105_000);
        vm.roll(7);
        //simple quit, for round 6 still 1,1,1,1
        nftParam.tokenUri = "nft 4";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        super._mintNftWithParam(nftParam, nftMinter.addr);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        //current contribuction: 1,1,1,0
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000 + 105_000 * 2);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000 + 105_000 * 2);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000 + 105_000 * 2, "a63");
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 105_000 * 2, "a64");
        vm.roll(8);
        //using topup balance need not update
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        //current contribuction: 1,1,1,0
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000 + 105_000 * 2, "a71");
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000 * 2 + 105_000 * 2, "a72");
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000 * 2 + 105_000 * 2, "a73");
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 140_000 + 105_000 * 2, "a74");
    }

    function test_planBasic_autoUpdate() public {
        //this test achieves auto update by calling claimDaoPlanReward
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);

        //plan begin in round 2
        protocol.createPlan(
            CreatePlanParam(daoId, 2, 1, 10, 4_200_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(2);
        nftParam.tokenUri = "nft 1";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        //current contribuction: 0,0,0,0
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 0);
        vm.roll(3);
        nftParam.tokenUri = "nft 2";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 2);
        super._mintNftWithParam(nftParam, nftMinter2.addr);
        //in round 2 claim reward for round 1
        //current contribuction: 1,0,0,0
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 0);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 0);
        vm.roll(4);
        nftParam.tokenUri = "nft 3";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 3);
        super._mintNftWithParam(nftParam, nftMinter3.addr);
        //current contribuction: 1,1,0,0
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 0);
        vm.roll(5);
        //current contribuction: 1,1,1,0
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000);
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 0);
        vm.roll(6);
        //current contribuction: 1,1,1,1
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000 + 105_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000 + 105_000);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000 + 105_000);
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 105_000);
        vm.roll(7);
        //simple quit, for round 6 still 1,1,1,1
        nftParam.tokenUri = "nft 4";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        super._mintNftWithParam(nftParam, nftMinter.addr);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        //current contribuction: 1,1,1,0
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000 + 105_000 * 2);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000 + 105_000 * 2);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000 + 105_000 * 2, "a63");
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 105_000 * 2, "a64");
        vm.roll(8);
        //using topup balance need not update
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        //current contribuction: 1,1,1,0
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000 + 105_000 * 2, "a71");
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000 * 2 + 105_000 * 2, "a72");
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000 * 2 + 105_000 * 2, "a73");
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 140_000 + 105_000 * 2, "a74");
    }

    function test_planBasic_claimCulmulately() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);

        //plan begin in round 2
        protocol.createPlan(
            CreatePlanParam(daoId, 2, 1, 10, 4_200_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        nftParam.tokenUri = "nft 1";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        //current contribuction: 0,0,0,0

        vm.roll(3);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        nftParam.tokenUri = "nft 2";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 2);
        super._mintNftWithParam(nftParam, nftMinter2.addr);
        //in round 2 claim reward for round 1
        //current contribuction: 1,0,0,0

        vm.roll(4);
        nftParam.tokenUri = "nft 3";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 3);
        super._mintNftWithParam(nftParam, nftMinter3.addr);
        protocol.updateMultiTopUpAccount(daoId, nfts); //挂账和mint的先后顺序不影响，因为本回合的挂账都不会成功
        //current contribuction: 1,1,0,0

        vm.roll(5);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        //current contribuction: 1,1,1,0

        vm.roll(6);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        //current contribuction: 1,1,1,1

        vm.roll(7);
        //simple quit, for round 6 still 1,1,1,1
        nftParam.tokenUri = "nft 4";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        //current contribuction: 1,1,1,0

        vm.roll(8);
        //using topup balance need not update
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 3));
        //current contribuction: 1,1,1,0
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000 + 105_000 * 2, "a71");
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000 * 2 + 105_000 * 2, "a72");
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 140_000 * 2 + 105_000 * 2, "a73");
        assertEq(_testERC20.balanceOf(nftMinter3.addr), 140_000 + 105_000 * 2, "a74");
    }

    function test_twoPlans() public {
        bytes32 plan0 = protocol.createPlan(
            CreatePlanParam(daoId, 2, 1, 10, 4_200_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        protocol.createPlan(
            CreatePlanParam(daoId, 3, 1, 10, 42_000_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        vm.roll(2);
        //contribution:
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        nftParam.tokenUri = "nft 1";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        vm.roll(3);
        //contribution: 1,0 || 0,0
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 1));
        nftParam.tokenUri = "nft 2";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);

        vm.roll(4);
        //contribution 1,1 || 1,1
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 1));

        nftParam.tokenUri = "nft 3";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);

        vm.roll(5);
        //contribution 1,2 || 1,2
        bytes32[] memory planIds = new bytes32[](1);
        planIds[0] = plan0;
        assertEq(protocol.claimMultiPlanReward(planIds, NftIdentifier(address(_testERC721), 1)), 490_000);
        assertEq(protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1)), 4_900_000);

        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 420_000 + 210_000 + 140_000 + 2_100_000 + 1_400_000, "a71");
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 210_000 + 140_000 * 2 + 2_100_000 + 1_400_000 * 2, "a72");
    }

    function test_pressure_for_plan_number() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        uint256 number = 300;
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        for (uint256 i = 0; i < number; i++) {
            protocol.createPlan(
                CreatePlanParam(daoId, 2, 1, 10, 4_200_000, address(_testERC20), false, false, "", PlanTemplateType(0))
            );
        }
        vm.roll(2);
        nftParam.tokenUri = "nft 1";
        uint256 gasBefore = gasleft();
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);

        console2.log("limit: ", block.gaslimit);
        console2.log("gas price: ", tx.gasprice);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        console2.log("gas: ", gasBefore - gasleft());

        nftParam.tokenUri = "nft 2";
        gasBefore = gasleft();
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 2);
        super._mintNftWithParam(nftParam, nftMinter2.addr);
        console2.log("gas: ", gasBefore - gasleft());

        vm.prank(daoCreator.addr);
        protocol.setDaoUnifiedPrice(daoId, 1 ether);

        nftParam.tokenUri = "nft 3";
        gasBefore = gasleft();
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 3);
        nftParam.flatPrice = 1 ether;
        super._mintNftWithParam(nftParam, nftMinter3.addr);
        console2.log("gas: ", gasBefore - gasleft());

        vm.roll(3);
        gasBefore = gasleft();
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        console2.log("gas: ", gasBefore - gasleft());
        vm.roll(4);
        gasBefore = gasleft();
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        console2.log("gas: ", gasBefore - gasleft());
        vm.roll(5);
        gasBefore = gasleft();
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        console2.log("gas: ", gasBefore - gasleft());
        vm.roll(6);
        gasBefore = gasleft();
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        console2.log("gas: ", gasBefore - gasleft());
        gasBefore = gasleft();
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        console2.log("gas: ", gasBefore - gasleft());
        gasBefore = gasleft();
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 2));
        console2.log("gas: ", gasBefore - gasleft());
    }

    function test_planEnds() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        protocol.createPlan(
            CreatePlanParam(daoId, 1, 1, 11, 10_000_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        vm.roll(5);
        nftParam.tokenUri = "nft 1";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        vm.roll(6);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 1));
        vm.roll(100);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 7_000_000);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 3_000_000);
    }

    function test_addPlanTotalReward() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        bytes32 planId = protocol.createPlan(
            CreatePlanParam(daoId, 1, 1, 11, 10_000_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        vm.roll(5);
        nftParam.tokenUri = "nft 1";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);

        protocol.addPlanTotalReward(planId, 70_000_000, false);
        vm.roll(6);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 1));
        vm.roll(100);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 7_000_000 + 10_000_000 + 5_000_000 * 6);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 3_000_000 + 5_000_000 * 6);
    }

    function test_plan_incentivizeOutputToken_noCompete() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        bytes32 planId = protocol.createPlan(
            CreatePlanParam(daoId, 1, 1, 11, 10_000_000, address(_testERC20), false, true, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));

        vm.roll(5);
        nftParam.tokenUri = "nft 1";
        vm.prank(daoCreator.addr);
        protocol.setDaoUnifiedPrice(daoId, 0.3 ether);

        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        nftParam.flatPrice = 0.3 ether;
        super._mintNftWithParam(nftParam, nftMinter1.addr);

        vm.roll(6);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 1));
        vm.roll(100);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertApproxEqAbs(_testERC20.balanceOf(nftMinter.addr), 7_000_000, 10);
        assertApproxEqAbs(_testERC20.balanceOf(nftMinter1.addr), 3_000_000, 10);
    }

    function test_plan_incentivizeOutputToken_Compete() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        nftParam.tokenUri = "nft 1";
        vm.prank(daoCreator.addr);
        protocol.setDaoUnifiedPrice(daoId, 0.3 ether);

        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        nftParam.flatPrice = 0.3 ether;
        super._mintNftWithParam(nftParam, nftMinter1.addr);

        bytes32 planId = protocol.createPlan(
            CreatePlanParam(daoId, 1, 1, 11, 10_000_000, address(_testERC20), false, true, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateMultiTopUpAccount(daoId, nfts);

        vm.roll(100);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertApproxEqAbs(_testERC20.balanceOf(nftMinter.addr), 2_500_000, 10);
        assertApproxEqAbs(_testERC20.balanceOf(nftMinter1.addr), 7_500_000, 10);
    }

    function test_plan_incentivizeOutputToken_usingAccount() public {
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        nftParam.tokenUri = "nft 1";
        vm.prank(daoCreator.addr);
        protocol.setDaoUnifiedPrice(daoId, 0.3 ether);

        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        nftParam.flatPrice = 0.3 ether;
        super._mintNftWithParam(nftParam, nftMinter1.addr);

        bytes32 planId = protocol.createPlan(
            CreatePlanParam(daoId, 1, 1, 11, 10_000_000, address(_testERC20), false, true, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        vm.roll(7);
        vm.prank(daoCreator.addr);
        protocol.setDaoUnifiedPrice(daoId2, 0.2 ether);
        nftParam.tokenUri = "nft 2";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;

        nftParam.flatPrice = 0.2 ether;
        super._mintNftWithParam(nftParam, nftMinter1.addr);

        vm.roll(100);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertApproxEqAbs(_testERC20.balanceOf(nftMinter.addr), 250_000 * 5 + 500_000 * 5, 10);
        assertApproxEqAbs(_testERC20.balanceOf(nftMinter1.addr), 750_000 * 5 + 500_000 * 5, 10);
    }

    function test_planRetrive() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        bytes32 planId = protocol.createPlan(
            CreatePlanParam(daoId, 1, 1, 11, 10_000_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        vm.roll(3);
        nftParam.tokenUri = "nft 1";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        vm.roll(4);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 1));
        vm.roll(7);
        nftParam.tokenUri = "nft 2";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        nftParam.tokenUri = "nft 3";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);

        vm.roll(100);
        uint256 balBefore = _testERC20.balanceOf(address(this));
        protocol.retriveUnclaimedToken(planId);
        assertEq(_testERC20.balanceOf(address(this)), balBefore + 5_000_000);
        assertEq(protocol.getPlanCumulatedReward(planId), 5_000_000);
    }

    function test_planCumulatedReward() public {
        //minter 0 has balance in round 1;
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        bytes32 planId = protocol.createPlan(
            CreatePlanParam(daoId, 1, 1, 11, 10_000_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(2);
        protocol.updateTopUpAccount(daoId, NftIdentifier(address(_testERC721), 0));
        assertEq(protocol.getPlanCumulatedReward(planId), 0);
        vm.roll(3);
        nftParam.tokenUri = "nft 1";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        assertEq(protocol.getPlanCumulatedReward(planId), 1_000_000);
        vm.roll(4);
        assertEq(protocol.getPlanCumulatedReward(planId), 2_000_000);
        vm.roll(5);
        nftParam.tokenUri = "nft 2";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        nftParam.tokenUri = "nft 3";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 1);
        super._mintNftWithParam(nftParam, nftMinter1.addr);
        assertEq(protocol.getPlanCumulatedReward(planId), 3_000_000);
        vm.roll(6);
        assertEq(protocol.getPlanCumulatedReward(planId), 3_000_000);
        vm.roll(8);
        assertEq(protocol.getPlanCumulatedReward(planId), 3_000_000);
        nftParam.tokenUri = "nft 4";
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        super._mintNftWithParam(nftParam, nftMinter.addr);
        assertEq(protocol.getPlanCumulatedReward(planId), 3_000_000);
        vm.roll(9);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        assertEq(protocol.getPlanCumulatedReward(planId), 3_000_000);
        vm.roll(10);
        assertEq(protocol.getPlanCumulatedReward(planId), 3_000_000 + uint256(7_000_000) / 3);
        vm.roll(11);
        assertEq(protocol.getPlanCumulatedReward(planId), 3_000_000 + uint256(7_000_000) * 2 / 3);
        uint256 balBefore = _testERC20.balanceOf(address(this));
        protocol.retriveUnclaimedToken(planId);
        assertEq(_testERC20.balanceOf(address(this)), balBefore);
        vm.roll(12);
        assertEq(protocol.getPlanCumulatedReward(planId), 10_000_000);
        balBefore = _testERC20.balanceOf(address(this));
        protocol.retriveUnclaimedToken(planId);
        assertEq(_testERC20.balanceOf(address(this)), balBefore);
    }

    function test_planCumulatedReward_noUser() public {
        bytes32 planId = protocol.createPlan(
            CreatePlanParam(daoId, 1, 1, 11, 10_000_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(100);
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        super._mintNftWithParam(nftParam, nftMinter.addr);
        vm.roll(101);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        vm.roll(102);
        assertEq(protocol.getPlanCumulatedReward(planId), 0);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 0);

        uint256 balBefore = _testERC20.balanceOf(address(this));
        protocol.retriveUnclaimedToken(planId);
        assertEq(_testERC20.balanceOf(address(this)), balBefore + 10_000_000);
        assertEq(protocol.getPlanCumulatedReward(planId), 0);
    }

    function test_planBeginNow() public {
        bytes32 planId = protocol.createPlan(
            CreatePlanParam(daoId, 0, 1, 11, 10_000_000, address(_testERC20), false, false, "", PlanTemplateType(0))
        );
        vm.roll(100);
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = "nft 0";
        nftParam.flatPrice = 0.1 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier(address(_testERC721), 0);
        super._mintNftWithParam(nftParam, nftMinter.addr);
        vm.roll(101);
        protocol.updateMultiTopUpAccount(daoId, nfts);
        vm.roll(102);
        assertEq(protocol.getPlanCumulatedReward(planId), 0);
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 0));
        protocol.claimDaoPlanReward(daoId, NftIdentifier(address(_testERC721), 1));
        assertEq(_testERC20.balanceOf(nftMinter.addr), 0);
        assertEq(_testERC20.balanceOf(nftMinter1.addr), 0);

        uint256 balBefore = _testERC20.balanceOf(address(this));
        protocol.retriveUnclaimedToken(planId);
        assertEq(_testERC20.balanceOf(address(this)), balBefore + 10_000_000);
        assertEq(protocol.getPlanCumulatedReward(planId), 0);
    }
}
