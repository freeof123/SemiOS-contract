// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AEnums.sol";

contract GrantRewardTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_1CanvasAndLri() public {
        DeployHelper.CreateDaoParam memory param;
        param.daoCreatorERC20RatioInBps = 300;
        param.canvasCreatorERC20RatioInBps = 9000;
        param.nftMinterERC20RatioInBps = 500;
        param.actionType = 16;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        protocol.claimProjectERC20Reward(daoId);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        protocol.grantETH{ value: 1.5 ether }(daoId);
        vm.stopPrank();

        _mintNft(daoId, canvasId, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(3);

        deal(daoCreator.addr, 0);
        deal(canvasCreator.addr, 0);
        deal(nftMinter.addr, 0);
        deal(protocol.getDaoFeePool(daoId), 0);

        IERC20 token = IERC20(protocol.getDaoToken(daoId));
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        vm.startPrank(daoCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(daoCreator.addr), daoCreator.addr);
        vm.startPrank(canvasCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator.addr), canvasCreator.addr);
        vm.startPrank(nftMinter.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(nftMinter.addr), nftMinter.addr);

        assertEq(daoCreator.addr.balance, 1_551_724_137_931_034);
        assertEq(canvasCreator.addr.balance, 46_551_724_137_931_034);
        assertEq(nftMinter.addr.balance, 2_586_206_896_551_724);
        assertEq(_testERC20.balanceOf(daoCreator.addr), 1_034_482_758_620_689_655_172);
        assertEq(_testERC20.balanceOf(canvasCreator.addr), 31_034_482_758_620_689_655_172);
        assertEq(_testERC20.balanceOf(nftMinter.addr), 1_724_137_931_034_482_758_620);
    }

    function test_1CanvasAndEri() public {
        DeployHelper.CreateDaoParam memory param;
        param.daoCreatorERC20RatioInBps = 300;
        param.canvasCreatorERC20RatioInBps = 9000;
        param.nftMinterERC20RatioInBps = 500;
        param.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        param.rewardDecayFactor = 12_345;
        param.actionType = 16;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        protocol.claimProjectERC20Reward(daoId);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        protocol.grantETH{ value: 1.5 ether }(daoId);
        vm.stopPrank();

        _mintNft(daoId, canvasId, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(3);

        deal(daoCreator.addr, 0);
        deal(canvasCreator.addr, 0);
        deal(nftMinter.addr, 0);
        deal(protocol.getDaoFeePool(daoId), 0);

        IERC20 token = IERC20(protocol.getDaoToken(daoId));
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        vm.startPrank(daoCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(daoCreator.addr), daoCreator.addr);
        vm.startPrank(canvasCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator.addr), canvasCreator.addr);
        vm.startPrank(nftMinter.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(nftMinter.addr), nftMinter.addr);

        assertEq(daoCreator.addr.balance, 8_567_031_707_118_344);
        assertEq(canvasCreator.addr.balance, 257_010_951_213_550_338);
        assertEq(nftMinter.addr.balance, 14_278_386_178_530_574);
        assertEq(_testERC20.balanceOf(daoCreator.addr), 5_711_354_471_412_229_749_967);
        assertEq(_testERC20.balanceOf(canvasCreator.addr), 171_340_634_142_366_892_499_031);
        assertEq(_testERC20.balanceOf(nftMinter.addr), 9_518_924_119_020_382_916_613);
    }

    function test_2CanvasesAndLri() public {
        DeployHelper.CreateDaoParam memory param;
        param.daoCreatorERC20RatioInBps = 300;
        param.canvasCreatorERC20RatioInBps = 9000;
        param.nftMinterERC20RatioInBps = 500;
        param.actionType = 16;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        hoax(canvasCreator3.addr);
        bytes32 canvasId3 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 0);

        _mintNft(daoId, canvasId3, "test token uri 1", 0, canvasCreator3.key, randomGuy.addr);

        drb.changeRound(2);

        IERC20 token = IERC20(protocol.getDaoToken(daoId));
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId3);
        protocol.claimNftMinterReward(daoId, randomGuy.addr);
        vm.startPrank(protocolFeePool.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(protocolFeePool.addr), protocolFeePool.addr);
        vm.startPrank(daoCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(daoCreator.addr), daoCreator.addr);
        vm.startPrank(canvasCreator3.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator3.addr), canvasCreator3.addr);
        vm.startPrank(randomGuy.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(randomGuy.addr), randomGuy.addr);

        startHoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        protocol.grantETH{ value: 1.5 ether }(daoId);
        vm.stopPrank();

        _mintNft(daoId, canvasId1, "test token uri 2", 0.42 ether, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 3", 0.69 ether, canvasCreator2.key, nftMinter2.addr);

        drb.changeRound(3);

        deal(daoCreator.addr, 0);
        deal(canvasCreator.addr, 0);
        deal(canvasCreator2.addr, 0);
        deal(nftMinter.addr, 0);
        deal(nftMinter2.addr, 0);
        deal(protocol.getDaoFeePool(daoId), 0);

        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        vm.startPrank(daoCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(daoCreator.addr), daoCreator.addr);
        vm.startPrank(canvasCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator.addr), canvasCreator.addr);
        vm.startPrank(canvasCreator2.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator2.addr), canvasCreator2.addr);
        vm.startPrank(nftMinter.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(nftMinter.addr), nftMinter.addr);
        vm.startPrank(nftMinter2.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(nftMinter2.addr), nftMinter2.addr);

        assertEq(daoCreator.addr.balance, 1_551_724_137_931_034);
        assertEq(canvasCreator.addr.balance, 17_614_165_890_027_958);
        assertEq(canvasCreator2.addr.balance, 28_937_558_247_903_076);
        assertEq(nftMinter.addr.balance, 978_564_771_668_219);
        assertEq(nftMinter2.addr.balance, 1_607_642_124_883_504);
        assertEq(_testERC20.balanceOf(daoCreator.addr), 1_034_482_758_620_689_655_172);
        assertEq(_testERC20.balanceOf(canvasCreator.addr), 11_742_777_260_018_639_328_984);
        assertEq(_testERC20.balanceOf(canvasCreator2.addr), 19_291_705_498_602_050_326_188);
        assertEq(_testERC20.balanceOf(nftMinter.addr), 652_376_514_445_479_962_721);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 1_071_761_416_589_002_795_899);
    }

    function test_2CanvasesAndEri() public {
        DeployHelper.CreateDaoParam memory param;
        param.daoCreatorERC20RatioInBps = 300;
        param.canvasCreatorERC20RatioInBps = 9000;
        param.nftMinterERC20RatioInBps = 500;
        param.rewardTemplateType = RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE;
        param.rewardDecayFactor = 12_345;
        param.actionType = 16;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId1 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0), 0);

        hoax(canvasCreator2.addr);
        bytes32 canvasId2 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2", new bytes32[](0), 0);

        hoax(canvasCreator3.addr);
        bytes32 canvasId3 = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 3", new bytes32[](0), 0);

        _mintNft(daoId, canvasId3, "test token uri 1", 0, canvasCreator3.key, randomGuy.addr);

        drb.changeRound(2);

        IERC20 token = IERC20(protocol.getDaoToken(daoId));
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId3);
        protocol.claimNftMinterReward(daoId, randomGuy.addr);
        vm.startPrank(protocolFeePool.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(protocolFeePool.addr), protocolFeePool.addr);
        vm.startPrank(daoCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(daoCreator.addr), daoCreator.addr);
        vm.startPrank(canvasCreator3.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator3.addr), canvasCreator3.addr);
        vm.startPrank(randomGuy.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(randomGuy.addr), randomGuy.addr);

        startHoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        protocol.grantETH{ value: 1.5 ether }(daoId);
        vm.stopPrank();

        _mintNft(daoId, canvasId1, "test token uri 2", 0.42 ether, canvasCreator.key, nftMinter.addr);
        _mintNft(daoId, canvasId2, "test token uri 3", 0.69 ether, canvasCreator2.key, nftMinter2.addr);

        drb.changeRound(3);

        deal(daoCreator.addr, 0);
        deal(canvasCreator.addr, 0);
        deal(canvasCreator2.addr, 0);
        deal(nftMinter.addr, 0);
        deal(nftMinter2.addr, 0);
        deal(protocol.getDaoFeePool(daoId), 0);

        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId1);
        protocol.claimCanvasReward(canvasId2);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimNftMinterReward(daoId, nftMinter2.addr);
        vm.startPrank(daoCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(daoCreator.addr), daoCreator.addr);
        vm.startPrank(canvasCreator.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator.addr), canvasCreator.addr);
        vm.startPrank(canvasCreator2.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator2.addr), canvasCreator2.addr);
        vm.startPrank(nftMinter.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(nftMinter.addr), nftMinter.addr);
        vm.startPrank(nftMinter2.addr);
        protocol.exchangeERC20ToETH(daoId, token.balanceOf(nftMinter2.addr), nftMinter2.addr);

        assertEq(daoCreator.addr.balance, 8_567_031_707_118_344);
        assertEq(canvasCreator.addr.balance, 97_247_386_945_667_695);
        assertEq(canvasCreator2.addr.balance, 159_763_564_267_882_643);
        assertEq(nftMinter.addr.balance, 5_402_632_608_092_649);
        assertEq(nftMinter2.addr.balance, 8_875_753_570_437_925);
        assertEq(_testERC20.balanceOf(daoCreator.addr), 5_711_354_471_412_229_749_967);
        assertEq(_testERC20.balanceOf(canvasCreator.addr), 64_831_591_297_111_797_161_795);
        assertEq(_testERC20.balanceOf(canvasCreator2.addr), 106_509_042_845_255_095_337_236);
        assertEq(_testERC20.balanceOf(nftMinter.addr), 3_601_755_072_061_766_508_988);
        assertEq(_testERC20.balanceOf(nftMinter2.addr), 5_917_169_046_958_616_407_625);
    }

    function test_ShouldClaimAllGrant() public {
        DeployHelper.CreateDaoParam memory param;
        param.daoCreatorERC20RatioInBps = 300;
        param.canvasCreatorERC20RatioInBps = 9000;
        param.nftMinterERC20RatioInBps = 500;
        param.actionType = 16;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        protocol.claimProjectERC20Reward(daoId);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        protocol.grantETH{ value: 1.5 ether }(daoId);
        vm.stopPrank();

        deal(daoCreator.addr, 0);
        deal(canvasCreator.addr, 0);
        deal(nftMinter.addr, 0);
        deal(protocol.getDaoFeePool(daoId), 0);

        for (uint256 i; i < 29; i++) {
            _mintNft(
                daoId,
                canvasId,
                string.concat("test token uri ", vm.toString(i + 2)),
                0,
                canvasCreator.key,
                nftMinter.addr
            );

            drb.changeRound(i + 3);

            IERC20 token = IERC20(protocol.getDaoToken(daoId));
            protocol.claimProjectERC20Reward(daoId);
            protocol.claimCanvasReward(canvasId);
            protocol.claimNftMinterReward(daoId, nftMinter.addr);
            vm.startPrank(protocolFeePool.addr);
            protocol.exchangeERC20ToETH(daoId, token.balanceOf(protocolFeePool.addr), protocolFeePool.addr);
            vm.startPrank(daoCreator.addr);
            protocol.exchangeERC20ToETH(daoId, token.balanceOf(daoCreator.addr), daoCreator.addr);
            vm.startPrank(canvasCreator.addr);
            protocol.exchangeERC20ToETH(daoId, token.balanceOf(canvasCreator.addr), canvasCreator.addr);
            vm.startPrank(nftMinter.addr);
            protocol.exchangeERC20ToETH(daoId, token.balanceOf(nftMinter.addr), nftMinter.addr);
        }

        assertApproxEqRel(daoCreator.addr.balance, 4.5e16 + 0.29 ether * 0.3 * 0.03, 1e3);
        assertApproxEqRel(canvasCreator.addr.balance, 1.35e18 + 0.29 ether * 0.3 * 0.9 + 0.29 ether * 0.675, 1e2);
        assertApproxEqRel(nftMinter.addr.balance, 7.5e16 + 0.29 ether * 0.3 * 0.05, 1e2);
        assertEq(protocol.getVestingWallet(daoId).balance, 1);
        assertEq(protocol.getDaoFeePool(daoId).balance, 1);
        assertApproxEqRel(_testERC20.balanceOf(daoCreator.addr), 3e22, 1e2);
        assertApproxEqRel(_testERC20.balanceOf(canvasCreator.addr), 9e23, 1e2);
        assertApproxEqRel(_testERC20.balanceOf(nftMinter.addr), 5e22, 1e2);
        assertEq(_testERC20.balanceOf(protocol.getVestingWallet(daoId)), 1);
        assertEq(_testERC20.balanceOf(protocol.getDaoFeePool(daoId)), 1);
    }
}
