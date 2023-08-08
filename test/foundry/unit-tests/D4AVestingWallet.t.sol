// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";
import { ERC20SigUtils } from "test/foundry/utils/ERC20SigUtils.sol";

import { D4AVestingWallet } from "contracts/feepool/D4AVestingWallet.sol";

contract D4AVestingWalletTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_daoToken() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        assertEq(D4AVestingWallet(payable(protocol.getVestingWallet(daoId))).getDaoToken(), protocol.getDaoToken(daoId));
    }

    function test_lastUpdatedDaoTokenIncrease_ETH() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(randomGuy.addr);
        protocol.grantETH{ value: 1 ether }(daoId);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        assertEq(vestingWallet.getLastUpdatedDaoTokenIncrease(), 0);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        protocol.claimProjectERC20Reward(daoId);
        vestingWallet.release();

        assertEq(vestingWallet.getLastUpdatedDaoTokenIncrease(), 33_333_333_333_333_333_333_333_333);
    }

    function test_lastUpdatedDaoTokenIncrease_Token() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        assertEq(vestingWallet.getLastUpdatedDaoTokenIncrease(address(_testERC20)), 0);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        protocol.claimProjectERC20Reward(daoId);
        vestingWallet.release(address(_testERC20));

        assertEq(vestingWallet.getLastUpdatedDaoTokenIncrease(address(_testERC20)), 33_333_333_333_333_333_333_333_333);
    }

    function test_getTotalDaoTokenIssuance() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);

        protocol.claimProjectERC20Reward(daoId);

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        assertEq(vestingWallet.getTotalDaoTokenIssuance(), 966_666_666_666_666_666_666_666_667);
    }

    function test_release_ETH() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(randomGuy.addr);
        protocol.grantETH{ value: 1 ether }(daoId);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);
        deal(protocol.getDaoFeePool(daoId), 0);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        vestingWallet.release();

        assertEq(protocol.getDaoFeePool(daoId).balance, uint256(1 ether) / 30);
    }

    event EtherReleased(uint256 amount);

    function test_release_ETH_ExpectEmit() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(randomGuy.addr);
        protocol.grantETH{ value: 1 ether }(daoId);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);
        deal(protocol.getDaoFeePool(daoId), 0);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        vm.expectEmit(address(vestingWallet));
        emit EtherReleased(uint256(1 ether) / 30);
        vestingWallet.release();
    }

    function test_release_Token() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        vestingWallet.release(address(_testERC20));

        assertEq(_testERC20.balanceOf(protocol.getDaoFeePool(daoId)), uint256(1e6 ether) / 30);
    }

    event ERC20Released(address indexed token, uint256 amount);

    function test_release_Token_ExpectEmit() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        vm.expectEmit(address(vestingWallet));
        emit ERC20Released(address(_testERC20), uint256(1e6 ether) / 30);
        vestingWallet.release(address(_testERC20));
    }

    function test_releasable_ETH() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(randomGuy.addr);
        protocol.grantETH{ value: 1 ether }(daoId);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);
        deal(protocol.getDaoFeePool(daoId), 0);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        assertEq(vestingWallet.releasable(), uint256(1 ether) / 30);
    }

    function test_releasable_Token() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        assertEq(vestingWallet.releasable(address(_testERC20)), uint256(1e6 ether) / 30);
    }

    function test_beneficiary() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        assertEq(vestingWallet.beneficiary(), protocol.getDaoFeePool(daoId));
    }

    function test_released_ETH() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(randomGuy.addr);
        protocol.grantETH{ value: 1 ether }(daoId);

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);
        deal(protocol.getDaoFeePool(daoId), 0);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        vestingWallet.release();

        assertEq(vestingWallet.released(), uint256(1 ether) / 30);
    }

    function test_released_Token() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);

        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(protocol.getVestingWallet(daoId)));

        vestingWallet.release(address(_testERC20));

        assertEq(vestingWallet.released(address(_testERC20)), uint256(1e6 ether) / 30);
    }
}
